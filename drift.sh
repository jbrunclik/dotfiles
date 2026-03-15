#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
DRIFTED=0

if [[ -t 1 ]]; then
    RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[0;33m'
    BLUE='\033[0;34m' BOLD='\033[1m' RESET='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' BOLD='' RESET=''
fi

header() { echo -e "${BOLD}${BLUE}$1${RESET}"; }

check() {
    local src="$1" dst="$2"
    if [ ! -e "$dst" ]; then
        echo -e "  ${RED}MISSING${RESET}  $dst"
        DRIFTED=1
    elif [ -L "$dst" ]; then
        local target
        target="$(readlink "$dst")"
        if [ "$target" != "$src" ]; then
            echo -e "  ${YELLOW}LINK${RESET}     $dst -> $target (expected $src)"
            DRIFTED=1
        else
            echo -e "  ${GREEN}OK${RESET}       $dst"
        fi
    elif ! diff -q "$src" "$dst" > /dev/null 2>&1; then
        echo -e "  ${YELLOW}CHANGED${RESET}  $dst"
        diff -u "$src" "$dst" 2>/dev/null | head -20 || true
        echo ""
        DRIFTED=1
    else
        echo -e "  ${GREEN}OK${RESET}       $dst"
    fi
}

echo -e "${BOLD}Checking for drift...${RESET}"
echo ""

header "Symlinks:"
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
check "$DOTFILES/config/karabiner/karabiner.json"       "$HOME/.config/karabiner/karabiner.json"
check "$DOTFILES/config/bat/themes/CatppuccinMocha.tmTheme" "$HOME/.config/bat/themes/CatppuccinMocha.tmTheme"

# Check local-only files exist
echo ""
header "Local files (not in repo):"
for f in "$HOME/.gitconfig.local" "$HOME/.ssh/config.local"; do
    if [ ! -f "$f" ]; then
        echo -e "  ${RED}MISSING${RESET}  $f"
        DRIFTED=1
    else
        echo -e "  ${GREEN}OK${RESET}       $f"
    fi
done

# Check Hammerspoon loader file
echo ""
header "Hammerspoon:"
HS_INIT="$HOME/.hammerspoon/init.lua"
if [ ! -f "$HS_INIT" ]; then
    echo -e "  ${RED}MISSING${RESET}  $HS_INIT"
    DRIFTED=1
elif grep -q "dofile.*$DOTFILES/config/hammerspoon/init.lua" "$HS_INIT" 2>/dev/null; then
    echo -e "  ${GREEN}OK${RESET}       $HS_INIT (dofile loader)"
else
    echo -e "  ${YELLOW}CHANGED${RESET}  $HS_INIT (not pointing to dotfiles)"
    DRIFTED=1
fi

# Check Brewfile packages (single brew command instead of per-package)
echo ""
header "Brewfile packages:"
BUNDLE_CHECK="$(brew bundle check --file="$DOTFILES/Brewfile" 2>&1)" && {
    echo -e "  ${GREEN}All packages installed.${RESET}"
} || {
    echo "$BUNDLE_CHECK" | grep -v "^$" | while IFS= read -r line; do
        echo -e "  ${RED}MISSING${RESET}  $line"
    done
    DRIFTED=1
}

# Check VS Code extensions
echo ""
header "VS Code extensions:"
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
        echo -e "  ${RED}MISSING${RESET} extensions:$MISSING_EXTS"
    else
        echo -e "  ${GREEN}All extensions installed.${RESET}"
    fi
else
    echo -e "  ${YELLOW}SKIPPED${RESET} ('code' CLI not in PATH)"
fi

echo ""
if [ "$DRIFTED" -eq 0 ]; then
    echo -e "${BOLD}${GREEN}No drift detected. Everything matches.${RESET}"
else
    echo -e "${BOLD}${RED}Drift detected!${RESET} Run ${BOLD}./install.sh${RESET} to re-sync, or update the repo."
    exit 1
fi
