# .zshenv → .zprofile → .zshrc → .zlogin → .zlogout
#
# .zshrc is for interactive shells.
#   You set options for the interactive shell there with the setopt and unsetopt commands.
#   You can also load shell modules, set your history options, change your prompt, set up zle and completion, et cetera.
#   You also set any variables that are only used in the interactive shell (e.g. $LS_COLORS).

# ------------------------------------------------------------------------------
# Environment
# ------------------------------------------------------------------------------

setopt NUMERIC_GLOB_SORT

# Start the SSH agent if not already running
if [ -z "$SSH_AUTH_SOCK" ]; then
  eval "$(ssh-agent -s)"
fi

# Add SSH key
ssh-add -l &>/dev/null
if [ $? -eq 1 ]; then
  if [[ -f "$HOME/.ssh/id_rsa" ]]; then
    ssh-add --apple-use-keychain "$HOME/.ssh/id_rsa"
  elif [[ -f "$HOME/.ssh/id_ed25519" ]]; then
    ssh-add --apple-use-keychain "$HOME/.ssh/id_ed25519"
  fi
fi

HB_CNF_HANDLER="$(brew --prefix)/Homebrew/Library/Taps/homebrew/homebrew-command-not-found/handler.sh"
if [ -f "$HB_CNF_HANDLER" ]; then
    source "$HB_CNF_HANDLER"
fi

# Do not override files using `>`, but it's still possible using `>!`
set -o noclobber

# Better formatting for time command
export TIMEFMT=$'\n================\nCPU\t%P\nuser\t%*U\nsystem\t%*S\ntotal\t%*E'

# ------------------------------------------------------------------------------
# Oh My Zsh
# ------------------------------------------------------------------------------
ZSH_DISABLE_COMPFIX=true

# Autoload node version when changing cwd
zstyle ':omz:plugins:nvm' autoload true

# Use passphase from macOS keychain
if [[ "$OSTYPE" == "darwin"* ]]; then
  zstyle :omz:plugins:ssh-agent ssh-add-args --apple-load-keychain
fi

# ------------------------------------------------------------------------------
# Dependencies
# ------------------------------------------------------------------------------

function zvm_config() {
  ZVM_LINE_INIT_MODE=$ZVM_MODE_INSERT
  ZVM_VI_INSERT_ESCAPE_BINDKEY=jk
}

# Load zgenom
source "${ZDOTDIR}/.zgenom/zgenom.zsh"
zgenom autoupdate

# Load zgenom init script
if ! zgenom saved; then
    zgenom ohmyzsh

    # OhMyZsh plugins
    zgenom ohmyzsh plugins/git
    zgenom ohmyzsh plugins/history-substring-search
    zgenom ohmyzsh plugins/sudo
    zgenom ohmyzsh plugins/command-not-found
    zgenom ohmyzsh plugins/npm
    zgenom ohmyzsh plugins/nvm
    zgenom ohmyzsh plugins/extract
    zgenom ohmyzsh plugins/macos
    zgenom ohmyzsh plugins/gh
    zgenom ohmyzsh plugins/common-aliases
    zgenom ohmyzsh plugins/brew
    zgenom ohmyzsh plugins/sfdx
    zgenom ohmyzsh plugins/aliases
    zgenom ohmyzsh plugins/iterm2
    zgenom ohmyzsh plugins/thefuck
    zgenom ohmyzsh plugins/dotenv
    zgenom ohmyzsh plugins/ssh-agent

    # Custom plugins
    zgenom load jeffreytse/zsh-vi-mode
    zgenom load djui/alias-tips
    zgenom load agkozak/zsh-z
    zgenom load marzocchi/zsh-notify
    zgenom load hlissner/zsh-autopair
    zgenom load zsh-users/zsh-syntax-highlighting
    zgenom load zdharma-continuum/fast-syntax-highlighting
    zgenom load zsh-users/zsh-autosuggestions
    zgenom load unixorn/autoupdate-zgenom
    zgenom load unixorn/fzf-zsh-plugin
    zgenom load amyreese/zsh-titles

    # Files
    zgenom load $DOTFILES/lib
    zgenom load $DOTFILES/custom

    # Spaceship Prompt
    zgenom load spaceship-prompt/spaceship-prompt spaceship

    # Completions
    zgenom load zsh-users/zsh-completions src

    # Save all to init script
    zgenom save

    # Compile your zsh files
    zgenom compile $ZGEN_RESET_ON_CHANGE
fi

zstyle :omz:plugins:ssh-agent identities id_rsa

zgenom clean

# Diff - lib/theme-and-appearance.zsh has its own function which we override here
if _exists diff-so-fancy; then
  quiet unset diff
  diff() {
    command diff --color -u "$@" | diff-so-fancy | less
  }
fi

# ------------------------------------------------------------------------------
# Direnv
# ------------------------------------------------------------------------------

# Per-directory configs
if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi

# ------------------------------------------------------------------------------
# iTerm
# ------------------------------------------------------------------------------
# Allows to pass variables into the app UI
iterm2_print_user_vars() {
    iterm2_set_user_var now $(echo $(date +'%a\xC2\xA0%H:%M'))
    iterm2_set_user_var title $(echo "$(whoami)@$(hostname):$(pwd)")
    iterm2_set_user_var editor $(echo $(which $EDITOR))
}

# ------------------------------------------------------------------------------
# Load additional zsh files
# ------------------------------------------------------------------------------

# bun completions
if [ -s "$HOME/.bun/_bun" ]; then
  source "$HOME/.bun/_bun"
  export BUN_INSTALL="$HOME/.bun"
  export PATH="$BUN_INSTALL/bin:$PATH"
fi

# Fuzzy finder bindings
export FZF_BASE="$HOME/.fzf"
if [ -f "$HOME/.fzf.zsh" ]; then
  source "$HOME/.fzf.zsh"
  eval "$(fzf --zsh)"
fi



. "$HOME/.local/share/../bin/env"
