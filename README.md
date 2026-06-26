# personal-dotfiles

Shell, prompt, and editor config synced between Macs.

## What's here

- `zsh/` — zshrc and zprofile
- `fish/` — config.fish, conf.d/ (autoloaded settings), functions/ (autoloaded functions, bucketed into `shared/`, `personal/`, `work/`)
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

# 3. Symlink config (backs up any existing files first).
#    Fish functions: shared/ is always linked; pick which private buckets to add.
./install.sh --personal            # personal machine
# ./install.sh --work              # work machine
# ./install.sh --personal --work   # a machine that's both (e.g. during transition)

# 4. Open a new terminal — zsh picks up the new config

# 5. (Optional) Try fish in the same terminal
fish

# 6. (Optional, per-machine) Make fish your login shell.
#    Not symlinked — it mutates system state (/etc/shells needs sudo) and is a
#    per-machine choice. Skip it on machines where you want zsh as the default.
fish_path="$(brew --prefix)/bin/fish"
grep -qxF "$fish_path" /etc/shells || echo "$fish_path" | sudo tee -a /etc/shells
chsh -s "$fish_path"
```

## Updating

Edit files in this repo directly. Symlinks point here, so changes are live in new shell sessions.

## Backups

`install.sh` backs up any pre-existing config files to `~/dotfiles-backup/<date>/` before replacing them with symlinks.

## Notes

- `nvm` (if present) is left on disk; `fnm` is used for new work. Re-install needed Node versions: `fnm install <version>`.
- `pyenv` (if present) is left on disk but no longer initialized. `uv` covers Python use cases. Remove via `brew uninstall pyenv` when confident.
