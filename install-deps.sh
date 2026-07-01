#!/usr/bin/env bash
# Install machine dependencies.
# Idempotent and safe to re-run: installs anything missing, without upgrading
# already-installed deps.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse args.
UPGRADE=false
for arg in "$@"; do
    case "$arg" in
        --upgrade-all)
            UPGRADE=true
            ;;
        -h | --help)
            echo "Usage: $(basename "$0") [--upgrade-all]"
            echo "  --upgrade-all  Also upgrade already-installed deps (default: install missing only)."
            exit 0
            ;;
        *)
            echo "Unknown option: $arg" >&2
            echo "Usage: $(basename "$0") [--upgrade-all]" >&2
            exit 1
            ;;
    esac
done

# --- Homebrew formulae + casks (from the Brewfile) ---------------------------
# By default, --no-upgrade installs what's missing but doesn't silently bump
# existing versions. Pass --upgrade-all to drop it and upgrade everything.
if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew not found. Install it first: https://brew.sh" >&2
    exit 1
fi
if [ "$UPGRADE" = true ]; then
    brew bundle install --file="$REPO_DIR/Brewfile"
else
    brew bundle install --no-upgrade --file="$REPO_DIR/Brewfile"
fi

# --- espanso packages (espanso's own package manager, not brew) --------------
# espanso is installed by the Brewfile above. Its hub packages are managed
# separately; list them here so a fresh machine restores them.
ESPANSO_PACKAGES=(lorem)

if command -v espanso >/dev/null 2>&1; then
    installed="$(espanso package list 2>/dev/null || true)"
    for pkg in "${ESPANSO_PACKAGES[@]}"; do
        if grep -qE "^- $pkg " <<<"$installed"; then
            echo "Using espanso package: $pkg"
        else
            echo "Installing espanso package: $pkg"
            espanso install "$pkg"
        fi
    done
else
    echo "espanso not on PATH yet; skipping package install." \
         "Re-run this script after opening a new shell." >&2
fi
