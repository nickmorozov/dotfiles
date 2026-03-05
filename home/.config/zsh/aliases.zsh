
#############################################
# Aliases
#############################################

# File Manager (yazi with cwd tracking)
function yy() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

# Current dir without path
alias cwd='basename $PWD'

# Git (replaces OMZ git plugin — only the aliases we actually use)
alias gst='git status'
alias gss='git status --short'
alias gd='git diff'
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

# Fast config edit
alias ez="$EDITOR $ZDOTDIR/.zshrc"
alias ezz="$EDITOR $ZDOTDIR/"
alias ea="$EDITOR $ZDOTDIR/aliases.zsh"
alias eaa="$EDITOR $ZDOTDIR/*.zsh"

# Remove empty directories recursively
rdf() {
  if [[ -z $1 ]]; then
    echo "Usage: rdf <DIR>"
    return 1
  fi
  find "${1}" -type d -empty -exec rmdir {} \+
}

# Crontab
alias crontab-save="crontab -l > $HOME/.crontab"

# Dotfiles: move a file into dotfiles and symlink it back
dot-save() {
  test -z $1 && return 1
  mv "$1" "$HOME/.dotfiles/home"
  ln -s "$HOME/.dotfiles/home/$1"
}

# Homebrew
alias bi="brew install"
alias brm="brew remove"
alias bs="brew search"
alias bsd="brew search --desc --eval-all"
alias bdump="brew bundle dump --describe --global --formula --cask --tap --mas --force --quiet"
alias badopt="brew install --cask --adopt"
alias bl="brew list -ltr"
alias bcaveats="brew caveats \$(brew list)"
alias bdeps="brew deps --tree --installed"

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

# CLI
alias grab="sudo chown $USER"

# Extract (uses OMZ extract plugin `x`)
alias xr="x -r"

# Rsync
alias rs="rsync -Puha"

