# Brew (Apple Silicon)
/opt/homebrew/bin/brew shellenv fish | source

# uv-installed tools (~/.local/bin)
fish_add_path -gP $HOME/.local/bin
