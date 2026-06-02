---
name: daily-time-tracker
description: >-
    Draft and log Nick's daily Salesforce Mission Control time entries
    (LABSMPM__Milestone1_Time__c) in the cg-prod org, using macOS Timing app usage
    as context. Use this whenever the user asks to fill in their timesheet, log
    hours, "do my time", catch up on time tracking, track a day/yesterday/this
    week, or whenever the 4pm weekday scheduled run fires. Also use when the user
    mentions Timing usage in the context of billing hours, or asks to top a day up
    to 8-10 hours. The skill ALWAYS drafts first and waits for explicit approval
    before writing anything to production.
---

# Daily Time Tracker

Drafts daily time entries for Nick in the **cg-prod** Salesforce org and inserts
them only after he approves. Timing app usage is pulled in as _context_ (what was
actually worked), not as the source of truth — Nick bills a target of **8–10h/day**
regardless of tracked activity, with a standard task mix.

## The one rule that matters

**Never write to cg-prod without explicit approval in the current turn.** This is
production. The scheduled 4pm run drafts and notifies — it does not auto-insert.
Show the draft, wait for a clear "yes / insert / go", then insert.

## Workflow

### 1. Build the draft

Run the builder. It reads Timing + cg-prod (read-only) and writes a draft file.
It never touches Salesforce data.

```bash
python3 ~/.claude/skills/daily-time-tracker/scripts/build_draft.py \
    --dates 2026-06-02,2026-06-03 --target 9 --out time-entries-tree.json
```

- `--dates` takes one or more comma-separated `YYYY-MM-DD` values.
- Default `--dates` is today. For a 4pm weekday run, that's correct — pass nothing.
- If Nick says "yesterday and today" or names dates, pass them comma-separated.
- `--target` defaults to 9 (middle of the 8–10 band). Honor a different number if
  he asks ("make it 8", "bump to 10").

The script prints a per-day summary: Timing tracked hours, **work signal** (calls,
IDE, Slack, terminal — the apps that suggest real billable work), what's already
logged that day, and the proposed new rows. It subtracts already-logged hours so
re-running mid-day never double-books.

### 2. Relay the draft and get approval

Show Nick the summary as a compact table per day. Call out:

- Any day flagged **OUT OF BAND** (couldn't reach 8h — usually a missing Open task).
- Any `!` warnings (e.g. "No OPEN task named 'X'") — these mean a standard task got
  completed and needs reopening, or the hours got skipped.
- The work signal, so he can sanity-check or rewrite descriptions. The default
  descriptions are deliberately generic; he often edits them to match real work.

Then ask: insert as-is, or adjust first? Common adjustments — edit a description,
change hours on a task, repoint to a specific task (e.g. a reopened Brown-Forman
task). Apply edits directly to the draft JSON (`time-entries-tree.json`) or rebuild
with different args.

### 3. Insert (only after approval)

```bash
sf data import tree --files time-entries-tree.json -o cg-prod
```

`import tree` is REST + all-or-nothing per file. If any row is rejected the whole
batch rolls back, so a failure means nothing was committed — fix and re-run.

The most likely rejection is `FIELD_CUSTOM_VALIDATION_EXCEPTION: You cannot charge
time to a task that is not Open`. The builder already filters to Open tasks, but a
task can be completed between draft and insert. If it happens, re-run step 1 (it
re-resolves to currently-Open task Ids) and insert again.

### 4. Verify

```bash
sf data query -q "SELECT LABSMPM__Date__c, SUM(LABSMPM__Hours__c) hrs, COUNT(Id) n FROM LABSMPM__Milestone1_Time__c WHERE LABSMPM__Incurred_By__c='<userId>' AND LABSMPM__Date__c IN (<dates>) GROUP BY LABSMPM__Date__c" -o cg-prod
```

Confirm each day lands in the 8–10h band and report the totals back.

## Day shape and how hours are allocated

Defined in `scripts/build_draft.py` (`FIXED` + `FILL`), so it's one place to edit:

- **Nick - Breaks** 0.5h and **Nick - Internal Meetings** 0.5h — added when the day
  needs ≥1h of filling.
- Remaining hours split across **Deployment Consultant** (~45%), **CGPM Dev** (~40%),
  **Out-of-Scope Development** (~15%), rounded to 0.5, last task absorbing the
  remainder so the day hits the target exactly.

To change the mix permanently, edit those lists. For a one-off change, edit the
draft JSON before inserting.

## Why tasks are resolved by name at runtime

Task Ids are NOT cached. The package blocks time on completed tasks, and tasks get
completed constantly, so a hardcoded Id goes stale and the insert rolls back. The
builder resolves each standard task NAME to the newest **Open** (`Complete__c=false`)
Id every run, preferring the right project via a hint. If a needed task has no Open
instance, it warns instead of silently producing a broken draft — that's the signal
to reopen a task (set `LABSMPM__Complete__c=false`) before inserting.

## Key facts (org/data specifics)

- Org alias: `cg-prod`. User: `nmorozov@corraogroup.com` (resolved to Id at runtime).
- Time object: `LABSMPM__Milestone1_Time__c`. "Assigned to me" = `LABSMPM__Incurred_By__c`.
- `Time_Type__c` is always `Projects` — drives the package's rate/profit rollups.
- Timing DB: `~/Library/Application Support/info.eurocomp.Timing2/SQLite.db`,
  read-only. `startDate`/`endDate` are PLAIN Unix epoch (no Cocoa offset), with
  overlapping per-app/title/path rows across devices — the builder dedupes via
  interval union, so don't sum raw durations.
