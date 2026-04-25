# Shell Cleanup & Fish Setup — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the antigen/oh-my-zsh/spaceship zsh stack with a lean zsh setup, add fish as a parallel option, centralize both in `~/dev/personal-dotfiles/`, and serve a shared starship prompt to both shells.

**Architecture:** All configs live in this repo. An idempotent `install.sh` symlinks them into the right locations after backing up any existing files to `~/dotfiles-backup/<date>/`. zsh remains the login shell; fish is opt-in via the `fish` command. Starship is the shared prompt, configured by a single `starship.toml`.

**Tech Stack:** bash (install script), zsh, fish, starship, fnm (replaces nvm), direnv, uv (replaces pyenv).

---

## File Structure

| File | Responsibility |
|------|----------------|
| `README.md` | Bootstrap instructions for a new machine |
| `install.sh` | Idempotent symlink installer with timestamped backups |
| `zsh/zshrc` | Interactive zsh config: prompt, plugins, aliases, ghc function |
| `zsh/zprofile` | Login zsh config: PATH (brew shellenv, uv) |
| `fish/config.fish` | Top-level fish config (intentionally near-empty) |
| `fish/conf.d/path.fish` | PATH setup for fish (brew + uv) |
| `fish/conf.d/env.fish` | Environment vars (EDITOR) |
| `fish/conf.d/fnm.fish` | fnm init with `--use-on-cd` |
| `fish/conf.d/direnv.fish` | direnv hook for fish |
| `fish/conf.d/starship.fish` | starship init for fish |
| `fish/functions/ghc.fish` | `ghc` function (translated from zsh) |
| `fish/functions/chrome.fish` | `chrome` alias as a function |
| `fish/functions/chrome-debug.fish` | `chrome-debug` alias as a function |
| `starship/starship.toml` | Shared starship prompt config (zsh + fish) |

The repo already has `docs/2026-04-25-shell-cleanup-design.md` committed.

---

## Task 1: Write `README.md`

**Files:**
- Create: `~/dev/personal-dotfiles/README.md`

- [ ] **Step 1: Write README**

Write `~/dev/personal-dotfiles/README.md` with:

````markdown
# personal-dotfiles

Shell, prompt, and editor config synced between Macs.

## What's here

- `zsh/` — zshrc and zprofile
- `fish/` — config.fish, conf.d/ (autoloaded settings), functions/ (autoloaded functions)
- `starship/` — prompt config (used by both shells)
- `install.sh` — idempotent symlink installer with backups
- `docs/` — design and plan documents

## Bootstrap on a new machine

```bash
# 1. Clone
git clone <this-repo-url> ~/dev/personal-dotfiles
cd ~/dev/personal-dotfiles

# 2. Install dependencies via brew
brew install fnm starship fish zsh-syntax-highlighting zsh-autosuggestions

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
````

- [ ] **Step 2: Verify**

Run: `head -5 ~/dev/personal-dotfiles/README.md`
Expected: First 5 lines including `# personal-dotfiles` heading.

- [ ] **Step 3: Commit**

```bash
cd ~/dev/personal-dotfiles
git add README.md
git commit -m "docs: add README with bootstrap instructions"
```

---

## Task 2: Write `install.sh`

**Files:**
- Create: `~/dev/personal-dotfiles/install.sh`

- [ ] **Step 1: Write install.sh**

Write `~/dev/personal-dotfiles/install.sh`:

```bash
#!/usr/bin/env bash
# Idempotent symlink installer with timestamped backups.
# Safe to re-run on any machine.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/dotfiles-backup/$(date +%Y-%m-%d)"

mkdir -p "$BACKUP_DIR"
mkdir -p "$HOME/.config/fish/conf.d"
mkdir -p "$HOME/.config/fish/functions"

link() {
    local src="$1"
    local dest="$2"

    # Already correctly linked?
    if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
        echo "ok:     $dest"
        return
    fi

    # Back up existing file or wrong-target symlink
    if [ -e "$dest" ] || [ -L "$dest" ]; then
        local backup="$BACKUP_DIR/$(basename "$dest")"
        if [ -e "$backup" ]; then
            backup="${backup}.$(date +%H%M%S)"
        fi
        echo "backup: $dest -> $backup"
        mv "$dest" "$backup"
    fi

    mkdir -p "$(dirname "$dest")"
    ln -s "$src" "$dest"
    echo "linked: $dest"
}

# Top-level files
link "$REPO_DIR/zsh/zshrc"              "$HOME/.zshrc"
link "$REPO_DIR/zsh/zprofile"           "$HOME/.zprofile"
link "$REPO_DIR/fish/config.fish"       "$HOME/.config/fish/config.fish"
link "$REPO_DIR/starship/starship.toml" "$HOME/.config/starship.toml"

# Fish conf.d/ files
for src in "$REPO_DIR"/fish/conf.d/*.fish; do
    link "$src" "$HOME/.config/fish/conf.d/$(basename "$src")"
done

# Fish functions/ files
for src in "$REPO_DIR"/fish/functions/*.fish; do
    link "$src" "$HOME/.config/fish/functions/$(basename "$src")"
done

echo
echo "done. backups (if any) at: $BACKUP_DIR"
```

- [ ] **Step 2: Make executable**

Run: `chmod +x ~/dev/personal-dotfiles/install.sh`

- [ ] **Step 3: Syntax check**

Run: `bash -n ~/dev/personal-dotfiles/install.sh`
Expected: no output, exit 0.

- [ ] **Step 4: Commit**

```bash
cd ~/dev/personal-dotfiles
git add install.sh
git commit -m "feat: add idempotent symlink installer"
```

---

## Task 3: Install brew dependencies

**Files:** none (system-level installs)

- [ ] **Step 1: Check what's already installed**

Run: `brew list --formula | grep -E '^(fnm|starship|fish|zsh-syntax-highlighting|zsh-autosuggestions)$' || true`
Expected: lists any already-installed packages (likely none of these).

- [ ] **Step 2: Install missing packages**

Run: `brew install fnm starship fish zsh-syntax-highlighting zsh-autosuggestions`
Expected: `==> Pouring ...` for each new package, no errors.

- [ ] **Step 3: Verify each binary**

Run:
```bash
which fnm starship fish
ls /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
ls /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
```
Expected: paths printed for each, no `not found` or `No such file`.

(Nothing to commit — this is system state.)

---

## Task 4: Write zsh config

**Files:**
- Create: `~/dev/personal-dotfiles/zsh/zshrc`
- Create: `~/dev/personal-dotfiles/zsh/zprofile`

- [ ] **Step 1: Create directory and write zshrc**

```bash
mkdir -p ~/dev/personal-dotfiles/zsh
```

Write `~/dev/personal-dotfiles/zsh/zshrc`:

```bash
# Editor
export EDITOR=/usr/local/bin/code

# Aliases
alias chrome="open -a 'Google Chrome'"
alias chrome-debug="/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome \
    --remote-debugging-port=9222 \
    --profile-directory='Profile 9'"

# Completions
autoload -Uz compinit && compinit

# zsh plugins (sourced directly, no framework)
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# Prompt
eval "$(starship init zsh)"

# Tools
eval "$(fnm env --use-on-cd --shell zsh)"
eval "$(direnv hook zsh)"

# Functions
ghc() {
    copilot \
        --allow-tool='write' \
        --allow-tool='shell(git log)' \
        --allow-tool='shell(git status)' \
        --allow-tool='shell(echo)' \
        --allow-tool='shell(grep)' \
        --allow-tool='shell(find)' \
        --allow-tool='shell(ls)' \
        --allow-tool='shell(cat)' \
        --allow-tool='shell(head)' \
        --allow-tool='shell(tail)' \
        --allow-tool='shell(sed)' \
        --allow-tool='shell(awk)' \
        --allow-tool='shell(sort)' \
        --allow-tool='shell(uniq)' \
        --allow-tool='shell(wc)' \
        --allow-tool='shell(jq)' \
        "$@"
}
```

- [ ] **Step 2: Write zprofile**

Write `~/dev/personal-dotfiles/zsh/zprofile`:

```bash
# Brew (Apple Silicon path; sets PATH, MANPATH, INFOPATH, HOMEBREW_*)
eval "$(/opt/homebrew/bin/brew shellenv)"

# uv-installed tools (~/.local/bin)
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"
```

- [ ] **Step 3: Syntax check**

Run:
```bash
zsh -n ~/dev/personal-dotfiles/zsh/zshrc
zsh -n ~/dev/personal-dotfiles/zsh/zprofile
```
Expected: no output, exit 0 for both.

- [ ] **Step 4: Commit**

```bash
cd ~/dev/personal-dotfiles
git add zsh/zshrc zsh/zprofile
git commit -m "feat: add cleaned zsh config (no framework, starship, fnm)"
```

---

## Task 5: Write starship config

**Files:**
- Create: `~/dev/personal-dotfiles/starship/starship.toml`

- [ ] **Step 1: Create directory**

```bash
mkdir -p ~/dev/personal-dotfiles/starship
```

- [ ] **Step 2: Write starship.toml**

Write `~/dev/personal-dotfiles/starship/starship.toml`:

```toml
# Shared by zsh and fish.
# Two-line prompt: directory + git + language versions, then a clean arrow.
# Replaces spaceship-prompt.

format = """
$directory\
$git_branch\
$git_status\
$python\
$nodejs\
$line_break\
$character\
"""

[character]
success_symbol = "[➜](bold green)"
error_symbol = "[✗](bold red)"

[directory]
truncation_length = 3
truncate_to_repo = true
style = "bold cyan"

[git_branch]
symbol = " "
style = "bold purple"

[git_status]
ahead = "↑${count}"
behind = "↓${count}"
diverged = "↑${ahead_count}↓${behind_count}"
untracked = "?"
modified = "!"
staged = "+"
deleted = "✘"
stashed = "≡"
style = "bold yellow"

[python]
symbol = " "
format = "[$symbol$version]($style) "
style = "bold green"

[nodejs]
symbol = " "
format = "[$symbol$version]($style) "
style = "bold green"
```

- [ ] **Step 3: Validate config**

Run: `STARSHIP_CONFIG=~/dev/personal-dotfiles/starship/starship.toml starship explain 2>&1 | head -10`
Expected: lists modules that will render, with no `Error parsing config` or similar messages on stderr.

- [ ] **Step 4: Commit**

```bash
cd ~/dev/personal-dotfiles
git add starship/starship.toml
git commit -m "feat: add starship config (spaceship-like, two-line)"
```

---

## Task 6: Write fish config

**Files:**
- Create: `~/dev/personal-dotfiles/fish/config.fish`
- Create: `~/dev/personal-dotfiles/fish/conf.d/path.fish`
- Create: `~/dev/personal-dotfiles/fish/conf.d/env.fish`
- Create: `~/dev/personal-dotfiles/fish/conf.d/fnm.fish`
- Create: `~/dev/personal-dotfiles/fish/conf.d/direnv.fish`
- Create: `~/dev/personal-dotfiles/fish/conf.d/starship.fish`
- Create: `~/dev/personal-dotfiles/fish/functions/ghc.fish`
- Create: `~/dev/personal-dotfiles/fish/functions/chrome.fish`
- Create: `~/dev/personal-dotfiles/fish/functions/chrome-debug.fish`

- [ ] **Step 1: Create directories**

```bash
mkdir -p ~/dev/personal-dotfiles/fish/conf.d
mkdir -p ~/dev/personal-dotfiles/fish/functions
```

- [ ] **Step 2: Write config.fish**

Write `~/dev/personal-dotfiles/fish/config.fish`:

```fish
# Most config lives in conf.d/ (autoloaded in lexical order).
# Add only ordering-sensitive items here.
```

- [ ] **Step 3: Write conf.d/path.fish**

Write `~/dev/personal-dotfiles/fish/conf.d/path.fish`:

```fish
# Brew (Apple Silicon)
/opt/homebrew/bin/brew shellenv fish | source

# uv-installed tools (~/.local/bin)
fish_add_path -gP $HOME/.local/bin
```

- [ ] **Step 4: Write conf.d/env.fish**

Write `~/dev/personal-dotfiles/fish/conf.d/env.fish`:

```fish
set -gx EDITOR /usr/local/bin/code
```

- [ ] **Step 5: Write conf.d/fnm.fish**

Write `~/dev/personal-dotfiles/fish/conf.d/fnm.fish`:

```fish
fnm env --use-on-cd --shell fish | source
```

- [ ] **Step 6: Write conf.d/direnv.fish**

Write `~/dev/personal-dotfiles/fish/conf.d/direnv.fish`:

```fish
direnv hook fish | source
```

- [ ] **Step 7: Write conf.d/starship.fish**

Write `~/dev/personal-dotfiles/fish/conf.d/starship.fish`:

```fish
starship init fish | source
```

- [ ] **Step 8: Write functions/ghc.fish**

Write `~/dev/personal-dotfiles/fish/functions/ghc.fish`:

```fish
function ghc
    copilot \
        --allow-tool='write' \
        --allow-tool='shell(git log)' \
        --allow-tool='shell(git status)' \
        --allow-tool='shell(echo)' \
        --allow-tool='shell(grep)' \
        --allow-tool='shell(find)' \
        --allow-tool='shell(ls)' \
        --allow-tool='shell(cat)' \
        --allow-tool='shell(head)' \
        --allow-tool='shell(tail)' \
        --allow-tool='shell(sed)' \
        --allow-tool='shell(awk)' \
        --allow-tool='shell(sort)' \
        --allow-tool='shell(uniq)' \
        --allow-tool='shell(wc)' \
        --allow-tool='shell(jq)' \
        $argv
end
```

- [ ] **Step 9: Write functions/chrome.fish**

Write `~/dev/personal-dotfiles/fish/functions/chrome.fish`:

```fish
function chrome
    open -a 'Google Chrome' $argv
end
```

- [ ] **Step 10: Write functions/chrome-debug.fish**

Write `~/dev/personal-dotfiles/fish/functions/chrome-debug.fish`:

```fish
function chrome-debug
    /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome \
        --remote-debugging-port=9222 \
        --profile-directory='Profile 9' $argv
end
```

- [ ] **Step 11: Syntax check (parse each file)**

Run:
```bash
for f in ~/dev/personal-dotfiles/fish/config.fish \
         ~/dev/personal-dotfiles/fish/conf.d/*.fish \
         ~/dev/personal-dotfiles/fish/functions/*.fish; do
    fish -n "$f" && echo "ok: $f" || echo "FAIL: $f"
done
```
Expected: `ok: ...` for each file.

- [ ] **Step 12: Commit**

```bash
cd ~/dev/personal-dotfiles
git add fish/
git commit -m "feat: add fish config (conf.d split, functions autoloaded)"
```

---

## Task 7: Run install.sh and verify symlinks

**Files:** symlinks created at:
- `~/.zshrc`, `~/.zprofile`
- `~/.config/fish/config.fish`, `~/.config/fish/conf.d/*.fish`, `~/.config/fish/functions/*.fish`
- `~/.config/starship.toml`

Backups land at: `~/dotfiles-backup/2026-04-25/`

- [ ] **Step 1: Snapshot current zsh startup time**

Run: `for i in 1 2 3; do /usr/bin/time zsh -i -c exit 2>&1 | tail -1; done`
Expected: ~0.33–0.60s real time (baseline; will improve after install).

- [ ] **Step 2: Run installer**

Run: `~/dev/personal-dotfiles/install.sh`
Expected output: lines like `backup: /Users/cchudzicki/.zshrc -> /Users/cchudzicki/dotfiles-backup/2026-04-25/.zshrc` and `linked: ...` for each managed file. Final line: `done. backups (if any) at: ...`.

- [ ] **Step 3: Verify zsh symlinks**

Run: `ls -la ~/.zshrc ~/.zprofile`
Expected: both shown as symlinks (`l` in mode bits) pointing into `~/dev/personal-dotfiles/zsh/`.

- [ ] **Step 4: Verify fish symlinks**

Run: `ls -la ~/.config/fish/config.fish ~/.config/fish/conf.d/ ~/.config/fish/functions/`
Expected: `config.fish` is a symlink; `conf.d/` and `functions/` directories contain symlinks (one `*.fish` per managed file) pointing into the repo.

- [ ] **Step 5: Verify starship symlink**

Run: `ls -la ~/.config/starship.toml`
Expected: symlink pointing into `~/dev/personal-dotfiles/starship/`.

- [ ] **Step 6: Verify backups exist**

Run: `ls -la ~/dotfiles-backup/2026-04-25/`
Expected: at minimum, the original `.zshrc` and `.zprofile` are present.

- [ ] **Step 7: Re-run installer (idempotency check)**

Run: `~/dev/personal-dotfiles/install.sh`
Expected: every line is `ok: ...` — no new backups, no re-linking.

---

## Task 8: Verify zsh in a fresh session

- [ ] **Step 1: Time fresh startup**

Run: `for i in 1 2 3; do /usr/bin/time zsh -i -c exit 2>&1 | tail -1; done`
Expected: ~80–150ms real time per run (down from 330–600ms baseline). If still >250ms, something didn't load lazily — check that `pyenv init` and `nvm` lines are gone from the symlinked files.

- [ ] **Step 2: Verify no startup errors**

Run: `zsh -i -c exit 2>&1`
Expected: no output. Any error indicates a missing dependency or syntax issue.

- [ ] **Step 3: Verify starship loaded**

Run: `zsh -i -c 'echo $PROMPT' 2>&1 | head -3`
Expected: a non-empty prompt string containing starship's escape sequences (will look like garbled text starting with `%{` or similar — that's correct).

- [ ] **Step 4: Verify tools available**

Run: `zsh -i -c 'which starship fnm direnv && type ghc'`
Expected:
```
/opt/homebrew/bin/starship
/opt/homebrew/bin/fnm
/opt/homebrew/bin/direnv
ghc is a shell function
```

- [ ] **Step 5: Verify completions and plugins**

Run: `zsh -i -c 'echo ZSH_HIGHLIGHT_VERSION=$ZSH_HIGHLIGHT_VERSION; echo ZSH_AUTOSUGGEST_STRATEGY=$ZSH_AUTOSUGGEST_STRATEGY'`
Expected: both variables non-empty (proves both plugins were sourced).

---

## Task 9: Re-install Node versions in fnm

- [ ] **Step 1: List existing nvm-managed Node versions**

Run: `ls ~/.nvm/versions/node/ 2>/dev/null || echo "no nvm versions"`
Expected: directory names like `v18.20.0`, `v20.11.1`, etc. — or "no nvm versions" if you haven't used nvm.

- [ ] **Step 2: Install each in fnm**

For each version listed in step 1, run (replacing `<version>` with e.g. `20`):

```bash
fnm install <version>
```

For multiple: `fnm install 18 && fnm install 20 && fnm install 22` (or whichever are relevant).

Expected: `Installing Node v<version>...` followed by completion.

- [ ] **Step 3: Set a default**

Run: `fnm default <your-most-used-version>` (e.g. `fnm default 20`).
Expected: no output on success.

- [ ] **Step 4: Verify default works in a fresh shell**

Run: `zsh -i -c 'node --version'`
Expected: prints `v20.x.x` (or whichever default you set).

- [ ] **Step 5: Verify auto-switch on cd**

Run, replacing `<some-project>` with a project that has a `.nvmrc` file:
```bash
zsh -i -c 'cd <some-project> && node --version'
```
Expected: prints the version specified in `.nvmrc`.

If you don't have a project with `.nvmrc` handy, create a quick test:
```bash
mkdir /tmp/nvmrc-test && echo "18" > /tmp/nvmrc-test/.nvmrc
zsh -i -c 'cd /tmp/nvmrc-test && node --version'
rm -rf /tmp/nvmrc-test
```
Expected: prints `v18.x.x`.

---

## Task 10: Verify fish in a subshell

- [ ] **Step 1: Launch fish and check it starts cleanly**

Run: `fish -i -c exit 2>&1`
Expected: no output. Any error indicates a config issue.

- [ ] **Step 2: Verify env**

Run: `fish -i -c 'echo $EDITOR; echo $PATH | tr " " "\n" | head -5'`
Expected: `/usr/local/bin/code` then a PATH listing including `/opt/homebrew/bin` and `~/.local/bin`.

- [ ] **Step 3: Verify starship and tools**

Run: `fish -i -c 'which starship fnm direnv'`
Expected: paths to all three.

- [ ] **Step 4: Verify functions are autoloaded**

Run: `fish -i -c 'functions -q ghc chrome chrome-debug; and echo all-present'`
Expected: `all-present`.

- [ ] **Step 5: Verify fnm cd-switching in fish**

Run:
```bash
mkdir /tmp/nvmrc-test && echo "18" > /tmp/nvmrc-test/.nvmrc
fish -i -c 'cd /tmp/nvmrc-test; node --version'
rm -rf /tmp/nvmrc-test
```
Expected: prints `v18.x.x` (assuming `fnm install 18` was done in Task 9).

- [ ] **Step 6: Time fish startup**

Run: `for i in 1 2 3; do /usr/bin/time fish -i -c exit 2>&1 | tail -1; done`
Expected: ~80–150ms real time per run.

---

## Task 11: Push to GitHub (user-gated)

This step creates a remote repo. **Confirm with user before running.**

- [ ] **Step 1: Confirm visibility preference**

Ask user: public or private? (Private is the safe default for personal dotfiles.)

- [ ] **Step 2: Create remote**

Run (substituting visibility):
```bash
cd ~/dev/personal-dotfiles
gh repo create personal-dotfiles --private --source=. --remote=origin --push
```
Expected: repo created, current `main` branch pushed.

- [ ] **Step 3: Verify**

Run: `gh repo view --json url -q .url`
Expected: URL of the new repo.

---

## Post-implementation notes (no action required)

- Login shell remains `/bin/zsh`. To switch later: add fish to `/etc/shells` (`echo /opt/homebrew/bin/fish | sudo tee -a /etc/shells`), then `chsh -s /opt/homebrew/bin/fish`.
- `~/.nvm/` and pyenv install are untouched. Remove when comfortable: `rm -rf ~/.nvm` and `brew uninstall pyenv pyenv-virtualenv`.
- On the new work Mac: `git clone <repo-url> ~/dev/personal-dotfiles && cd ~/dev/personal-dotfiles && brew install fnm starship fish zsh-syntax-highlighting zsh-autosuggestions && ./install.sh`.
- If a starship icon doesn't render (squares/?), the terminal lacks a Nerd Font. iTerm2: Preferences → Profiles → Text → Font → choose a Nerd Font variant.
