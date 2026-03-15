#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

if ! command -v brew &>/dev/null; then
    echo "Error: Homebrew is required. Install it from https://brew.sh"
    exit 1
fi

echo "==> Installing Homebrew packages"
brew bundle --file="$DOTFILES/Brewfile"

echo "==> Linking config files"

link() {
    local src="$1" dst="$2"
    mkdir -p "$(dirname "$dst")"
    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
        echo "  Backing up $dst -> ${dst}.bak"
        mv "$dst" "${dst}.bak"
    fi
    ln -sfn "$src" "$dst"
    echo "  $dst -> $src"
}

link "$DOTFILES/bash_profile"                          "$HOME/.bash_profile"
link "$DOTFILES/inputrc"                               "$HOME/.inputrc"
link "$DOTFILES/gitconfig"                             "$HOME/.gitconfig"
link "$DOTFILES/ssh_config"                            "$HOME/.ssh/config"
chmod 700 "$HOME/.ssh"
chmod 600 "$HOME/.ssh/config"
link "$DOTFILES/config/ghostty/config"                 "$HOME/.config/ghostty/config"
link "$DOTFILES/config/nvim"                           "$HOME/.config/nvim"
link "$DOTFILES/config/starship.toml"                  "$HOME/.config/starship.toml"
link "$DOTFILES/config/bat/config"                     "$HOME/.config/bat/config"
link "$DOTFILES/config/mc/skins/catppuccin-mocha.ini"  "$HOME/.local/share/mc/skins/catppuccin-mocha.ini"
link "$DOTFILES/config/vscode/settings.json"           "$HOME/Library/Application Support/Code/User/settings.json"

echo "==> Installing VS Code extensions"
if command -v code &>/dev/null; then
    while IFS= read -r ext; do
        code --install-extension "$ext" --force 2>/dev/null || true
    done < "$DOTFILES/config/vscode/extensions.txt"
else
    echo "  WARNING: 'code' CLI not found — install VS Code and run 'Shell Command: Install code in PATH'"
fi

echo "==> Checking local config files"
if [ ! -f "$HOME/.gitconfig.local" ]; then
    echo "  WARNING: ~/.gitconfig.local not found — create it with your [user] name/email"
fi
if [ ! -f "$HOME/.ssh/config.local" ]; then
    echo "  WARNING: ~/.ssh/config.local not found — create it with your Host entries"
fi

echo "==> Done! Open a new terminal tab to apply changes."
