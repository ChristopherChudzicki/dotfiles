#!/usr/bin/env bash
# Idempotent symlink installer with timestamped backups.
# Safe to re-run on any machine.
#
# Fish functions are bucketed: shared/ is always linked; personal/ and work/
# are linked only when explicitly requested.
#
#   ./link.sh                     # shared functions only
#   ./link.sh --personal          # shared + personal
#   ./link.sh --work              # shared + work
#   ./link.sh --personal --work   # everything (e.g. a transition machine)

set -euo pipefail

INSTALL_PERSONAL=0
INSTALL_WORK=0
for arg in "$@"; do
    case "$arg" in
        --personal) INSTALL_PERSONAL=1 ;;
        --work)     INSTALL_WORK=1 ;;
        -h|--help)  echo "usage: ./link.sh [--personal] [--work]"; exit 0 ;;
        *) echo "unknown option: $arg (try --personal, --work)" >&2; exit 1 ;;
    esac
done

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/dotfiles-backup/$(date +%Y-%m-%d)"

# espanso config dir (macOS location)
ESPANSO_DIR="$HOME/Library/Application Support/espanso"

mkdir -p "$BACKUP_DIR"
mkdir -p "$HOME/.config/fish/conf.d"
mkdir -p "$HOME/.config/fish/functions"
mkdir -p "$HOME/.config/ghostty"
mkdir -p "$HOME/.config/ghostty/themes"
mkdir -p "$ESPANSO_DIR/config"
mkdir -p "$ESPANSO_DIR/match"

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

# Remove our own broken symlinks — repo files moved between buckets or deleted —
# so re-runs leave no dangling links behind. Only touches symlinks that point
# into this repo, never unrelated files.
prune_repo_links() {
    local dir="$1"
    [ -d "$dir" ] || return 0
    for link in "$dir"/*; do
        [ -L "$link" ] || continue        # symlinks only
        [ -e "$link" ] && continue        # keep if target still exists
        case "$(readlink "$link")" in
            "$REPO_DIR"/*) echo "prune:  $link"; rm "$link" ;;
        esac
    done
}

prune_repo_links "$HOME/.config/fish/functions"
prune_repo_links "$HOME/.config/fish/conf.d"
prune_repo_links "$HOME/.config/ghostty/themes"
prune_repo_links "$ESPANSO_DIR/config"
prune_repo_links "$ESPANSO_DIR/match"

# Top-level files
link "$REPO_DIR/zsh/zshrc"              "$HOME/.zshrc"
link "$REPO_DIR/zsh/zprofile"           "$HOME/.zprofile"
link "$REPO_DIR/fish/config.fish"       "$HOME/.config/fish/config.fish"
link "$REPO_DIR/starship/starship.toml" "$HOME/.config/starship.toml"
link "$REPO_DIR/ghostty/config"         "$HOME/.config/ghostty/config"

# Fish conf.d/ files
for src in "$REPO_DIR"/fish/conf.d/*.fish; do
    link "$src" "$HOME/.config/fish/conf.d/$(basename "$src")"
done

# Fish functions/ — shared always; personal/ and work/ only when requested.
link_function_dir() {
    local dir="$1"
    [ -d "$dir" ] || return 0
    for src in "$dir"/*.fish; do
        [ -f "$src" ] || continue
        link "$src" "$HOME/.config/fish/functions/$(basename "$src")"
    done
}

link_function_dir "$REPO_DIR/fish/functions/shared"
[ "$INSTALL_PERSONAL" = 1 ] && link_function_dir "$REPO_DIR/fish/functions/personal"
[ "$INSTALL_WORK" = 1 ]     && link_function_dir "$REPO_DIR/fish/functions/work"

# Ghostty user themes
for src in "$REPO_DIR"/ghostty/themes/*; do
    [ -f "$src" ] || continue
    link "$src" "$HOME/.config/ghostty/themes/$(basename "$src")"
done

# espanso — global config and base matches. Installed packages (e.g. lorem)
# are managed by espanso itself and intentionally not tracked here; restore
# them with `espanso install <pkg>` (see README).
link "$REPO_DIR/espanso/config/default.yml" "$ESPANSO_DIR/config/default.yml"
link "$REPO_DIR/espanso/match/base.yml"     "$ESPANSO_DIR/match/base.yml"

echo
echo "done. backups (if any) at: $BACKUP_DIR"
