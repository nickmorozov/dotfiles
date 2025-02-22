
#############################################
# OSX
#############################################

# Util
_quit() {
  osascript <<EOF
try
  tell application "${1}" to quit

  on error errMsg
  log "Error running shortcut: " & errMsg
end try
EOF
}

_launch() {
  osascript <<EOF
try
  tell application "${1}" to launch

  on error errMsg
  log "Error running shortcut: " & errMsg
end try
EOF
}

_activate() {
  osascript <<EOF
try
  tell application "${1}" to activate

  on error errMsg
  log "Error running shortcut: " & errMsg
end try
EOF
}

_is_running() {
  osascript <<EOF
try
  tell application "System Events"
    (name of processes) contains "${1}"
    return result
  end tell

  on error errMsg
  log "Error running shortcut: " & errMsg
end try
EOF
}

_get_default_browser() {
  defaults read ~/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure | \
  awk -F'"' '/http;/{print window[(NR)-1]}{window[NR]=$2}' | \
  awk -F'.' '{print $NF}'
}

_toggle_stage_manager() {
  osascript -e 'tell application "System Events" to key code 109 using control down'
}

_use_new_browser() {
  osascript <<EOF
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


# Dock
function dock {
    local usage=(
      'Usage:'
      '  dock toggle|position|size|spacer'
      '    toggle (hide/unhide)'
      '    position [left|right|bottom]'
      '    size <16-128>'
      '    spacer [app|other] [normal|small|flex]]'
    )

  if [[ -z $1 ]]; then
    printf '%s\n' $usage && return 1
  fi

  if [[ 'toggle' = $1 ]]; then
    if [[ $(defaults read com.apple.dock "autohide") -eq 1 ]]; then
      defaults write com.apple.dock "autohide" -bool "false" || return 1
    else
      defaults write com.apple.dock "autohide" -bool "true" || return 1
    fi
  fi

  if [[ 'position' = $1 ]]; then
    if [[ -z $2 || $2 != (left|right|bottom) ]]; then
      printf '%s\n' $usage && return 1
    fi

    defaults write com.apple.dock "orientation" -string $2 || return 1
  fi

  if [[ 'size' = $1 ]]; then
    if [[ -z $2 || $2 -lt 0 || $2 -gt 128 ]]; then
      printf '%s\n' $usage && return 1
    fi

    defaults write com.apple.dock "tilesize" -int $2 || return 1
  fi

  if [[ 'spacer' = $1 ]]; then
    if [[ -z $2 || -z $3 || $2 != (app|other) || $3 != (normal|small|flex) ]]; then
      printf '%s\n' $usage && return 1
    fi

    cmd='defaults write com.apple.dock persistent-'

    if [[ 'app' = $2 ]]; then
      cmd+='apps'
      cmd+=" -array-add '{tile-type="
    else
      cmd+='others'
      cmd+=" -array-add '{tile-data={}; tile-type="
    fi


    if [[ 'small' = $3 ]]; then
        cmd+='"small-spacer-tile"'
      elif [[ 'flex' = $3 ]]; then
        cmd+='"flex-spacer-tile"'
      else
        cmd+='"spacer-tile"'
    fi

    cmd+=";}'"

    echo $cmd
    eval $cmd || return 1
  fi

  killall Dock && echo "Success!"
}

# Set Launchpad size
launchpad_size() {
  if [[ -z $2 ]]; then
    echo "Usage: launchpad_size <columns> <rows>"
  fi

  defaults write com.apple.dock springboard-columns -int $1
  defaults write com.apple.dock springboard-rows -int $2
  killall Dock
}

