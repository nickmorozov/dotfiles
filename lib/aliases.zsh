# .zshenv → .zprofile → .zshrc → .zlogin → .zlogout

#############################################
# Aliases
#############################################

# Enable askpass for Sudo
if _exists askpass; then
  if askpass -c; then
    alias sudo='sudo -A '
  else
    askpass -s
    alias sudo='sudo -A '
  fi
fi

# Extract helper
alias unrar="7z"
alias unzip="7z x"
alias xr="x -r"

# CLI
alias quiet=" >& /dev/null "
alias grab="sudo chown $USER"
alias rmf="rm -f"
alias rmr="rm -r"

# Reboot without user password on login - useful for encrypted system with Bluetooth keyboards
alias restart="sudo fdesetup authrestart -delayminutes 0"

# Avoid stupidity with trash-cli:
# https://github.com/sindresorhus/trash-cli
# or use default rm -i
if _exists trash; then
  alias rm='trash'
fi

# Just bcoz clr shorter than clear
alias clr='clear'

# Go to the /home/$USER (~) directory and clears window of your terminal
alias q="~ && clear"

# Fast config edit
alias ez="$EDITOR $ZDOTDIR/{zshenv,.zshrc,.zprofile,zsh.$HOST}"
alias ea="$EDITOR $DOTFILES/lib/aliases.zsh"

# Folders Shortcuts
[ -d ~/Downloads ]            && alias dl='cd ~/Downloads'
[ -d ~/Desktop ]              && alias dt='cd ~/Desktop'
[ -d ~/Projects ]             && alias pj='cd ~/Projects'
[ -d ~/Projects/Forks ]       && alias pjf='cd ~/Projects/Forks'
[ -d ~/Projects/Job ]         && alias pjj='cd ~/Projects/Job'
[ -d ~/Projects/Playground ]  && alias pjl='cd ~/Projects/Playground'
[ -d ~/Projects/Repos ]       && alias pjr='cd ~/Projects/Repos'

# Commands Shortcuts
alias e="$EDITOR"
alias v="$VIEWER"
alias -- +x='chmod +x'
alias x+='chmod +x'

# Open aliases
alias open='open_command'
alias o='open'
alias oo='open .'
alias term='open -a iterm.app'

# Homebrew
alias bi="brew install"
alias brm="brew remove"
alias bs="brew search"
alias bsd="brew search --desc --eval-all"
alias bdump="brew bundle dump --all --describe --force --global"
alias badopt="brew install --cask --adopt"
alias bl="brew list -ltr"
alias bcall="brew caveats $(brew list)"

# Run scripts
alias update="source $DOTFILES/scripts/update"
alias bootstrap="source $DOTFILES/scripts/bootstrap"

# Python
alias vact="source ./venv/bin/activate"
alias venv="virtualenv venv && vact"
alias pipreq="pip install -r requirements.txt"
if _exists python3; then
  alias py="python3"
else
  alias py="python"
fi
alias pym="py main.py"

# Quick jump to dotfiles
alias dotfiles="code $DOTFILES"

# Quick reload of zsh environment
alias reload="source $HOME/.zshenv && source $ZDOTDIR/.zprofile && source $ZDOTDIR/.zshrc"

# My IP
alias myip='ifconfig | sed -En "s/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p"'

# Show $PATH in readable view
alias path='echo -e ${PATH//:/\\n}'

# Download web page with all assets
alias getpage='wget --no-clobber --page-requisites --html-extension --convert-links --no-host-directories'

# Download file with original filename
alias get="curl -O -L"

# Use tldr as help util
if _exists tldr; then
  alias help="tldr"
fi

# Git
alias ghrc="gh repo create"
alias ghrcp="ghrc --public --push --source='.' --description "
alias ghrcpr="ghrc --private --push --source='.' --description "
alias ghrv="gh repo view --web"
alias git-root='cd $(git rev-parse --show-toplevel)'
function gcgp {
  gcmsg $@ && gp
}
function gcgpa {
  gcam $@ && gp
}

# GitHub Copilot Suggestions
alias cops="gh copilot suggest"
alias cope="gh copilot explain"

# Editing
alias vim="$EDITOR" # Fallback

if _exists lsd; then
  unalias ls
  alias ls='lsd'
  alias lt='lsd --tree'
fi

# cat with syntax highlighting
# https://github.com/sharkdp/bat
if _exists bat; then
  # Run to list all themes:
  #   bat --list-themes
  export BAT_THEME='gruvbox-dark'
  alias bat="bat --color=always"
  alias cat="bat --paging=never"
fi

# Fuck helper
_exists fuck && alias f="fuck"

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


