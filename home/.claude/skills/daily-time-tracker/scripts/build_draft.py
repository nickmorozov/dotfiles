#!/usr/bin/env python3
"""Build a daily Mission Control time-entry draft from Timing app usage.

Produces two things for each requested date:
  1. A Timing "work-signal" summary (deduped wall-clock per app) so the human
     has real context when reviewing/editing descriptions.
  2. A draft of time entries that fill the day up to a target band (8-10h),
     subtracting whatever is already logged in cg-prod.

Nothing is written to Salesforce here. This script only reads (Timing DB +
SOQL) and writes a local draft JSON. Insertion is a separate, explicit step
the human approves — see SKILL.md.

Why the design choices, learned the hard way:
  - Timing stores startDate/endDate as PLAIN UNIX epoch seconds (NOT Cocoa
    2001-epoch). Adding the 978307200 offset silently lets a date filter match
    all history and inflates totals ~6x. Treat the values as unixepoch directly.
  - Timing keeps overlapping rows per app AND per window-title AND per path,
    synced across multiple devices. Summing raw durations double/triple counts.
    Real wall-clock = union of merged intervals.
  - The package validation rule "You cannot charge time to a task that is not
    Open" blocks time on any task with LABSMPM__Complete__c=true. Cached task
    Ids go stale the moment a task is completed. So we resolve every standard
    task NAME to a currently-Open Id at runtime (Complete__c=false), newest first.
  - `sf data import tree` needs a referenceId per record and is all-or-nothing
    per file, so one bad row rolls back the whole batch. We emit referenceIds
    and validate Open-ness before writing the draft to avoid that.
"""
import argparse, datetime, json, os, subprocess, sys

ORG = "cg-prod"
USERNAME = "nmorozov@corraogroup.com"
TIME_OBJ = "LABSMPM__Milestone1_Time__c"
TASK_OBJ = "LABSMPM__Milestone1_Task__c"
TIMING_DB = os.path.expanduser(
    "~/Library/Application Support/info.eurocomp.Timing2/SQLite.db"
)

# Standard day shape. Each fill task is resolved to an Open Id at runtime.
# `project_hint` disambiguates when the same task name exists on many projects;
# we prefer an Open task whose project name contains the hint, else any Open one.
FIXED = [
    {"task": "Nick - Breaks", "hours": 0.5, "desc": "Breaks", "project_hint": "Dev & PM Internal"},
    {"task": "Nick - Internal Meetings", "hours": 0.5, "desc": "Scrum", "project_hint": "Dev & PM Internal"},
]
# Remaining hours (target - existing - fixed) split across these, in order,
# by the given weights, rounded to 0.5.
FILL = [
    {"task": "Deployment Consultant", "weight": 0.45, "desc": "Deployment, merging PRs, syncing branches and orgs", "project_hint": "Bumble Bee"},
    {"task": "CGPM Dev", "weight": 0.40, "desc": "Debugging and testing", "project_hint": "Dev & PM Internal"},
    {"task": "Out-of-Scope Development", "weight": 0.15, "desc": "Testing and debugging", "project_hint": ""},
]

# Apps that signal actual billable work (vs. games/shopping/personal).
WORK_APPS = ("Meet", "Teams", "Zoom", "Slack", "IntelliJ", "VS Code", "iTerm",
             "Terminal", "Claude", "Salesforce", "Chrome", "Safari")


def sf_query(soql):
    """Run SOQL via sf CLI, return list of record dicts. Raises on CLI error."""
    out = subprocess.run(
        ["sf", "data", "query", "-q", soql, "-o", ORG, "--json"],
        capture_output=True, text=True,
    )
    if out.returncode != 0:
        raise RuntimeError(f"SOQL failed: {soql}\n{out.stderr or out.stdout}")
    return json.loads(out.stdout)["result"]["records"]


def get_user_id():
    recs = sf_query(f"SELECT Id FROM User WHERE Username='{USERNAME}'")
    if not recs:
        raise RuntimeError(f"User not found: {USERNAME}")
    return recs[0]["Id"]


def resolve_open_task(name, project_hint):
    """Return (Id, project_name) for an Open task matching name, newest first.
    Prefer a task whose project contains project_hint; fall back to any Open one.
    Returns (None, None) if no Open task by that name exists."""
    safe = name.replace("'", "\\'")
    recs = sf_query(
        f"SELECT Id, CreatedDate, LABSMPM__Project_Milestone__r.LABSMPM__Project__r.Name "
        f"FROM {TASK_OBJ} WHERE Name='{safe}' AND LABSMPM__Complete__c=false "
        f"ORDER BY CreatedDate DESC"
    )
    def proj(r):
        m = (r.get("LABSMPM__Project_Milestone__r") or {}).get("LABSMPM__Project__r") or {}
        return m.get("Name") or ""
    if project_hint:
        for r in recs:
            if project_hint.lower() in proj(r).lower():
                return r["Id"], proj(r)
    return (recs[0]["Id"], proj(recs[0])) if recs else (None, None)


def existing_hours(user_id, date):
    recs = sf_query(
        f"SELECT LABSMPM__Hours__c, LABSMPM__Project_Task__r.Name, LABSMPM__Description__c "
        f"FROM {TIME_OBJ} WHERE LABSMPM__Incurred_By__c='{user_id}' "
        f"AND LABSMPM__Date__c={date}"
    )
    total = sum((r.get("LABSMPM__Hours__c") or 0) for r in recs)
    items = [
        (r.get("LABSMPM__Hours__c"),
         (r.get("LABSMPM__Project_Task__r") or {}).get("Name"),
         r.get("LABSMPM__Description__c"))
        for r in recs
    ]
    return total, items


def union_hours(intervals):
    if not intervals:
        return 0.0
    intervals = sorted(intervals)
    total = 0.0
    cs, ce = intervals[0]
    for s, e in intervals[1:]:
        if s <= ce:
            ce = max(ce, e)
        else:
            total += ce - cs
            cs, ce = s, e
    return (total + ce - cs) / 3600.0


def timing_signal(date):
    """Deduped wall-clock hours per app for the date. Returns (total, [(h,app)])."""
    import sqlite3
    if not os.path.exists(TIMING_DB):
        return None, []
    lo = datetime.datetime.strptime(date, "%Y-%m-%d").timestamp()
    hi = lo + 86400
    con = sqlite3.connect(f"file:{TIMING_DB}?mode=ro", uri=True)
    rows = con.execute(
        "SELECT a.title, aa.startDate, aa.endDate FROM AppActivity aa "
        "JOIN Application a ON a.id=aa.applicationID "
        "WHERE aa.isDeleted=0 AND aa.startDate>=? AND aa.startDate<?",
        (lo, hi),
    ).fetchall()
    con.close()
    by_app = {}
    for t, s, e in rows:
        by_app.setdefault(t or "?", []).append((s, e))
    total = union_hours([iv for ivs in by_app.values() for iv in ivs])
    per = sorted(((union_hours(v), k) for k, v in by_app.items()), reverse=True)
    return total, [(h, k) for h, k in per if h >= 0.05]


def round_half(x):
    return round(x * 2) / 2


def build_day(user_id, date, target):
    existing_total, existing_items = existing_hours(user_id, date)
    sig_total, sig_apps = timing_signal(date)

    need = max(0.0, target - existing_total)
    fixed_total = sum(f["hours"] for f in FIXED) if need >= 1.0 else 0.0
    remaining = max(0.0, need - fixed_total)

    rows, warnings = [], []

    def add(spec, hours):
        if hours <= 0:
            return
        tid, proj = resolve_open_task(spec["task"], spec.get("project_hint", ""))
        if not tid:
            warnings.append(f"No OPEN task named '{spec['task']}' — skipped {hours}h.")
            return
        rows.append({
            "task": spec["task"], "task_id": tid, "project": proj,
            "hours": hours, "desc": spec["desc"],
        })

    if need >= 1.0:
        for f in FIXED:
            add(f, f["hours"])

    # Distribute remaining across FILL by weight, rounded to 0.5, last task
    # absorbs the rounding remainder so the day lands exactly on target.
    if remaining > 0:
        allocated = 0.0
        for i, f in enumerate(FILL):
            if i < len(FILL) - 1:
                h = round_half(remaining * f["weight"])
            else:
                h = round_half(remaining - allocated)
            allocated += h
            add(f, h)

    drafted = sum(r["hours"] for r in rows)
    return {
        "date": date,
        "existing_total": existing_total,
        "existing_items": existing_items,
        "timing_total": sig_total,
        "timing_apps": sig_apps,
        "target": target,
        "draft_total": drafted,
        "day_total": existing_total + drafted,
        "rows": rows,
        "warnings": warnings,
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dates", help="comma-separated YYYY-MM-DD; default today")
    ap.add_argument("--target", type=float, default=9.0,
                    help="fill target in hours (band 8-10, default 9)")
    ap.add_argument("--out", default="time-entries-tree.json",
                    help="draft output path")
    args = ap.parse_args()

    if args.dates:
        dates = [d.strip() for d in args.dates.split(",")]
    else:
        dates = [datetime.date.today().isoformat()]

    user_id = get_user_id()
    days = [build_day(user_id, d, args.target) for d in dates]

    # Emit tree-import JSON (referenceId per record, Time_Type fixed to Projects).
    records, ref = [], 0
    for day in days:
        for r in day["rows"]:
            ref += 1
            records.append({
                "attributes": {"type": TIME_OBJ, "referenceId": f"T{ref}"},
                "LABSMPM__Incurred_By__c": user_id,
                "LABSMPM__Date__c": day["date"],
                "LABSMPM__Project_Task__c": r["task_id"],
                "LABSMPM__Hours__c": r["hours"],
                "LABSMPM__Description__c": r["desc"],
                "Time_Type__c": "Projects",
            })
    with open(args.out, "w") as f:
        json.dump({"records": records}, f, indent=2)

    # Human-readable summary to stdout (the skill relays this for approval).
    print(f"\nDRAFT — {len(records)} record(s) -> {args.out}")
    print(f"(Salesforce user {user_id}, org {ORG}, target {args.target}h, band 8-10h)\n")
    for day in days:
        wd = datetime.datetime.strptime(day["date"], "%Y-%m-%d").strftime("%a")
        print(f"=== {day['date']} ({wd}) ===")
        tt = day["timing_total"]
        print(f"  Timing tracked: {tt:.2f}h" if tt is not None else "  Timing: DB not found")
        work = [(h, a) for h, a in day["timing_apps"]
                if any(w in a for w in WORK_APPS)]
        if work:
            print("  Work signal: " + ", ".join(f"{a} {h:.2f}h" for h, a in work[:6]))
        if day["existing_items"]:
            print(f"  Already logged: {day['existing_total']}h")
            for h, t, d in day["existing_items"]:
                print(f"     {h}h  {t}  | {d or ''}")
        for r in day["rows"]:
            print(f"  + {r['hours']}h  {r['task']}  [{r['project']}]  | {r['desc']}")
        for w in day["warnings"]:
            print(f"  ! {w}")
        print(f"  -> day total {day['day_total']}h "
              f"({'in band' if 8 <= day['day_total'] <= 10 else 'OUT OF BAND'})\n")


if __name__ == "__main__":
    main()
