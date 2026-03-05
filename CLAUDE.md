# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a macOS-focused dotfiles repository managed by [Dotbot](https://github.com/anishathalye/dotbot). It provides a complete ZSH environment with plugin management via [zgenom](https://github.com/jandamm/zgenom), a [Spaceship](https://github.com/spaceship-prompt/spaceship-prompt) prompt, and extensive shell customization.

## Key Commands

- **Install/sync dotfiles:** `./install` (runs Dotbot with `install.conf.yaml`)
- **Update everything:** `update` (alias for `source $DOTFILES/scripts/update` — updates dotfiles, brew, apt)
- **Bootstrap new machine:** `./scripts/bootstrap` (interactive — installs Homebrew, git, zsh, software, npm packages)
- **Snapshot machine state:** `./scripts/snapshot` (reverse of bootstrap — dumps Brewfile + saves `~/Projects` repo manifest to `~/.repos`)
- **Restore project repos:** `./scripts/restore` (reads `~/.repos` and clones repos back into `~/Projects/`)
- **Reload shell config:** `reload` (alias that re-sources `.zshenv`, `.zprofile`, `.zshrc`)
- **Format files:** `fm <file>` (alias for `prettier --write`, uses prettier + prettier-plugin-sh from `package.json`)

## Architecture

### Dotbot Symlink Strategy

`install.conf.yaml` globs `home/.*` and symlinks everything into `~/`. This means files in `home/` become dotfiles in the user's home directory (e.g., `home/.zshenv` → `~/.zshenv`, `home/.config/` → `~/.config/`).

### ZSH Loading Order

```
~/.zshenv (home/.zshenv)           — Always sourced. Sets $PATH, $EDITOR, $DOTFILES, $ZDOTDIR, helper functions (_exists, _extend_path)
  → $ZDOTDIR/.zprofile             — Login shell setup
    → $ZDOTDIR/.zshrc              — Interactive shell: zgenom plugins, SSH agent, direnv, fzf, completions
      → $ZDOTDIR/.zlogin           — Post-login
```

`$ZDOTDIR` is `$XDG_CONFIG_HOME/zsh` (`~/.config/zsh`), so the main `.zshrc` lives at `home/.config/zsh/.zshrc`.

### Directory Roles

| Directory           | Purpose                                                                                                                        |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| `home/`             | Symlinked dotfiles (`.zshenv`, `.gitconfig`, `.config/`, `.claude/`, `.ideavimrc`, etc.)                                       |
| `home/.config/zsh/` | ZSH config: `.zshrc`, per-host files (`zsh.$HOST`), topic scripts (`sf.zsh`, `work.zsh`, `osx.zsh`)                            |
| `custom/`           | Custom zgenom plugins (loaded via `zgenom load $DOTFILES/custom`)                                                              |
| `bin/`              | Executable scripts added to `$PATH` (`git-cleanup`, `git-fork`, `emptytrash`, `password`, etc.)                                |
| `scripts/`          | Setup/maintenance scripts (`bootstrap`, `update`, `snapshot`, `restore`, `osx`, `zgenom`, `services`, `downloads`, `projects`) |
| `hooks/`            | Git hooks (`pre-commit`) — symlinked into `.git/hooks/` by dotbot or manually                                                  |
| `dotbot/`           | Dotbot submodule                                                                                                               |
| `backup/`           | Backup storage for dotfile sync                                                                                                |

### Snapshot / Restore Workflow

The `snapshot` + `restore` scripts provide disaster recovery for project repos:

1. **`scripts/snapshot`** — Runs `brew bundle dump` to update `~/.Brewfile`, then scans `~/Projects/` for git repos and writes their relative paths + remote URLs to `home/.repos` (tab-separated, symlinked to `~/.repos`)
2. **`scripts/restore`** — Reads `~/.repos` and clones each repo into `~/Projects/` at its original path, skipping repos that already exist

### Plugin Management

zgenom (in `.zshrc`) manages Oh-My-Zsh plugins and third-party ZSH plugins. The plugin list is cached — zgenom regenerates its init script when files in `ZGEN_RESET_ON_CHANGE` are modified (defined in `.zshenv`).

### Configuration Layers

- **Global git config:** `home/.gitconfig` (includes `~/.gitlocal` for per-machine user identity)
- **Per-host ZSH overrides:** `$ZDOTDIR/zsh.$HOST` (auto-created if missing)
- **Local ZSH overrides:** `~/.zshlocal`
- **Spaceship prompt config:** `home/.config/spaceship/config.zsh`

### Helper Functions (from .zshenv)

- `_exists <cmd>` — check if command exists
- `_extend_path <dir>` — add to `$PATH` without duplicates
- `_green`, `_red` — colored terminal output

## Conventions

- Shell scripts use `#!/usr/bin/env zsh` or `#!/usr/bin/env bash`
- The `$DOTFILES` env var always points to this repo root (`~/.dotfiles`)
- New executable scripts go in `bin/`; new ZSH topic configs go in `home/.config/zsh/`
- All aliases and shell functions go in `home/.config/zsh/aliases.zsh`
- Homebrew packages are tracked in `home/.Brewfile` (symlinked to `~/.Brewfile`; root `Brewfile` symlinks to it)
- Custom tool repos live as git submodules in `home/.local/repos/` with symlinks from `home/.local/bin/`
- Code formatting uses prettier (`.prettierrc` at repo root, `prettier-plugin-sh` for shell scripts)
- Run `zgenom reset` in a terminal after modifying the plugin list in `.zshrc`
- Project folders are scaffolded under `~/Projects/` with subdirs: `Repos`, `Forks`, `Job`, `Playground`
