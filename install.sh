#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/links.sh
source "$DOTFILES/lib/links.sh"

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
brew bundle install --file="$DOTFILES/Brewfile"

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

for entry in "${LINKS[@]}"; do
    link "$DOTFILES/${entry%%|*}" "${entry#*|}"
done

# Only the directory needs locking down. Don't chmod ~/.ssh/config — it's a
# symlink, so chmod would follow it and change the mode of the file in the
# repo. ssh only rejects a config that is writable by group/other, and the
# repo's 644 already satisfies that.
chmod 700 "$HOME/.ssh"

# Hammerspoon doesn't follow symlinks for init.lua — use a loader file
mkdir -p "$HOME/.hammerspoon"
echo "dofile(\"$DOTFILES/config/hammerspoon/init.lua\")" > "$HOME/.hammerspoon/init.lua"
echo -e "  ${GREEN}✓${RESET} $HOME/.hammerspoon/init.lua -> dofile loader"

header "Setting macOS accent color (Catppuccin Mocha mauve #cba6f7)"
defaults write -globalDomain AppleAccentColor -int 5
defaults write -globalDomain AppleHighlightColor -string "0.796078 0.650980 0.968627 Purple"

header "Building bat theme cache"
bat cache --build

header "Installing VS Code extensions"
if command -v code &>/dev/null; then
    # `|| [ -n "$ext" ]` so a final line without a trailing newline still runs
    while IFS= read -r ext || [ -n "$ext" ]; do
        [[ -z "$ext" || "$ext" == \#* ]] && continue
        if code --install-extension "$ext" --force >/dev/null 2>&1; then
            echo -e "  ${GREEN}✓${RESET} $ext"
        else
            warn "failed to install extension: $ext"
        fi
    done < "$DOTFILES/config/vscode/extensions.txt"
else
    warn "'code' CLI not found — install VS Code and run 'Shell Command: Install code in PATH'"
fi

header "Checking required binaries"
for entry in "${REQUIRED_BINS[@]}"; do
    bin="${entry%%|*}"
    command -v "$bin" &>/dev/null || warn "$bin not on PATH — needed for ${entry#*|}"
done

header "Checking local config files"
for entry in \
    "$HOME/.gitconfig.local|your [user] name/email" \
    "$HOME/.ssh/config.local|your Host entries" \
    "$HOME/.bash_profile.local|machine-local env vars and secrets"
do
    path="${entry%%|*}"
    [ -f "$path" ] || warn "$path not found — create it with ${entry#*|}"
done

header "Post-install reminders"
warn "Grant Accessibility permissions in System Settings → Privacy & Security → Accessibility for:"
echo -e "    - Karabiner-Elements"
echo -e "    - Karabiner-EventViewer (if installed)"
echo -e "    - Hammerspoon"
warn "Open and configure manually:"
echo -e "    - Maccy — set clipboard hotkey (default: Cmd+Shift+V), launch at login"
echo -e "    - Shottr — set screenshot hotkeys, launch at login"
warn "Install Chrome theme from Web Store:"
echo -e "    - Search 'Catppuccin Chrome Theme Mocha' or visit the Chrome Web Store"
warn "Set Slack theme:"
echo -e "    - Preferences → Themes → Create custom theme, paste:"
echo -e "    - #1E1E2E,#F8F8FA,#CBA6F7,#1E1E2E,#11111B,#CDD6F4,#CBA6F7,#EBA0AC,#1E1E2E,#CDD6F4"
warn "Set btop theme:"
echo -e "    - Launch btop → Esc → Options → set color theme to catppuccin_mocha"

echo -e "\n${BOLD}${GREEN}==> Done!${RESET} Open a new terminal tab to apply changes."
