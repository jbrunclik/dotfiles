#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/links.sh
source "$DOTFILES/lib/links.sh"

# Homebrew prints "==> New Formulae/Casks" announcements on stderr during
# auto-update. Those would otherwise be mistaken for package-check output.
export HOMEBREW_NO_AUTO_UPDATE=1

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
    if [ ! -e "$dst" ] && [ ! -L "$dst" ]; then
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
for entry in "${LINKS[@]}"; do
    check "$DOTFILES/${entry%%|*}" "${entry#*|}"
done

echo ""
header "Local files (not in repo):"
for f in "${LOCAL_FILES[@]}"; do
    if [ ! -f "$f" ]; then
        echo -e "  ${RED}MISSING${RESET}  $f"
        DRIFTED=1
    else
        echo -e "  ${GREEN}OK${RESET}       $f"
    fi
done

# Check Touch ID for sudo (install.sh enables it)
echo ""
header "Touch ID for sudo:"
if grep -qs '^auth.*pam_tid.so' /etc/pam.d/sudo_local; then
    echo -e "  ${GREEN}OK${RESET}       /etc/pam.d/sudo_local"
else
    echo -e "  ${RED}MISSING${RESET}  /etc/pam.d/sudo_local (run install.sh)"
    DRIFTED=1
fi

# Check macOS settings (install.sh writes them; an OS update can reset them)
echo ""
header "macOS settings:"
BAD_DEFAULTS=0
for entry in "${DEFAULTS[@]}"; do
    IFS='|' read -r domain key type value <<< "$entry"
    if ! have="$(default_matches "$domain" "$key" "$type" "$value")"; then
        echo -e "  ${YELLOW}CHANGED${RESET}  $domain $key = $have (expected $value)"
        BAD_DEFAULTS=1
        DRIFTED=1
    fi
done
[ "$BAD_DEFAULTS" -eq 0 ] && echo -e "  ${GREEN}All ${#DEFAULTS[@]} settings match.${RESET}"

# Check Hammerspoon loader file
echo ""
header "Hammerspoon:"
HS_INIT="$HOME/.hammerspoon/init.lua"
if [ ! -f "$HS_INIT" ]; then
    echo -e "  ${RED}MISSING${RESET}  $HS_INIT"
    DRIFTED=1
elif grep -qF "dofile(\"$DOTFILES/config/hammerspoon/init.lua\")" "$HS_INIT" 2>/dev/null; then
    echo -e "  ${GREEN}OK${RESET}       $HS_INIT (dofile loader)"
else
    echo -e "  ${YELLOW}CHANGED${RESET}  $HS_INIT (not pointing to dotfiles)"
    DRIFTED=1
fi

# Check Brewfile packages.
#
# `brew bundle check` counts a package as unmet when it is merely OUTDATED, not
# only when it is absent — and this machine routinely carries dozens of outdated
# formulae, so it reported ~15 installed packages as "unmet". Only a genuinely
# missing package is drift; outdated is a soft note cleared by
# `brew bundle install`. So check installation directly against `brew list`
# (version-agnostic) and surface outdated separately without failing.
echo ""
header "Brewfile packages:"
# The Brewfile also loads the untracked ~/Brewfile.local (work tools etc.).
BREWFILES=("$DOTFILES/Brewfile")
[ -f "$HOME/Brewfile.local" ] && BREWFILES+=("$HOME/Brewfile.local")
# Tap-qualified names (org/tap/name) are compared by their last component,
# which is what `brew list` prints.
mapfile -t WANT_FORMULAE < <(grep -hE '^brew "' "${BREWFILES[@]}" | sed -E 's/^brew "([^"]+)".*/\1/; s|.*/||')
mapfile -t WANT_CASKS    < <(grep -hE '^cask "' "${BREWFILES[@]}" | sed -E 's/^cask "([^"]+)".*/\1/')
mapfile -t WANT_MAS      < <(grep -hE '^mas "' "${BREWFILES[@]}" | sed -E 's/^mas "([^"]+)", *id: *([0-9]+).*/\2 \1/')
INSTALLED_FORMULAE="$(brew list --formula -1 2>/dev/null)"
INSTALLED_CASKS="$(brew list --cask -1 2>/dev/null)"
OUTDATED_ALL="$(brew outdated --quiet 2>/dev/null)"

MISSING_PKGS=()
OUTDATED_PKGS=()
for f in "${WANT_FORMULAE[@]}"; do
    if ! grep -qxF "$f" <<< "$INSTALLED_FORMULAE"; then
        MISSING_PKGS+=("$f (formula)")
    elif grep -qxF "$f" <<< "$OUTDATED_ALL"; then
        OUTDATED_PKGS+=("$f")
    fi
done
for c in "${WANT_CASKS[@]}"; do
    if ! grep -qxF "$c" <<< "$INSTALLED_CASKS"; then
        MISSING_PKGS+=("$c (cask)")
    elif grep -qxF "$c" <<< "$OUTDATED_ALL"; then
        OUTDATED_PKGS+=("$c")
    fi
done
if [ "${#WANT_MAS[@]}" -gt 0 ]; then
    INSTALLED_MAS="$(mas list 2>/dev/null | awk '{print $1}')"
    for entry in "${WANT_MAS[@]}"; do
        grep -qxF "${entry%% *}" <<< "$INSTALLED_MAS" || MISSING_PKGS+=("${entry#* } (App Store)")
    done
fi

if [ "${#MISSING_PKGS[@]}" -gt 0 ]; then
    for p in "${MISSING_PKGS[@]}"; do
        echo -e "  ${RED}MISSING${RESET}  $p"
    done
    DRIFTED=1
else
    echo -e "  ${GREEN}All packages installed.${RESET}"
fi
if [ "${#OUTDATED_PKGS[@]}" -gt 0 ]; then
    # Informational only — outdated is not drift. Run 'brew bundle install'.
    echo -e "  ${YELLOW}OUTDATED${RESET} ${#OUTDATED_PKGS[@]} (update with 'brew bundle install'): ${OUTDATED_PKGS[*]}"
fi

# Check binaries the configs shell out to
echo ""
header "Required binaries:"
MISSING_BINS=0
for entry in "${REQUIRED_BINS[@]}"; do
    bin="${entry%%|*}"
    if ! command -v "$bin" &>/dev/null; then
        echo -e "  ${RED}MISSING${RESET}  $bin (${entry#*|})"
        MISSING_BINS=1
        DRIFTED=1
    fi
done
[ "$MISSING_BINS" -eq 0 ] && echo -e "  ${GREEN}All required binaries on PATH.${RESET}"

# mise runtimes: config/mise/config.toml is linked, but nothing installs what
# it asks for until `mise install` runs
echo ""
header "mise tools:"
if command -v mise &>/dev/null; then
    MISSING_MISE="$(mise ls --missing --global 2>/dev/null | awk '{print $1 " " $2}')"
    if [ -n "$MISSING_MISE" ]; then
        while IFS= read -r t; do echo -e "  ${RED}MISSING${RESET}  $t (run 'mise install')"; done <<< "$MISSING_MISE"
        DRIFTED=1
    else
        echo -e "  ${GREEN}All global tools installed.${RESET}"
    fi
else
    echo -e "  ${YELLOW}SKIPPED${RESET} ('mise' not in PATH)"
fi

# Claude Code settings: bootstrap.sh merges settings.base.json into the live
# settings.json, which Claude Code owns and rewrites — so check every value
# the base sets is still there
echo ""
header "Claude Code settings:"
CLAUDE_SETTINGS="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json"
if [ -f "$CLAUDE_SETTINGS" ]; then
    CHANGED_KEYS="$(jq -rn --slurpfile base "$DOTFILES/config/claude/settings.base.json" \
        --slurpfile live "$CLAUDE_SETTINGS" '
        $base[0] | paths(scalars) as $p
        | select(($live[0] | getpath($p)) != ($base[0] | getpath($p)))
        | "\($p | map(tostring) | join(".")) = \($live[0] | getpath($p) | tojson) (expected \($base[0] | getpath($p) | tojson))"
    ' 2>/dev/null)" || CHANGED_KEYS="could not parse $CLAUDE_SETTINGS"
    if [ -n "$CHANGED_KEYS" ]; then
        while IFS= read -r k; do echo -e "  ${YELLOW}CHANGED${RESET}  $k"; done <<< "$CHANGED_KEYS"
        echo -e "           run 'bash config/claude/bootstrap.sh'"
        DRIFTED=1
    else
        echo -e "  ${GREEN}OK${RESET}       every settings.base.json value present"
    fi
else
    echo -e "  ${RED}MISSING${RESET}  $CLAUDE_SETTINGS (run 'bash config/claude/bootstrap.sh')"
    DRIFTED=1
fi

# Check Neovim treesitter parsers actually got installed
echo ""
header "Neovim treesitter parsers:"
if command -v nvim &>/dev/null; then
    TS_COUNT="$(nvim --headless \
        "+lua local ok, ts = pcall(require, 'nvim-treesitter'); io.write(ok and #ts.get_installed() or -1)" \
        "+qa" 2>/dev/null || echo -1)"
    if [ "$TS_COUNT" -gt 0 ]; then
        echo -e "  ${GREEN}OK${RESET}       $TS_COUNT parsers installed"
    elif [ "$TS_COUNT" -eq 0 ]; then
        echo -e "  ${RED}MISSING${RESET}  no parsers installed — run ':TSInstall' or restart nvim"
        DRIFTED=1
    else
        echo -e "  ${YELLOW}SKIPPED${RESET} (nvim-treesitter not loaded yet)"
    fi
else
    echo -e "  ${YELLOW}SKIPPED${RESET} ('nvim' not in PATH)"
fi

# Check Finder default apps
echo ""
header "Finder default apps:"
if command -v swiftc &>/dev/null; then
    set_default_apps --check || DRIFTED=1
else
    echo -e "  ${YELLOW}SKIP${RESET}     swiftc not found"
fi

# URL router: with a work-domain list present, Hammerspoon must be the default
# browser, or links quietly stop being routed (an MDM can reset it)
echo ""
header "Default browser (URL router):"
if [ -f "$HOME/.config/url-router/work.local" ]; then
    handler="$(python3 -c '
import plistlib, os
p = os.path.expanduser("~/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist")
hs = [h.get("LSHandlerRoleAll", "") for h in plistlib.load(open(p, "rb")).get("LSHandlers", []) if h.get("LSHandlerURLScheme") == "https"]
print(hs[0] if hs else "none")' 2>/dev/null || echo unknown)"
    if [ "$handler" = "org.hammerspoon.hammerspoon" ]; then
        echo -e "  ${GREEN}OK${RESET}       https → Hammerspoon"
    else
        echo -e "  ${YELLOW}CHANGED${RESET}  https → $handler (expected Hammerspoon; run hs -c 'hs.urlevent.setDefaultHandler(\"http\")')"
        DRIFTED=1
    fi
else
    echo -e "  ${YELLOW}SKIP${RESET}     no ~/.config/url-router/work.local — every link goes to Dia"
fi

# Thaw menu bar layout (config/thaw/layout). On the MacBook's own display
# thaw-layout doesn't judge — that display has its own Thaw profile.
echo ""
header "Menu bar layout (Thaw):"
if pgrep -x Thaw > /dev/null && pgrep -x Hammerspoon > /dev/null; then
    if THAW_OUT="$("$DOTFILES/thaw-layout" 2>&1)"; then
        echo -e "  ${GREEN}OK${RESET}       $(head -1 <<< "$THAW_OUT")"
    else
        echo -e "  ${YELLOW}CHANGED${RESET}  run ./thaw-layout for details:"
        while IFS= read -r line; do echo "           $line"; done <<< "$THAW_OUT"
        DRIFTED=1
    fi
else
    echo -e "  ${YELLOW}SKIPPED${RESET} (Thaw or Hammerspoon not running)"
fi

# Check VS Code extensions
echo ""
header "VS Code extensions:"
if command -v code &>/dev/null; then
    INSTALLED_EXTS="$(code --list-extensions 2>/dev/null)"
    MISSING_EXTS=""
    while IFS= read -r ext || [ -n "$ext" ]; do
        [[ -z "$ext" || "$ext" == \#* ]] && continue
        # -x so a shorter id can't be satisfied by a longer installed one
        # (e.g. ms-python.python vs ms-python.vscode-python-envs)
        if ! echo "$INSTALLED_EXTS" | grep -qxFi "$ext"; then
            MISSING_EXTS="$MISSING_EXTS $ext"
            DRIFTED=1
        fi
    done < "$DOTFILES/config/vscode/extensions.txt"
    if [ -n "$MISSING_EXTS" ]; then
        echo -e "  ${RED}MISSING${RESET} extensions:$MISSING_EXTS"
    else
        echo -e "  ${GREEN}All extensions installed.${RESET}"
    fi
    # Extras: installed but neither listed nor pulled in by a listed one (an
    # extensionDependencies / extensionPack entry, followed recursively).
    # Extensions arrive by recommendation prompts too, so list or uninstall.
    EXPECTED_EXTS="$(cat "$HOME"/.vscode/extensions/*/package.json 2>/dev/null | jq -rn \
        --rawfile list "$DOTFILES/config/vscode/extensions.txt" '
        ([inputs | {key: ("\(.publisher).\(.name)" | ascii_downcase),
                    value: [(.extensionDependencies // [])[], (.extensionPack // [])[]] | map(ascii_downcase)}]
         | from_entries) as $deps
        | def closure: . as $s | ($s + [$s[] | $deps[.] // [] | .[]] | unique) as $n
                       | if $n == $s then $s else $n | closure end;
        $list | split("\n") | map(ascii_downcase | select(length > 0 and (startswith("#") | not)))
        | closure | .[]' 2>/dev/null)"
    EXTRA_EXTS=""
    while IFS= read -r ext; do
        [ -z "$ext" ] && continue
        grep -qxFi "$ext" <<< "$EXPECTED_EXTS" || EXTRA_EXTS="$EXTRA_EXTS $ext"
    done <<< "$INSTALLED_EXTS"
    if [ -n "$EXTRA_EXTS" ]; then
        echo -e "  ${YELLOW}EXTRA${RESET}   not in extensions.txt:$EXTRA_EXTS (list them or 'code --uninstall-extension')"
        DRIFTED=1
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
