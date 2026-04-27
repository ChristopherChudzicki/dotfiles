# personal-dotfiles

Shell, prompt, and editor config synced between Macs.

## What's here

- `zsh/` — zshrc and zprofile
- `fish/` — config.fish, conf.d/ (autoloaded settings), functions/ (autoloaded functions)
- `starship/` — prompt config (used by both shells)
- `ghostty/` — Ghostty terminal emulator config
- `install.sh` — idempotent symlink installer with backups
- `docs/` — design and plan documents

## Bootstrap on a new machine

```bash
# 1. Clone
git clone <this-repo-url> ~/dev/personal-dotfiles
cd ~/dev/personal-dotfiles

# 2. Install dependencies via brew
brew install fnm starship fish zsh-syntax-highlighting zsh-autosuggestions
brew install --cask ghostty font-droid-sans-mono-nerd-font

# 3. Symlink config (backs up any existing files first)
./install.sh

# 4. Open a new terminal — zsh picks up the new config

# 5. (Optional) Try fish in the same terminal
fish
```

## Updating

Edit files in this repo directly. Symlinks point here, so changes are live in new shell sessions.

## Backups

`install.sh` backs up any pre-existing config files to `~/dotfiles-backup/<date>/` before replacing them with symlinks.

## Notes

- `nvm` (if present) is left on disk; `fnm` is used for new work. Re-install needed Node versions: `fnm install <version>`.
- `pyenv` (if present) is left on disk but no longer initialized. `uv` covers Python use cases. Remove via `brew uninstall pyenv` when confident.
