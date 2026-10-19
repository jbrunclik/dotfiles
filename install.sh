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

# A fresh Mac: the Command Line Tools bring git, swiftc and the compilers
# Homebrew needs. The installer is a GUI dialog, so start it and stop here.
if ! xcode-select -p &>/dev/null; then
    xcode-select --install 2>/dev/null || true
    err "Xcode Command Line Tools are needed — finish the installer that just opened, then rerun ./install.sh"
    exit 1
fi

find_brew() {
    command -v brew &>/dev/null && return
    for prefix in /opt/homebrew /usr/local; do
        [ -x "$prefix/bin/brew" ] && eval "$("$prefix/bin/brew" shellenv)" && return
    done
    return 1
}
# Homebrew's signed release .pkg rather than its curl | bash script from a
# moving branch: it only runs if Apple notarized it and it's signed by
# Homebrew's Developer ID team. A new signer stops the install with a
# message rather than running something unexpected.
HOMEBREW_TEAM_ID=927JGANW46
if ! find_brew; then
    header "Installing Homebrew (signed .pkg from its latest GitHub release; asks for your password)"
    pkg="$(mktemp -d)/Homebrew.pkg"
    curl -fsSL -o "$pkg" https://github.com/Homebrew/brew/releases/latest/download/Homebrew.pkg
    sig="$(pkgutil --check-signature "$pkg" 2>&1 || true)"
    if ! grep -q "Notarization: trusted" <<< "$sig" || ! grep -q "($HOMEBREW_TEAM_ID)" <<< "$sig"; then
        err "Homebrew.pkg isn't notarized and signed by team $HOMEBREW_TEAM_ID — not installing it:"
        echo "$sig"
        exit 1
    fi
    sudo installer -pkg "$pkg" -target /
    find_brew || { err "Homebrew installed but brew isn't in /opt/homebrew or /usr/local"; exit 1; }
fi

header "Installing Homebrew packages"
# Don't let one failed entry abort the whole install (set -e): the mas
# lines fail until you're signed in to the App Store, and a cask can fail on
# a flaky download. drift.sh lists whatever is still missing afterwards.
brew bundle install --file="$DOTFILES/Brewfile" \
    || warn "some Brewfile entries failed (see above) — continuing; re-run after fixing"

header "Linking config files"

link() {
    local src="$1" dst="$2"
    mkdir -p "$(dirname "$dst")"
    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
        # Never overwrite an earlier backup: the first .bak is the original
        local bak="${dst}.bak"
        [ -e "$bak" ] && bak="${dst}.bak.$(date +%Y%m%d-%H%M%S)"
        echo -e "  ${YELLOW}Backing up${RESET} $dst -> $bak"
        mv "$dst" "$bak"
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

header "Setting macOS defaults (lib/links.sh)"
for entry in "${DEFAULTS[@]}"; do
    IFS='|' read -r domain key type value <<< "$entry"
    defaults write "$domain" "$key" "-$type" "$value"
done
echo -e "  ${GREEN}✓${RESET} ${#DEFAULTS[@]} settings"
killall Dock 2>/dev/null || true  # no Dock running, e.g. over SSH

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

# Guarded: under set -e, a bat that failed to install would abort everything after
header "Building bat theme cache"
if command -v bat &>/dev/null; then
    bat cache --build || warn "bat cache --build failed — the Catppuccin theme won't load"
else
    warn "bat not installed — skipping its theme cache"
fi

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
    "$HOME/.gitconfig.local|your [user] name/email and signingkey (the .pub path)" \
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
echo -e "    - Thaw (also Screen Recording — it reads the menu bar icons)"
warn "Install manually (no Homebrew cask):"
echo -e "    - KensingtonWorks — mouse/trackball driver, from kensington.com"
echo -e "    - Shokz Connect — headphone firmware and settings, from shokz.com"
warn "Open and configure manually:"
echo -e "    - Maccy — enable launch at login (hotkey: Cmd+Shift+C, the default)"
echo -e "    - Shottr — set screenshot hotkeys, launch at login"
echo -e "    - Thaw — launch at login, then sort the menu bar icons into its sections"
warn "URL router (links: work → Chrome, rest → Dia):"
echo -e "    - List work domains in ~/.config/url-router/work.local (see GUIDE.md)"
echo -e "    - Make Hammerspoon the default browser: hs -c 'hs.urlevent.setDefaultHandler(\"http\")', then confirm"
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
