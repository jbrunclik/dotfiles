#!/usr/bin/env bash
# PostToolUse hook (Edit|Write): validate the config file that was just edited,
# using the same checks as CI where there is one. Exit 2 feeds the error back
# to Claude; validators that aren't installed are skipped.
set -uo pipefail

file="$(jq -r '.tool_input.file_path // empty')"
[ -n "$file" ] || exit 0
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
case "$file" in "$repo"/*) ;; *) exit 0 ;; esac
rel="${file#"$repo"/}"
cd "$repo" || exit 0

have() { command -v "$1" >/dev/null 2>&1; }
fail() { echo "$rel: $1" >&2; echo "$2" >&2; exit 2; }

case "$rel" in
    install.sh|drift.sh|gh-new-repo|hyper-cheatsheet|wallpaper|lib/links.sh|bash_profile|bashrc|config/git/hooks/pre-commit|config/git/hooks/pre-push)
        # Checked together, as in CI, so `source lib/links.sh` resolves
        have shellcheck || exit 0
        out="$(shellcheck install.sh drift.sh gh-new-repo hyper-cheatsheet wallpaper lib/links.sh bash_profile bashrc config/git/hooks/pre-commit config/git/hooks/pre-push 2>&1)" \
            || fail "shellcheck failed" "$out" ;;
    *.sh)
        have shellcheck || exit 0
        out="$(shellcheck "$rel" 2>&1)" || fail "shellcheck failed" "$out" ;;
    config/karabiner/karabiner.json)
        out="$(jq empty "$rel" 2>&1)" || fail "invalid JSON" "$out"
        cli="/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli"
        if [ -x "$cli" ]; then
            tmp="$(mktemp)"
            jq '{title: "check", rules: .profiles[0].complex_modifications.rules}' "$rel" > "$tmp"
            out="$("$cli" --lint-complex-modifications "$tmp" 2>&1)"; rc=$?
            rm -f "$tmp"
            [ $rc -eq 0 ] || fail "Karabiner lint failed" "$out"
        fi ;;
    *.json)
        # VS Code settings are JSONC (comments), which jq rejects
        case "$rel" in config/vscode/*) exit 0 ;; esac
        out="$(jq empty "$rel" 2>&1)" || fail "invalid JSON" "$out" ;;
    config/nvim/*.lua)
        # Neovim runs LuaJIT, as in CI. Parse-only via loadfile: `luajit -b`
        # require()s jit.bcsave, and ./?.lua is on the search path.
        have luajit || exit 0
        out="$(LUA_FILE="$rel" luajit -e 'local ok, err = loadfile(os.getenv("LUA_FILE")) if not ok then io.stderr:write(err, "\n") os.exit(1) end' 2>&1)" \
            || fail "Lua syntax error" "$out" ;;
    *.lua)
        have luac || exit 0
        out="$(luac -p "$rel" 2>&1)" || fail "Lua syntax error" "$out" ;;
    config/ghostty/config)
        ghostty=/Applications/Ghostty.app/Contents/MacOS/ghostty
        [ -x "$ghostty" ] || exit 0
        out="$("$ghostty" +validate-config 2>&1)" || fail "Ghostty config invalid" "$out" ;;
esac
exit 0
