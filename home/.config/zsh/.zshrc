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

# Do not override files using `>`, but it's still possible using `>!`
set -o noclobber

# Better formatting for time command
export TIMEFMT=$'\n================\nCPU\t%P\nuser\t%*U\nsystem\t%*S\ntotal\t%*E'

# LS Colors (editor: https://geoff.greer.fm/lscolors/)
export LSCOLORS="Gxfxcxdxbxegedabagacab"
export LS_COLORS='no=00:fi=00:di=01;34:ln=00;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=41;33;01:ex=00;32:ow=0;41:*.cmd=00;32:*.exe=01;32:*.com=01;32:*.bat=01;32:*.btm=01;32:*.dll=01;32:*.tar=00;31:*.tbz=00;31:*.tgz=00;31:*.rpm=00;31:*.deb=00;31:*.arj=00;31:*.taz=00;31:*.lzh=00;31:*.lzma=00;31:*.zip=00;31:*.zoo=00;31:*.z=00;31:*.Z=00;31:*.gz=00;31:*.bz2=00;31:*.tb2=00;31:*.tz2=00;31:*.tbz2=00;31:*.avi=01;35:*.bmp=01;35:*.fli=01;35:*.gif=01;35:*.jpg=01;35:*.jpeg=01;35:*.mng=01;35:*.mov=01;35:*.mpg=01;35:*.pcx=01;35:*.pbm=01;35:*.pgm=01;35:*.png=01;35:*.ppm=01;35:*.tga=01;35:*.tif=01;35:*.xbm=01;35:*.xpm=01;35:*.dl=01;35:*.gl=01;35:*.wmv=01;35:*.aiff=00;32:*.au=00;32:*.mid=00;32:*.mp3=00;32:*.ogg=00;32:*.voc=00;32:*.wav=00;32:*.patch=00;34:*.o=00;32:*.so=01;35:*.ko=01;31:*.la=00;33'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# ------------------------------------------------------------------------------
# Oh My Zsh
# ------------------------------------------------------------------------------
ZSH_DISABLE_COMPFIX=true

# Autoload node version when changing cwd
zstyle ':omz:plugins:nvm' autoload true

# Use passphrase from macOS keychain
if [[ "$OSTYPE" == "darwin"* ]]; then
  zstyle :omz:plugins:ssh-agent ssh-add-args --apple-load-keychain
fi
zstyle :omz:plugins:ssh-agent identities id_rsa

# ------------------------------------------------------------------------------
# Dependencies
# ------------------------------------------------------------------------------

# Load zgenom
source "${ZDOTDIR}/.zgenom/zgenom.zsh"
zgenom autoupdate

# Load zgenom init script
if ! zgenom saved; then
    zgenom ohmyzsh

    # OhMyZsh plugins
    zgenom ohmyzsh plugins/history-substring-search
    zgenom ohmyzsh plugins/sudo
    zgenom ohmyzsh plugins/command-not-found
    zgenom ohmyzsh plugins/nvm
    zgenom ohmyzsh plugins/extract
    zgenom ohmyzsh plugins/gh
    zgenom ohmyzsh plugins/brew
    zgenom ohmyzsh plugins/sfdx
    zgenom ohmyzsh plugins/iterm2
    zgenom ohmyzsh plugins/thefuck
    zgenom ohmyzsh plugins/dotenv
    zgenom ohmyzsh plugins/ssh-agent
    zgenom ohmyzsh plugins/aliases

    # Custom plugins
    zgenom load djui/alias-tips
    zgenom load marzocchi/zsh-notify
    zgenom load hlissner/zsh-autopair
    zgenom load zdharma-continuum/fast-syntax-highlighting
    zgenom load zsh-users/zsh-autosuggestions
    zgenom load unixorn/fzf-zsh-plugin
    zgenom load amyreese/zsh-titles

    # Files
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

# Smartdots (expands .... → ../../../)
smartdots() {
  if [[ $LBUFFER = *.. ]]; then
    LBUFFER+=/..
  else
    LBUFFER+=.
  fi
}
zle -N smartdots
bindkey . smartdots

# Diff
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
# Zoxide (directory jumper)
# ------------------------------------------------------------------------------

if _exists zoxide; then
  eval "$(zoxide init zsh)"
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

# Topic configs (aliases, sf, osx, work)
for s in $ZDOTDIR/*.zsh; do
  source $s
done

# bun completions
if [ -s "$HOME/.bun/_bun" ]; then
  source "$HOME/.bun/_bun"
fi

# LM Studio CLI
_extend_path "$HOME/.lmstudio/bin"


# Claude Chat
CLAUDEVOICE_FULL_CONTEXT=true      # gives it your MCP tools + skills
CLAUDEVOICE_MODEL=claude-sonnet-4-6
