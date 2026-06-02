#!/usr/bin/env zsh
# Scheduled 4pm-weekday driver for daily-time-tracker.
#
# Runs the draft builder for TODAY, then prompts Nick. It does NOT insert
# anything into Salesforce — approval/insert happens interactively in Claude.
#
# Notification design: `display notification` can't be made persistent from a
# script (that's a per-app System Settings toggle) and its click always opens
# the owning app (Script Editor), not anything useful. So when there's work to
# log we use a modal `display alert` instead: it stays on screen until clicked
# and its buttons run real actions. A "Review in Claude" button opens Terminal
# in ~/.daily-time (where the draft lives) running the skill, so import is one
# step away. When there's nothing to log we just fire a transient banner.
#
# launchd runs with a minimal PATH and no login env, so set PATH explicitly:
# Homebrew + the nvm node bin that provides `sf`. Update NVM_BIN if node moves.
set -u

HOMEBREW_BIN="/opt/homebrew/bin"
NVM_BIN="/opt/homebrew/opt/nvm/versions/node/v24.14.1/bin"
export PATH="$HOMEBREW_BIN:$NVM_BIN:/usr/bin:/bin:/usr/sbin:/sbin"

OUTDIR="$HOME/.daily-time"
mkdir -p "$OUTDIR"
DRAFT="$OUTDIR/time-entries-tree.json"
SUMMARY="$OUTDIR/last-summary.txt"
LOG="$OUTDIR/run.log"
SCRIPT="$HOME/.claude/skills/daily-time-tracker/scripts/build_draft.py"

TODAY=$(date +%Y-%m-%d)
echo "===== $(date) : building draft for $TODAY =====" >> "$LOG"

if ! python3 "$SCRIPT" --dates "$TODAY" --target 9 --out "$DRAFT" > "$SUMMARY" 2>> "$LOG"; then
    echo "BUILD FAILED — see log" >> "$LOG"
    /usr/bin/osascript -e "display notification \"Draft build failed for $TODAY — check ~/.daily-time/run.log\" with title \"Time tracker error\" sound name \"Basso\""
    exit 1
fi
cat "$SUMMARY" >> "$LOG"

NREC=$(grep -oE 'DRAFT — [0-9]+ record' "$SUMMARY" | grep -oE '[0-9]+' | head -1)
NREC=${NREC:-0}
TOTAL=$(grep -oE 'day total [0-9.]+h' "$SUMMARY" | tail -1)

if [[ "$NREC" -eq 0 ]]; then
    # Nothing to log today (already at target). Transient banner is enough.
    /usr/bin/osascript -e "display notification \"Already at ${TOTAL:-target} — nothing to log\" with title \"Time: $TODAY done\" sound name \"Glass\""
    exit 0
fi

# Persistent, actionable prompt. The dialog body shows the proposed rows so Nick
# can decide at a glance. Buttons: Dismiss (do nothing) | Review in Claude.
BODY="$NREC new rows — $TOTAL"$'\n\n'"$(grep -E '^\s+\+ ' "$SUMMARY")"
# AppleScript string-escape: backslashes and double quotes.
ESC=${BODY//\\/\\\\}
ESC=${ESC//\"/\\\"}

CHOICE=$(
    /usr/bin/osascript << OSA
set theButton to button returned of (display alert "Time draft ready: $TODAY" message "$ESC" buttons {"Dismiss", "Review in Claude"} default button "Review in Claude" as informational)
return theButton
OSA
)

if [[ "$CHOICE" == "Review in Claude" ]]; then
    # Open Terminal in the draft dir and launch the skill so import is immediate.
    /usr/bin/osascript << 'OSA'
tell application "Terminal"
    activate
    do script "cd ~/.daily-time && claude \"/daily-time-tracker review today's draft (time-entries-tree.json) and insert to cg-prod after I approve\""
end tell
OSA
fi
