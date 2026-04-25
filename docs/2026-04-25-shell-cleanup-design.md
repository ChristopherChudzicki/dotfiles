# Shell Cleanup & Fish Setup — Design

**Date:** 2026-04-25
**Status:** Approved, pending implementation plan

## Goals

- Replace the antigen + oh-my-zsh + spaceship-prompt zsh stack with a lean, fast setup.
- Add fish as a parallel option, without changing the login shell.
- Centralize shell config in a personal dotfiles repo so it can be cloned to the incoming work Mac.
- Single, consistent prompt across both shells via starship.

## Non-Goals

- Terminal emulator switch (Ghostty / iTerm2). Deferred to a separate session.
- nushell evaluation.
- Tmux configuration.
- Migrating the iTerm2 settings stored in `~/.config/iterm2/`.

## Repository Layout

Repo lives at `~/dev/personal-dotfiles/`.

```
~/dev/personal-dotfiles/
├── README.md             # bootstrap steps for a new machine
├── install.sh            # idempotent symlink installer with backups
├── docs/                 # design + plan documents
├── zsh/
│   ├── zshrc             # → ~/.zshrc
│   └── zprofile          # → ~/.zprofile
├── fish/
│   ├── config.fish       # → ~/.config/fish/config.fish
│   ├── conf.d/           # → ~/.config/fish/conf.d/
│   │   ├── path.fish
│   │   ├── env.fish
│   │   ├── fnm.fish
│   │   ├── direnv.fish
│   │   └── starship.fish
│   └── functions/        # → ~/.config/fish/functions/
│       └── ghc.fish
└── starship/
    └── starship.toml     # → ~/.config/starship.toml
```

## Components

### `install.sh`

A small bash script (~30 lines) that:

- Creates `~/dotfiles-backup/<YYYY-MM-DD>/` and copies any existing target file there before overwriting.
- Symlinks each managed file from the repo to its target location.
- Is idempotent: re-running on the same machine, or running fresh on the new work Mac, produces the same result without errors.
- Does not install brew packages (those are listed in the README as prerequisites).

### Cleaned `zsh/zshrc`

Approximately 18 lines. Removes:

- `antigen`, `oh-my-zsh`, `spaceship-prompt`
- `heroku`, `lein`, `pip`, `command-not-found` bundles
- `nvm` and `pyenv` initialization

Adds / keeps:

- `starship init zsh` (subshelled at startup; <10ms)
- `zsh-syntax-highlighting` and `zsh-autosuggestions` sourced directly from `/opt/homebrew/share/`
- `fnm env --use-on-cd` for Node version switching on `cd`
- `direnv hook zsh`
- Existing aliases: `chrome`, `chrome-debug`
- Existing function: `ghc`
- `EDITOR=/usr/local/bin/code`

### Cleaned `zsh/zprofile`

PATH setup via `eval "$(/opt/homebrew/bin/brew shellenv)"`. Removes nvm. Drops the legacy `/usr/local/bin` prepend (brew shellenv handles PATH correctly on Apple Silicon).

### `fish/config.fish`

Minimal — just `source` of any environment that needs ordering. Most setup goes in `conf.d/`.

### `fish/conf.d/*.fish`

One file per concern, autoloaded by fish in lexical order:

- `path.fish` — brew shellenv equivalent for fish
- `env.fish` — `EDITOR`, etc.
- `fnm.fish` — `fnm env --use-on-cd | source`
- `direnv.fish` — `direnv hook fish | source`
- `starship.fish` — `starship init fish | source`

### `fish/functions/ghc.fish`

`ghc` translated to fish syntax. Other functions (`ocw_studio_env`) are dropped per design discussion.

### `starship/starship.toml`

Seeded from a starship preset close to the spaceship aesthetic (likely `pastel-powerline` or `nerd-font-symbols` — confirm with `starship preset --list` during execution). The intent is a working two-line prompt with git segment on first launch; further tuning happens later.

## Dependencies

Installed via brew (listed in README, not automated by `install.sh`):

- `starship`
- `fnm`
- `fish`
- `zsh-syntax-highlighting`
- `zsh-autosuggestions`

Already installed: `direnv`, `git`, `uv`.

## Migration Strategy

1. Initialize repo (this step — done).
2. Write spec and plan to `docs/`.
3. Install missing brew dependencies.
4. Author all config files in repo.
5. Run `install.sh` — backs up current `.zshrc`, `.zprofile` to `~/dotfiles-backup/2026-04-25/`, then symlinks.
6. Open a new zsh session, verify behavior.
7. Re-install Node versions used in active projects via `fnm install <version>`.
8. Try fish in a subshell (`fish`); verify env, prompt, completions, `cd` auto-switching.
9. Commit and push. Repo is ready for cloning on the incoming work Mac.

## Safety / Rollback

- All existing config backed up to `~/dotfiles-backup/2026-04-25/` before any symlinking.
- Login shell remains zsh; fish is opt-in via `fish` command.
- `nvm` install in `~/.nvm/` is left untouched as a fallback during transition. Removal happens manually later.
- `pyenv` install is left untouched but no longer initialized. Removal via `brew uninstall pyenv` whenever the user is confident `uv` covers everything.
- If a problem appears: `rm` the symlink, restore the backed-up file. No global state changes besides those symlinks.

## Verification

After `install.sh` and a fresh zsh session:

- `time zsh -i -c exit` shows startup under ~150ms (vs. current 330–600ms).
- `which starship && starship --version` succeeds.
- Prompt renders with git branch, dirty state, etc.
- `cd` into a directory containing `.nvmrc` switches Node automatically.
- `direnv` activates `.envrc` files as before.
- `fish` launches; prompt and env match zsh; `cd` auto-switching works there too.

## Open Items (resolved during execution)

- Which Node versions to re-install in `fnm` (depends on active projects at the time).
- Whether to `brew uninstall pyenv` and delete `~/.nvm` at the end (user choice once confident).
