# shellcheck shell=bash
# These arrays are consumed by the scripts that source this file.
# shellcheck disable=SC2034
#
# Shared symlink manifest, sourced by install.sh and drift.sh.
#
# Keeping one list means install and drift can't disagree about what
# "installed" means. Format: "<path relative to repo root>|<destination>".
# Destinations may contain spaces, so the delimiter is '|' rather than
# whitespace.
#
# Not covered here (they need special handling in install.sh/drift.sh):
#   ~/.hammerspoon/init.lua — a dofile loader; Hammerspoon won't follow symlinks
#
# Karabiner is linked as a whole directory: it saves karabiner.json by writing
# a temp file and renaming it over the original, which replaces a file symlink.

LINKS=(
    "bash_profile|$HOME/.bash_profile"
    "bashrc|$HOME/.bashrc"
    "inputrc|$HOME/.inputrc"
    "gitconfig|$HOME/.gitconfig"
    "config/git/ignore|$HOME/.config/git/ignore"
    "ssh_config|$HOME/.ssh/config"
    "config/ghostty/config|$HOME/.config/ghostty/config"
    "config/nvim|$HOME/.config/nvim"
    "config/starship.toml|$HOME/.config/starship.toml"
    "config/mise/config.toml|$HOME/.config/mise/config.toml"
    "config/ccstatusline/settings.json|$HOME/.config/ccstatusline/settings.json"
    "config/claude/CLAUDE.md|$HOME/.claude/CLAUDE.md"
    "config/bat/config|$HOME/.config/bat/config"
    "config/bat/themes/CatppuccinMocha.tmTheme|$HOME/.config/bat/themes/CatppuccinMocha.tmTheme"
    "config/mc/skins/catppuccin-mocha.ini|$HOME/.local/share/mc/skins/catppuccin-mocha.ini"
    "config/vscode/settings.json|$HOME/Library/Application Support/Code/User/settings.json"
    "config/lazygit/config.yml|$HOME/Library/Application Support/lazygit/config.yml"
    # Only config.yml: hosts.yml next to it holds the auth token
    "config/gh/config.yml|$HOME/.config/gh/config.yml"
    # Not common.conf: gpg writes use-keyboxd there itself on first run
    "config/gnupg/gpg.conf|$HOME/.gnupg/gpg.conf"
    "config/gnupg/gpg-agent.conf|$HOME/.gnupg/gpg-agent.conf"
    "config/btop/themes/catppuccin_mocha.theme|$HOME/.config/btop/themes/catppuccin_mocha.theme"
    "config/karabiner|$HOME/.config/karabiner"
    "config/borders/bordersrc|$HOME/.config/borders/bordersrc"
    "gh-new-repo|$HOME/.local/bin/gh-new-repo"
    "hyper-cheatsheet|$HOME/.local/bin/hyper-cheatsheet"
    "keyboardio-backup|$HOME/.local/bin/keyboardio-backup"
    "keyboardio-layers|$HOME/.local/bin/keyboardio-layers"
    "thaw-layout|$HOME/.local/bin/thaw-layout"
    "wallpaper|$HOME/.local/bin/wallpaper"
    "dotfiles-update|$HOME/.local/bin/dotfiles-update"
    "config/launchd/dotfiles.brew-autoupdate.plist|$HOME/Library/LaunchAgents/dotfiles.brew-autoupdate.plist"
)

# Binaries the configs reference but that nothing else verifies. Neovim's
# conform.nvim and nvim-lint shell out to these; when they're absent,
# format-on-save silently no-ops and linting throws ENOENT on every buffer.
# Mason installs LSP servers only, so these have to come from Homebrew.
REQUIRED_BINS=(
    "bat|bat theme + cat alias"
    "eza|ls aliases"
    "fd|find alias"
    "rg|ripgrep"
    "dust|du alias"
    "btop|top alias"
    "delta|git pager"
    "difft|git difftool (difftastic)"
    "fzf|shell fuzzy finder"
    "starship|prompt"
    "zoxide|cd replacement"
    "mise|runtime versions"
    "tree-sitter|compiling nvim-treesitter parsers"
    "prettier|conform.nvim formatter for ts/js/json/yaml/markdown"
    "eslint_d|nvim-lint linter for ts/js"
    "shfmt|conform.nvim formatter for shell scripts"
    "pyright-langserver|Claude Code's pyright-lsp plugin"
    "typescript-language-server|Claude Code's typescript-lsp plugin"
    "lua-language-server|Claude Code's lua-lsp plugin"
    "ruff|Python lint + format"
    "uv|Python packaging"
    "gitleaks|secret scanning in the global pre-commit hook"
    "git-lfs|git-lfs hooks in the global hooksPath; they exit 2 without it"
    "gm|GraphicsMagick, pinned by the gm alias in bash_profile"
    "pinentry-mac|gpg-agent's passphrase/PIN dialog (pinentry-program)"
)

# Files that must exist locally but are deliberately not in the repo.
LOCAL_FILES=(
    "$HOME/.gitconfig.local"
    "$HOME/.ssh/config.local"
)

# macOS settings: install.sh writes them, drift.sh checks them (an OS update
# can reset any of them silently). Format: "<domain>|<key>|<type>|<value>",
# type as for `defaults write` without the dash (int, float, bool, string),
# or `shortcut`: a ShortcutRecorder dict (archived SRShortcut + its display
# string) given as a plist fragment, checked by that display string.
# Most take effect at next logout or app launch; install.sh restarts the Dock.
DEFAULTS=(
    # Accent and highlight color: Catppuccin Mocha mauve #cba6f7
    "NSGlobalDomain|AppleAccentColor|int|5"
    "NSGlobalDomain|AppleHighlightColor|string|0.796078 0.650980 0.968627 Purple"
    # Dark mode, dark-style app icons (macOS 26), and windows tinted by the
    # wallpaper — with the generated blue-teal wallpaper that gives Finder and
    # System Settings a faint blue cast, closer to Catppuccin's base than grey
    "NSGlobalDomain|AppleInterfaceStyle|string|Dark"
    "NSGlobalDomain|AppleIconAppearanceTheme|string|RegularDark"
    "NSGlobalDomain|AppleReduceDesktopTinting|bool|false"
    # Fastest repeat the System Settings sliders allow (30 ms, 225 ms initial
    # delay), and hold-to-repeat instead of the accent popup — Hyper+HJKL
    # arrows and CapsLock tap-then-hold Backspace both rely on repeat
    "NSGlobalDomain|KeyRepeat|int|2"
    "NSGlobalDomain|InitialKeyRepeat|int|15"
    "NSGlobalDomain|ApplePressAndHoldEnabled|bool|false"
    # Picked up the next time Finder starts
    "NSGlobalDomain|AppleShowAllExtensions|bool|true"
    # Dock on the right and hidden: a bottom Dock pops up over Zoom's toolbar
    # (and every app's bottom controls) on overshoot. A short delay stays,
    # because right-tiled apps do have controls near the right edge (Slack's
    # thread close button). Apps are launched by Hyper keys, so the Dock is
    # mostly a running-apps indicator.
    "com.apple.dock|orientation|string|right"
    "com.apple.dock|autohide|bool|true"
    "com.apple.dock|autohide-delay|float|0.2"
    "com.apple.dock|autohide-time-modifier|float|0.15"
    "com.apple.dock|magnification|bool|false"
    "com.apple.dock|minimize-to-application|bool|true"
    # Keep Spaces in a fixed order instead of reordering by recent use
    "com.apple.dock|mru-spaces|bool|false"
    # Clicking the wallpaper no longer hides every window
    "com.apple.WindowManager|EnableStandardClickToShowDesktop|bool|false"
    # App preferences worth keeping — only the settings that were actually
    # changed. (AlDente's plist also holds the license email, so never export
    # the whole domain.) AlDente: hold the battery at 80 % (macOS 26's native
    # limit, whose floor is 80), sailing mode 5 %, discharge down to the
    # limit, and heat protection — heat wears a battery faster than charge
    # level, and this Mac lives plugged in
    "com.apphousekitchen.aldente-pro|chargeVal|float|80"
    "com.apphousekitchen.aldente-pro|sailingMode|bool|true"
    "com.apphousekitchen.aldente-pro|sailingLevel|float|5"
    "com.apphousekitchen.aldente-pro|automaticDischarge|bool|true"
    "com.apphousekitchen.aldente-pro|useTahoeNativeLimit|bool|true"
    "com.apphousekitchen.aldente-pro|heatProtectMode|bool|true"
    "com.apphousekitchen.aldente-pro|showPercentage|bool|true"
    # Scroll Reverser: reverse the mouse (KensingtonWorks), not the trackpad
    "com.pilotmoon.scroll-reverser|InvertScrollingOn|bool|true"
    "com.pilotmoon.scroll-reverser|ReverseTrackpad|bool|false"
    # AltTab takes over macOS's switchers: hold ⌘ + Tab for every window
    # (shortcut 1), ⌘ + ` for the front app's windows (shortcut 2 — AltTab
    # Pro). Write these with AltTab quit: it keeps its settings in memory.
    # Single-quoted: the ` in the second one would start a command substitution.
    'com.lwouis.alt-tab-macos|holdShortcut|shortcut|<dict><key>secureData</key><data>YnBsaXN0MDDUAQIDBAUGHB9ZJGFyY2hpdmVyWCRvYmplY3RzVCR0b3BYJHZlcnNpb25fEA9OU0tleWVkQXJjaGl2ZXKlBwgUFRZVJG51bGzWCQoLDA0ODxAQERITViRjbGFzc1pjaGFyYWN0ZXJzXxAbY2hhcmFjdGVyc0lnbm9yaW5nTW9kaWZpZXJzV2tleUNvZGVdbW9kaWZpZXJGbGFnc1d2ZXJzaW9ugASAAIACgAOAABH//xIAEAAA0hcYGRpYJGNsYXNzZXNaJGNsYXNzbmFtZaIaG1pTUlNob3J0Y3V0WE5TT2JqZWN00R0eVHJvb3SAARIAAYagCBEbJCkyREpQXWRvjZWjq62vsbO1uL3Cy9bZ5O3w9fcAAAAAAAABAQAAAAAAAAAgAAAAAAAAAAAAAAAAAAAA/A==</data><key>string</key><string>⌘</string></dict>'
    'com.lwouis.alt-tab-macos|holdShortcut2|shortcut|<dict><key>secureData</key><data>YnBsaXN0MDDUAQIDBAUGBwpYJHZlcnNpb25ZJGFyY2hpdmVyVCR0b3BYJG9iamVjdHMSAAGGoF8QD05TS2V5ZWRBcmNoaXZlctEICVRyb290gAGlCwwZGhtVJG51bGzWDQ4PEBESExQVFBcUXW1vZGlmaWVyRmxhZ3NfEBtjaGFyYWN0ZXJzSWdub3JpbmdNb2RpZmllcnNWJGNsYXNzWmNoYXJhY3RlcnNXa2V5Q29kZVd2ZXJzaW9ugAOAAIAEgACAAoAAEf//EgAQAADSHB0eH1okY2xhc3NuYW1lWCRjbGFzc2VzWlNSU2hvcnRjdXSiHiBYTlNPYmplY3QIERokKTI3SUxRU1lfbHqYn6qyury+wMLExsnO097n8vUAAAAAAAABAQAAAAAAAAAhAAAAAAAAAAAAAAAAAAAA/g==</data><key>string</key><string>⌘</string></dict>'
    'com.lwouis.alt-tab-macos|nextWindowShortcut2|shortcut|<dict><key>secureData</key><data>YnBsaXN0MDDUAQIDBAUGHiFZJGFyY2hpdmVyWCRvYmplY3RzVCR0b3BYJHZlcnNpb25fEA9OU0tleWVkQXJjaGl2ZXKmBwgVFhcdVSRudWxs1gkKCwwNDg8QERITFFYkY2xhc3NaY2hhcmFjdGVyc18QG2NoYXJhY3RlcnNJZ25vcmluZ01vZGlmaWVyc1drZXlDb2RlXW1vZGlmaWVyRmxhZ3NXdmVyc2lvboAEgAWABYACgAOAABAyEADSGBkaG1gkY2xhc3Nlc1okY2xhc3NuYW1lohscWlNSU2hvcnRjdXRYTlNPYmplY3RRYNEfIFRyb290gAESAAGGoAgRGyQpMkRLUV5lcI6WpKyusLK0tri6vMHK1djj7O7x9vgAAAAAAAABAQAAAAAAAAAiAAAAAAAAAAAAAAAAAAAA/Q==</data><key>string</key><string>`</string></dict>'
)

# True when a DEFAULTS entry's domain/key holds its value. `defaults read`
# prints bools as 1/0 and floats in its own format, so those are normalized
# before comparing; prints the current value (or "unset") on stdout.
default_matches() {
    local domain="$1" key="$2" type="$3" want="$4" have
    have="$(defaults read "$domain" "$key" 2>/dev/null)" || { echo unset; return 1; }
    if [ "$type" = shortcut ]; then
        have="$(defaults export "$domain" - | plutil -extract "$key.string" raw -o - - 2>/dev/null)"
        want="$(sed -E 's|.*<key>string</key><string>([^<]*)</string>.*|\1|' <<< "$want")"
    fi
    echo "$have"
    case "$type" in
        bool)  [ "$have" = "$([ "$want" = true ] && echo 1 || echo 0)" ] ;;
        float) awk -v a="$have" -v b="$want" 'BEGIN { exit !(a + 0 == b + 0) }' ;;
        *)     [ "$have" = "$want" ] ;;
    esac
}

# Links src to dst, moving a real file at dst aside first. install.sh links
# LINKS with it; CI runs it into a temp $HOME.
link() {
    local src="$1" dst="$2"
    mkdir -p "$(dirname "$dst")"
    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
        # Never overwrite an earlier backup: the first .bak is the original
        local bak="${dst}.bak"
        [ -e "$bak" ] && bak="${dst}.bak.$(date +%Y%m%d-%H%M%S)"
        echo -e "  ${YELLOW:-}Backing up${RESET:-} $dst -> $bak"
        mv "$dst" "$bak"
    fi
    ln -sfn "$src" "$dst"
    echo -e "  ${GREEN:-}✓${RESET:-} $dst -> $src"
}

# Compiles config/finder/set-default-apps.swift into a temp dir and runs it
# against config/finder/default-apps. Pass --check to report drift only.
set_default_apps() {
    local bin
    bin="$(mktemp -d)/set-default-apps"
    swiftc -O -o "$bin" "$DOTFILES/config/finder/set-default-apps.swift" 2>/dev/null \
        || { echo "  failed to compile set-default-apps.swift" >&2; return 1; }
    "$bin" "$@" "$DOTFILES/config/finder/default-apps"
}
