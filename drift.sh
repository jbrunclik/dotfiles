#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
DRIFTED=0

check() {
    local src="$1" dst="$2"
    if [ ! -e "$dst" ]; then
        echo "  MISSING  $dst"
        DRIFTED=1
    elif [ -L "$dst" ]; then
        local target
        target="$(readlink "$dst")"
        if [ "$target" != "$src" ]; then
            echo "  LINK     $dst -> $target (expected $src)"
            DRIFTED=1
        fi
    elif ! diff -q "$src" "$dst" > /dev/null 2>&1; then
        echo "  CHANGED  $dst"
        diff -u "$src" "$dst" 2>/dev/null | head -20 || true
        echo ""
        DRIFTED=1
    fi
}

echo "Checking for drift..."
echo ""

echo "Symlinks:"
check "$DOTFILES/bash_profile"                          "$HOME/.bash_profile"
check "$DOTFILES/inputrc"                               "$HOME/.inputrc"
check "$DOTFILES/gitconfig"                             "$HOME/.gitconfig"
check "$DOTFILES/ssh_config"                            "$HOME/.ssh/config"
check "$DOTFILES/config/ghostty/config"                 "$HOME/.config/ghostty/config"
check "$DOTFILES/config/nvim"                           "$HOME/.config/nvim"
check "$DOTFILES/config/starship.toml"                  "$HOME/.config/starship.toml"
check "$DOTFILES/config/bat/config"                     "$HOME/.config/bat/config"
check "$DOTFILES/config/mc/skins/catppuccin-mocha.ini"  "$HOME/.local/share/mc/skins/catppuccin-mocha.ini"
check "$DOTFILES/config/vscode/settings.json"           "$HOME/Library/Application Support/Code/User/settings.json"

# Check local-only files exist
echo ""
echo "Local files (not in repo):"
for f in "$HOME/.gitconfig.local" "$HOME/.ssh/config.local"; do
    if [ ! -f "$f" ]; then
        echo "  MISSING  $f"
        DRIFTED=1
    else
        echo "  OK       $f"
    fi
done

# Check Brewfile packages
echo ""
echo "Brewfile packages:"
MISSING_PKGS=""
while IFS= read -r line; do
    if [[ "$line" =~ ^brew\ \"(.+)\" ]]; then
        pkg="${BASH_REMATCH[1]}"
        if ! brew list "$pkg" &>/dev/null; then
            MISSING_PKGS="$MISSING_PKGS $pkg"
            DRIFTED=1
        fi
    elif [[ "$line" =~ ^cask\ \"(.+)\" ]]; then
        pkg="${BASH_REMATCH[1]}"
        if ! brew list --cask "$pkg" &>/dev/null; then
            MISSING_PKGS="$MISSING_PKGS $pkg"
            DRIFTED=1
        fi
    fi
done < "$DOTFILES/Brewfile"

if [ -n "$MISSING_PKGS" ]; then
    echo "  MISSING packages:$MISSING_PKGS"
else
    echo "  All packages installed."
fi

# Check VS Code extensions
echo ""
echo "VS Code extensions:"
if command -v code &>/dev/null; then
    INSTALLED_EXTS="$(code --list-extensions 2>/dev/null)"
    MISSING_EXTS=""
    while IFS= read -r ext; do
        if ! echo "$INSTALLED_EXTS" | grep -qFi "$ext"; then
            MISSING_EXTS="$MISSING_EXTS $ext"
            DRIFTED=1
        fi
    done < "$DOTFILES/config/vscode/extensions.txt"
    if [ -n "$MISSING_EXTS" ]; then
        echo "  MISSING extensions:$MISSING_EXTS"
    else
        echo "  All extensions installed."
    fi
else
    echo "  SKIPPED ('code' CLI not in PATH)"
fi

echo ""
if [ "$DRIFTED" -eq 0 ]; then
    echo "No drift detected. Everything matches."
else
    echo "Drift detected! Run ./install.sh to re-sync, or update the repo."
    exit 1
fi
