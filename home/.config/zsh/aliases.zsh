#############################################
# Aliases
#############################################

# ------------------------------------------------------------------------------
# System & Environment
# ------------------------------------------------------------------------------

# Enable askpass for Sudo
if _exists askpass; then
    if askpass -c; then
        alias sudo='sudo -A '
    else
        askpass -s \
            && alias sudo='sudo -A '
    fi
fi

# Reboot without user password on login - useful for encrypted system with Bluetooth keyboards
alias restart="sudo fdesetup authrestart -delayminutes 0"

alias clr='clear'

# Go to ~ and clear terminal
alias q="~ && clear"

# ------------------------------------------------------------------------------
# Navigation
# ------------------------------------------------------------------------------

# Folder shortcuts
[ -d ~/iCloud ] && alias ic='cd ~/iCloud'
[ -d ~/Documents ] && alias ds='cd ~/Documents'
[ -d ~/Downloads ] && alias dl='cd ~/Downloads'
[ -d ~/Desktop ] && alias dt='cd ~/Desktop'
[ -d ~/Projects ] && alias pj='cd ~/Projects'
[ -d ~/Projects/Enum ] && alias pje='cd ~/Projects/Enum'
[ -d ~/Projects/Forks ] && alias pjf='cd ~/Projects/Forks'
[ -d ~/Projects/Hobbies ] && alias pjh='cd ~/Projects/Hobbies'
[ -d ~/Projects/Job ] && alias pjj='cd ~/Projects/Job'
[ -d ~/Projects/Playground ] && alias pjl='cd ~/Projects/Playground'
[ -d ~/Projects/Repos ] && alias pjr='cd ~/Projects/Repos'

# Current dir without path
alias cwd='basename $PWD'

# File Manager (yazi with cwd tracking)
function yy() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}

# ------------------------------------------------------------------------------
# Editor & Files
# ------------------------------------------------------------------------------

alias e="$EDITOR"
alias vim="$EDITOR"
alias v="$VIEWER"
alias -- +x='chmod +x'
alias x+='chmod +x'

# Open
alias open='open_command'
alias o='open'
alias oo='open .'
alias oa='open -a'

# lsd (ls replacement)
if _exists lsd; then
    unalias ls l la ll lsa 2> /dev/null
    alias ls='lsd -Fvg --group-directories-first'
    alias l='ls -1'
    alias ll='ls -lh --date=relative'
    alias lr='ll -R'
    alias la='ll -A'
    alias lt='la --tree'
    alias lT='la -t'
    alias lS='la -S'
    alias lSS='la -S --total-size'
    alias lX='la -X'
fi

# Tree (respects .gitignore when in a git repo)
tt() {
    local depth="${1:-2}"
    if git rev-parse --is-inside-work-tree &> /dev/null; then
        tree -L "$depth" --gitignore
    else
        tree -L "$depth" -I 'node_modules|.git'
    fi
}

# Fast config edit
alias ez="$EDITOR $ZDOTDIR/.zshrc"
alias ezz="$EDITOR $ZDOTDIR/"
alias ea="$EDITOR $ZDOTDIR/aliases.zsh"
alias eaa="$EDITOR $ZDOTDIR/*.zsh"

# Quick jump to dotfiles
alias dotfiles="$EDITOR $DOTFILES"

# tldr as help
if _exists tldr; then
    alias help="tldr"
fi

# ------------------------------------------------------------------------------
# Git
# ------------------------------------------------------------------------------

# Core git aliases (replaces OMZ git plugin — only the aliases we actually use)
alias gst='git status'
alias gss='git status --short'
alias gd='git diff && git diff --cached'
alias ga='git add'
alias gaa='git add --all'
alias gcm='git commit -m'
alias gcam='git commit --all --message'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gp='git push'
alias gl='git pull'
alias gcl='git clone --recurse-submodules'
alias grset='git remote set-url'
alias gsta='git stash push'
alias gstp='git stash pop'
alias grs='git restore'
alias grst='git restore --staged'
alias git-root='cd $(git rev-parse --show-toplevel)'

# Commit + push combos
gcgp() { git commit -m "$@" && git push; }
gcagp() { git commit --all --message "$@" && git push; }
gtag() { git tag "$@" && git push origin "$@"; }

# GitHub CLI
alias ghrc="gh repo create"
alias ghrcp="ghrc --public --push --source='.' --description "
alias ghrcpr="ghrc --private --push --source='.' --description "
alias ghrv="gh repo view --web"

# Recursive git status — shows only repos that need attention (dirty or unpushed)
# usage: gstr [dir]  (defaults to current directory, searches recursively)
gstr() {
    local root="${1:-.}" found=0
    find "$root" -maxdepth 3 -name .git -type d -prune 2> /dev/null | while read gitdir; do
        local dir="${gitdir%/.git}"
        local dirty=$(git -C "$dir" status --porcelain 2> /dev/null)
        local ahead=$(git -C "$dir" rev-list --count @{upstream}..HEAD 2> /dev/null)
        if [[ -n "$dirty" || "${ahead:-0}" -gt 0 ]]; then
            _green "  ➜ ${dir/#$HOME/~}"
            [[ -n "$dirty" ]] && echo "    $(echo "$dirty" | wc -l | tr -d ' ') dirty file(s)"
            [[ "${ahead:-0}" -gt 0 ]] && echo "    $ahead commit(s) to push"
            found=1
        fi
    done
    [[ $found -eq 0 ]] && _green "  All repos clean and pushed!"
}

# ------------------------------------------------------------------------------
# Shell & System
# ------------------------------------------------------------------------------

# Run scripts
alias update="source $DOTFILES/scripts/update"
alias bootstrap="source $DOTFILES/scripts/bootstrap"
alias snapshot="$DOTFILES/scripts/snapshot"
alias restore="$DOTFILES/scripts/restore"

# Quick reload of zsh environment
alias reload="find $ZDOTDIR -name '*.zwc' -delete 2>/dev/null; source $HOME/.zshenv && source $ZDOTDIR/.zprofile && source $ZDOTDIR/.zshrc"

alias myip='ifconfig | sed -En "s/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p"'
alias path='echo -e ${PATH//:/\\n}'
alias grab="sudo chown $USER"

# Download
alias getpage='wget --no-clobber --page-requisites --html-extension --convert-links --no-host-directories'
alias get="curl -O -L"

# Rsync
alias rs="rsync -Puha"

# thefuck
if _exists fuck; then
    alias f="fuck"
fi

# Remove empty directories recursively
rdf() {
    if [[ -z $1 ]]; then
        echo "Usage: rdf <DIR>"
        return 1
    fi
    find "${1}" -type d -empty -exec rmdir {} \+
}

# Sanitize filenames: replace non-alphanumeric chars with underscores (preserves extensions)
# usage: sanitize <DIR>
sanitize() {
    local dir="${1:-.}"
    # Rename directories first (bottom-up so child renames don't break parent paths)
    find "$dir" -depth -type d ! -path "$dir" | while read -r d; do
        local parent="${d:h}" name="${d:t}"
        local clean="${name//[^a-zA-Z0-9._-]/_}"
        [[ "$name" != "$clean" ]] && mv -n "$d" "$parent/$clean" && echo "dir:  $name → $clean"
    done
    # Then rename files
    find "$dir" -type f | while read -r f; do
        local parent="${f:h}" name="${f:t}"
        local stem="${name%.*}" ext="${name##*.}"
        if [[ "$name" == *.* ]]; then
            local clean="${stem//[^a-zA-Z0-9._-]/_}.$ext"
        else
            local clean="${name//[^a-zA-Z0-9._-]/_}"
        fi
        [[ "$name" != "$clean" ]] && mv -n "$f" "$parent/$clean" && echo "file: $name → $clean"
    done
}

# Crontab
alias crontab-save="crontab -l > $HOME/.crontab"

# Dotfiles: move a file into dotfiles and symlink it back
dot-save() {
    test -z $1 && return 1
    mv "$1" "$HOME/.dotfiles/home"
    ln -s "$HOME/.dotfiles/home/$1"
}

# Extract (uses OMZ extract plugin `x`)
alias xr="x -r"

# ------------------------------------------------------------------------------
# Homebrew
# ------------------------------------------------------------------------------

alias bi="brew install"
alias brm="brew remove"
alias bs="brew search"
alias bsd="brew search --desc --eval-all"
alias bdump="brew bundle dump --describe --global --formula --cask --tap --mas --force --quiet"
alias badopt="brew install --cask --adopt"
alias bl="brew list -ltr"
alias bcaveats="brew caveats \$(brew list)"
alias bdeps="brew deps --tree --installed"

# ------------------------------------------------------------------------------
# Python
# ------------------------------------------------------------------------------

alias vact="source ./venv/bin/activate"
alias venv="virtualenv venv && vact"
alias pipreq="pip install -r requirements.txt"
if _exists python3; then
    alias py="python3"
else
    alias py="python"
fi
alias pym="py main.py"

# ------------------------------------------------------------------------------
# Claude
# ------------------------------------------------------------------------------

alias cld="claude"
alias cldr="claude --resume"

# ------------------------------------------------------------------------------
# Prettier
# ------------------------------------------------------------------------------

alias fm="npx prettier --write"

# ------------------------------------------------------------------------------
# OSX
# ------------------------------------------------------------------------------

alias hide='chflags hidden'
alias unhide='chflags nohidden'
