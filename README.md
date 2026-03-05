# Nick Morozov's dotfiles

Managed with [Dotbot](https://github.com/anishathalye/dotbot). ZSH plugins via [zgenom](https://github.com/jandamm/zgenom). Prompt by [Spaceship](https://github.com/spaceship-prompt/spaceship-prompt).

## Quick Start

```sh
# Clone
git clone https://github.com/nickmorozov/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# Install (symlinks, submodules, zgenom, bootstrap)
./install

# Set your git identity
git config -f ~/.gitlocal user.email "you@example.com"
git config -f ~/.gitlocal user.name "Your Name"
```

## Updating

```sh
update    # pulls dotfiles, updates submodules, runs install, updates brew + zgenom
reload    # re-sources zsh without restarting terminal
```

## Architecture

```
~/.dotfiles/
├── install.conf.yaml   # Dotbot config — symlinks home/.* → ~/
├── install             # Dotbot runner
├── .gitmodules         # Git submodules (dotbot, nvim, iterm themes, custom tools)
├── Brewfile            # Symlink to home/.Brewfile
│
├── home/               # Everything here gets symlinked to ~/
│   ├── .config/        # XDG configs (zsh, nvim, iterm2, jetbrains, raycast, gh, etc.)
│   ├── .local/
│   │   ├── bin/        # User scripts + symlinks to repos
│   │   └── repos/      # Git submodules (focus-manager, calendar-syncer, askpass)
│   ├── .claude/        # Claude Code settings, plugins, and project memory
│   ├── .sf/ .sfdx/     # Salesforce CLI auth and org configs
│   ├── .Brewfile       # Homebrew bundle (all packages, casks, taps, mas apps)
│   ├── .gitconfig      # Git config (sources ~/.gitlocal for user identity)
│   ├── .gitlocal       # Git user identity (name, email) — machine-specific
│   ├── .ideavimrc      # IdeaVim config (sources shared vimrc)
│   ├── .zshenv         # ZSH env vars, PATH, helper functions
│   ├── .crontab        # Cron jobs (save with crontab-save, load with crontab ~/.crontab)
│   └── .ssh            # Symlink to iCloud SSH keys
│
├── bin/                # Standalone scripts (added to PATH)
├── scripts/            # Install/update/bootstrap scripts
├── lib/                # ZSH libraries loaded by zgenom (aliases, smartdots, lscolors)
├── custom/             # Custom ZSH files loaded by zgenom
└── backup/             # macOS defaults backup
```

### How Symlinks Work

Dotbot globs `home/.*` and symlinks each entry to `~/`. So:
- `home/.config` → `~/.config`
- `home/.zshenv` → `~/.zshenv`
- `home/.Brewfile` → `~/.Brewfile`

Since `~/.config` is a symlink to the dotfiles repo, editing `~/.config/zsh/.zshrc` directly edits the tracked file.

### ZSH Loading Order

```
~/.zshenv          → Environment vars, PATH, helper functions (_exists, _extend_path, etc.)
~/.config/zsh/
  .zprofile        → Login shell setup
  .zshrc           → Interactive shell: zgenom plugins, completions, prompt
    lib/*.zsh      → Core aliases, lscolors, smartdots
    custom/*.zsh   → (empty by default)
  aliases.zsh      → Personal aliases (brew, python, yazi, config editing)
  osx.zsh          → macOS helpers (dock, launchpad, app control)
  sf.zsh           → Salesforce CLI aliases and workflows
  work.zsh         → Work/personal focus mode toggle
```

### Submodules

| Submodule | Path | Purpose |
|-----------|------|---------|
| [dotbot](https://github.com/anishathalye/dotbot) | `dotbot/` | Symlink manager |
| [NvChad](https://github.com/nickmorozov/NvChad) | `home/.config/nvim/` | Neovim config (Lua) |
| [iTerm2-Color-Schemes](https://github.com/mbadolato/iTerm2-Color-Schemes) | `home/.config/iterm2/iTerm2-Color-Schemes/` | Terminal color themes |
| [focus-manager](https://github.com/nickmorozov/focus-manager) | `home/.local/repos/focus-manager/` | macOS Focus mode CLI |
| [osx-calendar-syncer](https://github.com/nickmorozov/osx-calendar-syncer) | `home/.local/repos/osx-calendar-syncer/` | Calendar sync tool |
| [sudo-askpass-security](https://github.com/nickmorozov/sudo-askpass-security) | `home/.local/repos/sudo-askpass-security/` | macOS Keychain sudo |

## Aliases Cheat Sheet

### Navigation
| Alias | Command | Description |
|-------|---------|-------------|
| `..` / `...` / `....` | `cd ../..` etc. | Quick parent traversal (smartdots) |
| `dl` / `dt` / `pj` | `cd ~/Downloads` etc. | Folder shortcuts |
| `pjj` / `pjr` / `pjf` / `pjl` | `cd ~/Projects/Job` etc. | Project folder shortcuts |
| `z <dir>` | zoxide | Frecency-based directory jumper |
| `yy` | yazi | File manager with cwd tracking |

### Git
| Alias | Description |
|-------|-------------|
| `gst` / `gss` | Status / short status |
| `gd` | Diff |
| `gaa` | Add all |
| `gcm "msg"` | Commit with message |
| `gcam "msg"` | Add all + commit with message |
| `gco` / `gcb` | Checkout / checkout new branch |
| `gp` / `gl` | Push / pull |
| `gcl` | Clone with submodules |
| `grs` / `grst` | Restore / restore staged |
| `gsta` / `gstp` | Stash push / pop |
| `grset` | Remote set-url |
| `gcgp "msg"` | Commit + push |
| `gcgpa "msg"` | Add all + commit + push |
| `git-root` | cd to repo root |
| `gst-dirs` / `gst-proj` | Status across multiple repos |
| `git l` / `git ll` | Pretty log / log with files |
| `git amend` / `git undo` | Amend last / undo last commit |
| `git sync` | Pull + push |
| `als <keyword>` | Search aliases by keyword (OMZ aliases plugin) |

### Homebrew
| Alias | Description |
|-------|-------------|
| `bi` / `brm` / `bs` | Install / remove / search |
| `bsd` | Search with descriptions |
| `bdump` | Dump Brewfile |
| `bl` | List installed (sorted by date) |
| `bdeps` | Show dependency tree |
| `badopt` | Install cask with --adopt |

### Work Mode
| Alias | Description |
|-------|-------------|
| `dbw` | Switch to work focus (Chrome, Slack, Teams, IDE) |
| `dbp` | Switch to personal focus (Safari) |
| `dbt` | Toggle work/personal |
| `dbm` / `dbmc` | Start/stop music apps |
| `dbs` / `dbc` | Default browser Safari/Chrome |

### Editor & Files
| Alias | Description |
|-------|-------------|
| `e` / `vim` | Open in $EDITOR (nvim) |
| `v` / `cat` | View with bat (syntax highlighting) |
| `ls` / `ltree` | lsd with tree view |
| `ez` / `ezz` | Edit .zshrc / zsh config dir |
| `dotfiles` | Open dotfiles in editor |

### Misc
| Alias | Description |
|-------|-------------|
| `update` | Update everything (dotfiles, brew, zgenom) |
| `reload` | Re-source ZSH config |
| `myip` / `path` | Show local IP / readable PATH |
| `f` | thefuck — correct previous command |

## Crontab

The `.crontab` file defines scheduled tasks. Load with `crontab ~/.crontab`.

| Schedule | Command | Purpose |
|----------|---------|---------|
| Every hour 8am-midnight | `shortcuts run "Sync Events"` | Sync calendar events via Shortcuts |
| Weekdays 8-10am | `focus -g \| grep 'Work' \|\| dbw` | Auto-switch to work mode if Focus is Work |
| Daily 6-10pm | `focus -g \| grep 'Work' && dbp` | Auto-switch to personal if still in Work focus |

## Brewfile

`~/.Brewfile` (symlinked from `home/.Brewfile`) is the source of truth for all Homebrew packages. The root `Brewfile` is a symlink to it.

```sh
bdump     # Save current brew state to Brewfile
brew bundle --global   # Install everything from Brewfile
```

## fzf

[fzf](https://github.com/junegunn/fzf) is a fuzzy finder installed via Homebrew and configured by the `fzf-zsh-plugin`. It's used for:

- **`Ctrl+R`** — fuzzy search command history
- **`Ctrl+T`** — fuzzy find files in current directory
- **`Alt+C`** — fuzzy cd into subdirectories
- **`**<Tab>`** — trigger fzf completion (e.g., `vim **<Tab>`, `cd **<Tab>`)

## License

MIT
