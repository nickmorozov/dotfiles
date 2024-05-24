
#############################################
# Work
#############################################

# GitHub Copilot Suggestions
alias cops="gh copilot suggest"
alias cope="gh copilot explain"

# Default Browser
db() {
  defaultbrowser $@

  quiet osascript <<EOF
tell application "System Events"
    -- Activate the CoreServicesUIAgent
    tell application "CoreServicesUIAgent" to activate
    delay 0.1 -- Adjust delay as necessary

    -- Focus on the CoreServicesUIAgent process
    tell process "CoreServicesUIAgent"
        delay 0.1 -- Adjust delay as necessary
        -- Find and click the button that starts with "Use"
        set useButton to (first button of window 1 whose name starts with "Use")
        click useButton
    end tell
end tell
EOF
}

# Personal/Work Focus Toggle
PERSONAL_APPS=('Safari' 'DatWeatherDoe' 'Karabiner-Menu' 'Karabiner-Elements')
WORK_APPS=('Microsoft Edge' 'Slack' 'Microsoft Teams (work or school)' 'Microsoft Teams' 'MSTeams' 'IntelliJ IDEA' 'HazeOver' 'Dato' 'JetBrains Toolbox' 'LogiTune' 'Moom' 'Cisco AnyConnect Secure Mobility Client')

# Work Focus
dbw() {
  db edgemac
  _toggle_stage_manager

  for app in "${PERSONAL_APPS[@]}"; do
    _quit "$app"
  done

  for app in "${WORK_APPS[@]}"; do
    _launch "$app"
  done

  focus -s "Work"

  _activate "${WORK_APPS[1]}"
}

# Personal Focus
dbp() {
  db safari
  _toggle_stage_manager

  for app in "${WORK_APPS[@]}"; do
    _quit "$app"
  done

  for app in "${PERSONAL_APPS[@]}"; do
    _launch "$app"
  done

  focus -s "Default"

  _activate "${PERSONAL_APPS[1]}"
}

# Toggle
dbt() {
  if db | quiet grep '*'; then
    dbp
  else
    dbw
  fi
}

