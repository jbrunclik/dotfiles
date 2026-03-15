#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

if [[ -t 1 ]]; then
    RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[0;33m'
    BLUE='\033[0;34m' BOLD='\033[1m' RESET='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' BOLD='' RESET=''
fi

header() { echo -e "${BOLD}${BLUE}==> $1${RESET}"; }
warn()   { echo -e "  ${YELLOW}WARNING${RESET}: $1"; }
err()    { echo -e "${RED}Error${RESET}: $1"; }

if ! command -v brew &>/dev/null; then
    err "Homebrew is required. Install it from https://brew.sh"
    exit 1
fi

header "Installing Homebrew packages"
brew bundle --file="$DOTFILES/Brewfile"

header "Linking config files"

link() {
    local src="$1" dst="$2"
    mkdir -p "$(dirname "$dst")"
    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
        echo -e "  ${YELLOW}Backing up${RESET} $dst -> ${dst}.bak"
        mv "$dst" "${dst}.bak"
    fi
    ln -sfn "$src" "$dst"
    echo -e "  ${GREEN}✓${RESET} $dst -> $src"
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
link "$DOTFILES/config/bat/themes/CatppuccinMocha.tmTheme" "$HOME/.config/bat/themes/CatppuccinMocha.tmTheme"
link "$DOTFILES/config/mc/skins/catppuccin-mocha.ini"  "$HOME/.local/share/mc/skins/catppuccin-mocha.ini"
link "$DOTFILES/config/vscode/settings.json"           "$HOME/Library/Application Support/Code/User/settings.json"
link "$DOTFILES/config/karabiner/karabiner.json"       "$HOME/.config/karabiner/karabiner.json"
# Hammerspoon doesn't follow symlinks for init.lua — use a loader file
mkdir -p "$HOME/.hammerspoon"
echo "dofile(\"$DOTFILES/config/hammerspoon/init.lua\")" > "$HOME/.hammerspoon/init.lua"
echo -e "  ${GREEN}✓${RESET} $HOME/.hammerspoon/init.lua -> dofile loader"

header "Building bat theme cache"
bat cache --build

header "Installing VS Code extensions"
if command -v code &>/dev/null; then
    while IFS= read -r ext; do
        code --install-extension "$ext" --force 2>/dev/null || true
    done < "$DOTFILES/config/vscode/extensions.txt"
else
    warn "'code' CLI not found — install VS Code and run 'Shell Command: Install code in PATH'"
fi

header "Checking local config files"
if [ ! -f "$HOME/.gitconfig.local" ]; then
    warn "~/.gitconfig.local not found — create it with your [user] name/email"
fi
if [ ! -f "$HOME/.ssh/config.local" ]; then
    warn "~/.ssh/config.local not found — create it with your Host entries"
fi

header "Post-install reminders"
warn "Grant Accessibility permissions in System Settings → Privacy & Security → Accessibility for:"
echo -e "    - Karabiner-Elements"
echo -e "    - Karabiner-EventViewer (if installed)"
echo -e "    - Hammerspoon"

echo -e "\n${BOLD}${GREEN}==> Done!${RESET} Open a new terminal tab to apply changes."
