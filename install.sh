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
