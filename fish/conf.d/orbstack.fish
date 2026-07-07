# OrbStack CLI tools (docker, orb, kubectl shims): adds ~/.orbstack/bin to PATH.
# Tracked here instead of letting OrbStack append to the symlinked config.fish.
# No-op on machines without OrbStack installed.
source ~/.orbstack/shell/init2.fish 2>/dev/null || :
