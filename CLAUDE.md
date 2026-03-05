# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a macOS-focused dotfiles repository managed by [Dotbot](https://github.com/anishathalye/dotbot). It provides a complete ZSH environment with plugin management via [zgenom](https://github.com/jandamm/zgenom), a [Spaceship](https://github.com/spaceship-prompt/spaceship-prompt) prompt, and extensive shell customization.

## Key Commands

- **Install/sync dotfiles:** `./install` (runs Dotbot with `install.conf.yaml`)
- **Update everything:** `update` (alias for `source $DOTFILES/scripts/update` — updates dotfiles, brew, apt)
- **Bootstrap new machine:** `./scripts/bootstrap` (interactive — installs Homebrew, git, zsh, software, npm packages)
- **Reload shell config:** `reload` (alias that re-sources `.zshenv`, `.zprofile`, `.zshrc`)
- **Format shell scripts:** `npx prettier --write <file>` (prettier + prettier-plugin-sh configured in `package.json`)

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

| Directory | Purpose |
|-----------|---------|
| `home/` | Symlinked dotfiles (`.zshenv`, `.gitconfig`, `.config/`, `.claude/`, `.ideavimrc`, etc.) |
| `home/.config/zsh/` | ZSH config: `.zshrc`, per-host files (`zsh.$HOST`), topic scripts (`sf.zsh`, `work.zsh`, `osx.zsh`) |
| `lib/` | Upstream ZSH scripts loaded by zgenom: `aliases.zsh`, `smartdots.zsh`, `lscolors.zsh` |
| `custom/` | Custom zgenom plugins (loaded via `zgenom load $DOTFILES/custom`) |
| `bin/` | Executable scripts added to `$PATH` (`git-cleanup`, `git-fork`, `emptytrash`, `password`, etc.) |
| `scripts/` | Setup/maintenance scripts (`bootstrap`, `update`, `osx`, `zgenom`, `services`, `downloads`) |
| `dotbot/` | Dotbot submodule |
| `backup/` | Backup storage for dotfile sync |

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
- Aliases and shell functions shared across machines go in `lib/aliases.zsh`
- Homebrew packages are tracked in `home/.Brewfile` (symlinked to `~/.Brewfile`; root `Brewfile` symlinks to it)
- Custom tool repos live as git submodules in `home/.local/repos/` with symlinks from `home/.local/bin/`
- Run `zgenom reset` in a terminal after modifying the plugin list in `.zshrc`
