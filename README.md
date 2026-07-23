# dotfiles

Shell, prompt, and editor config synced between Macs.

## What's here

- `zsh/` — zshrc and zprofile
- `fish/` — config.fish, conf.d/ (autoloaded settings), functions/ (autoloaded functions, bucketed into `shared/`, `personal/`, `work/`)
- `starship/` — prompt config (used by both shells)
- `bin/` — standalone helper scripts, invoked by absolute path (not on `$PATH`), except `claude-tts` which `link.sh` exposes on `$PATH` via `~/.local/bin`
- `ghostty/` — Ghostty terminal emulator config
- `espanso/` — espanso text expander: global config (`config/`) and snippets (`match/`)
- `link.sh` — idempotent symlink installer with backups
- `install-deps.sh` — installs Homebrew dependencies (idempotent)
- `Brewfile` — declarative list of brew formulae and casks
- `docs/` — design and plan documents

## Bootstrap on a new machine

```bash
# 1. Clone
git clone <this-repo-url> ~/dev/dotfiles
cd ~/dev/dotfiles

# 2. Install dependencies (brew formulae + casks from the Brewfile). Idempotent.
./install-deps.sh                 # installs missing deps only
# ./install-deps.sh --upgrade-all # also upgrade already-installed deps

# 3. Symlink config (backs up any existing files first).
#    Fish functions: shared/ is always linked; pick which private buckets to add.
./link.sh --personal            # personal machine
# ./link.sh --work              # work machine
# ./link.sh --personal --work   # a machine that's both (e.g. during transition)

# 4. Open a new terminal — zsh picks up the new config

# 5. (Optional) Try fish in the same terminal
fish

# 6. (Per-machine) To make fish your shell, set it as your login shell.
#    Ghostty and other terminals launch your login shell, so this is what makes
#    fish the default. Not symlinked — it mutates system state (/etc/shells needs
#    sudo) and is a per-machine choice; skip it to keep zsh (e.g. a work machine).
fish_path="$(brew --prefix)/bin/fish"
grep -qxF "$fish_path" /etc/shells || echo "$fish_path" | sudo tee -a /etc/shells
chsh -s "$fish_path"
```

## Updating

Edit files in this repo directly. Symlinks point here, so changes are live in new shell sessions.

## Backups

`link.sh` backs up any pre-existing config files to `~/dotfiles-backup/<date>/` before replacing them with symlinks.

## Notes

- espanso: only the global config and base snippets are tracked; hub packages are managed by espanso, not symlinked. `install-deps.sh` reinstalls them (currently just `lorem`) — add new ones to the `ESPANSO_PACKAGES` list there.
- `nvm` (if present) is left on disk; `fnm` is used for new work. Re-install needed Node versions: `fnm install <version>`.
- `pyenv` (if present) is left on disk but no longer initialized. `uv` covers Python use cases. Remove via `brew uninstall pyenv` when confident.

## Claude Code read-aloud (`bin/claude-tts`)

Reads Claude Code responses aloud via macOS `say`, with markdown stripped for
speech (formatting dropped; code blocks/tables/images collapse to short spoken
placeholders). Requires `uv` (in the Brewfile); deps are declared inline in the
script and fetched on first run.

Unlike most `bin/` scripts, this one is invoked by name: `link.sh` symlinks it
into `~/.local/bin` (on `$PATH` in every shell), so `claude-tts` works from zsh,
fish, and Claude Code's `!` shell alike.

Speaking is **off by default** and enabled per scope, most-specific wins:

```bash
claude-tts on            # this session only (run inside a session: !claude-tts on)
claude-tts on --repo     # every session in the current git repo
claude-tts on --global   # everywhere
claude-tts off [--repo|--global]   # same scopes
claude-tts status        # effective setting + where it resolved
```

State lives in `~/.claude/tts/`. A new response interrupts any in-progress
speech, and starting a new prompt silences it.

`~/.claude/settings.json` is **not** managed by this repo, so the hooks that
drive it must be added there by hand on each machine — three entries pointing at
this script (adjust the path if the repo isn't at `~/dev/dotfiles`):

- `Stop` → `.../bin/claude-tts speak` — speak the finished response
- `UserPromptSubmit` → `.../bin/claude-tts stop` — silence speech on a new prompt
- `SessionEnd` → `.../bin/claude-tts cleanup` — drop the session's toggle file

Add each alongside any existing hooks for that event rather than replacing them.
