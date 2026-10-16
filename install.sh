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

# Fastest repeat the System Settings sliders allow (30 ms, 225 ms initial delay),
# and hold-to-repeat instead of the accent popup — Hyper+HJKL arrows and
# CapsLock tap-then-hold Backspace both rely on repeat. Takes effect after logout.
header "Setting key repeat"
defaults write -globalDomain KeyRepeat -int 2
defaults write -globalDomain InitialKeyRepeat -int 15
defaults write -globalDomain ApplePressAndHoldEnabled -bool false

# Touch ID for sudo. /etc/pam.d/sudo_local survives macOS updates (unlike
# /etc/pam.d/sudo) and ships as a template with the pam_tid line commented out.
header "Enabling Touch ID for sudo"
if grep -qs '^auth.*pam_tid.so' /etc/pam.d/sudo_local; then
    echo -e "  ${GREEN}✓${RESET} already enabled"
elif [ -e /etc/pam.d/sudo_local ]; then
    # Never overwrite an existing file: it may hold other local PAM config
    warn "/etc/pam.d/sudo_local exists without pam_tid — add 'auth sufficient pam_tid.so' to it by hand"
elif grep -qs '^#auth.*pam_tid.so' /etc/pam.d/sudo_local.template; then
    sed 's/^#auth/auth/' /etc/pam.d/sudo_local.template | sudo tee /etc/pam.d/sudo_local >/dev/null
    echo -e "  ${GREEN}✓${RESET} /etc/pam.d/sudo_local"
else
    warn "No sudo_local template with a pam_tid line (needs macOS 14+) — skipping"
fi

# Dock on the right and hidden: a bottom Dock pops up over Zoom's toolbar (and
# every app's bottom controls) on overshoot. A short delay stays, because
# right-tiled apps do have controls near the right edge (Slack's thread close
# button). Apps are launched by Hyper keys, so the Dock is mostly a
# running-apps indicator.
header "Setting Dock and Spaces"
defaults write com.apple.dock orientation -string right
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0.2
defaults write com.apple.dock autohide-time-modifier -float 0.15
defaults write com.apple.dock magnification -bool false
defaults write com.apple.dock minimize-to-application -bool true
# Keep Spaces in a fixed order instead of reordering by recent use
defaults write com.apple.dock mru-spaces -bool false
# Clicking the wallpaper no longer hides every window
defaults write com.apple.WindowManager EnableStandardClickToShowDesktop -bool false
killall Dock

# App preferences worth keeping — only the settings that were actually changed.
# Written while the apps aren't running yet on a fresh machine; on this one
# they're already set. (AlDente's plist also holds the license email, so never
# export the whole domain.)
header "Setting app preferences"
# AlDente: hold the battery at 80 % (macOS 26's native limit, whose floor is
# 80), sailing mode 5 %, discharge down to the limit, and heat protection —
# heat wears a battery faster than charge level, and this Mac lives plugged in
defaults write com.apphousekitchen.aldente-pro chargeVal -float 80
defaults write com.apphousekitchen.aldente-pro sailingMode -bool true
defaults write com.apphousekitchen.aldente-pro sailingLevel -float 5
defaults write com.apphousekitchen.aldente-pro automaticDischarge -bool true
defaults write com.apphousekitchen.aldente-pro useTahoeNativeLimit -bool true
defaults write com.apphousekitchen.aldente-pro heatProtectMode -bool true
defaults write com.apphousekitchen.aldente-pro showPercentage -bool true
# Scroll Reverser: reverse the mouse (KensingtonWorks), not the trackpad
defaults write com.pilotmoon.scroll-reverser InvertScrollingOn -bool true
defaults write com.pilotmoon.scroll-reverser ReverseTrackpad -bool false

# Picked up the next time Finder starts (logout, or `killall Finder`)
header "Showing all file extensions in Finder"
defaults write -globalDomain AppleShowAllExtensions -bool true

# Finder "open with" defaults. Each type that actually changes gets a macOS
# consent dialog (no API avoids it); already-correct types are skipped, so this
# only prompts on first run or after drift. See config/finder/default-apps.
header "Setting Finder default apps"
if command -v swiftc &>/dev/null; then
    # shellcheck disable=SC2119
    set_default_apps || warn "some default apps were not set — see above"
else
    warn "swiftc not found — skipping Finder default apps (install Xcode Command Line Tools)"
fi

header "Building bat theme cache"
bat cache --build

# Merges generic prefs into ~/.claude/settings.json (leaving Claude-Code-managed
# keys and secrets alone) and installs the generic plugin set. See config/claude/.
header "Configuring Claude Code"
bash "$DOTFILES/config/claude/bootstrap.sh"

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
warn "Install manually (no Homebrew cask):"
echo -e "    - KensingtonWorks — mouse/trackball driver, from kensington.com"
echo -e "    - Shokz Connect — headphone firmware and settings, from shokz.com"
warn "Open and configure manually:"
echo -e "    - Maccy — enable launch at login (hotkey: Cmd+Shift+C, the default)"
echo -e "    - Shottr — set screenshot hotkeys, launch at login"
warn "Install Chrome theme from Web Store:"
echo -e "    - Search 'Catppuccin Chrome Theme Mocha' or visit the Chrome Web Store"
warn "Set Slack theme:"
echo -e "    - Preferences → Themes → Create custom theme, paste:"
echo -e "    - #1E1E2E,#F8F8FA,#CBA6F7,#1E1E2E,#11111B,#CDD6F4,#CBA6F7,#EBA0AC,#1E1E2E,#CDD6F4"
warn "Set btop theme:"
echo -e "    - Launch btop → Esc → Options → set color theme to catppuccin_mocha"
warn "Enable background git maintenance (per machine, one-time):"
echo -e "    - Run 'git maintenance start' inside your large repos for near-instant fetch/status"

echo -e "\n${BOLD}${GREEN}==> Done!${RESET} Open a new terminal tab to apply changes."
