#!/usr/bin/env bash
set -euo pipefail
#
# Configures the portable, GENERIC Claude Code layer. Idempotent; safe to re-run.
# Called by install.sh, or run standalone: bash config/claude/bootstrap.sh
#
# What it does NOT touch: work-specific plugins/marketplaces, the API key, or any
# per-machine state Claude Code writes to settings.json / settings.local.json.
# Generic prefs from settings.base.json are deep-merged in (base wins on its keys);
# everything Claude Code owns is preserved.

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SETTINGS="$CLAUDE_DIR/settings.json"
BASE="$DOTFILES/config/claude/settings.base.json"
HOOK="$DOTFILES/config/claude/hooks/idle-notify.sh"

if ! command -v claude &>/dev/null; then
    echo "  claude not on PATH — skipping Claude Code bootstrap"
    exit 0
fi
if ! command -v jq &>/dev/null; then
    echo "  jq not on PATH — skipping settings merge"
    exit 0
fi

mkdir -p "$CLAUDE_DIR"

# 1. Merge generic prefs + the idle-notify hook (with this machine's absolute path)
#    into the live, Claude-Code-managed settings.json. Deep merge, base wins on its
#    keys; enabledPlugins / extraKnownMarketplaces / apiKeyHelper are left untouched.
hooks_json="$(jq -n --arg cmd "$HOOK" \
    '{hooks: {Notification: [{matcher: "idle_prompt", hooks: [{type: "command", command: $cmd}]}]}}')"
tmp="$(mktemp)"
if [ -f "$SETTINGS" ]; then
    jq -s '.[0] * .[1] * .[2]' "$SETTINGS" "$BASE" <(printf '%s' "$hooks_json") > "$tmp"
else
    jq -s '.[0] * .[1]' "$BASE" <(printf '%s' "$hooks_json") > "$tmp"
fi
mv "$tmp" "$SETTINGS"
echo "  ✓ merged generic prefs + idle-notify hook into $SETTINGS"

# 2. Register generic marketplaces (idempotent).
claude plugin marketplace add anthropics/claude-plugins-community >/dev/null 2>&1 \
    && echo "  ✓ marketplace: claude-community" \
    || echo "  … marketplace claude-community (already added)"

# 3. Install the GENERIC personal plugin set (no work plugins).
PLUGINS=(
    superpowers
    frontend-design
    context7
    commit-commands
    feature-dev
    claude-md-management
    clangd-lsp
    pyright-lsp
    typescript-lsp
    security-guidance
)
for p in "${PLUGINS[@]}"; do
    if claude plugin install "${p}@claude-plugins-official" >/dev/null 2>&1; then
        echo "  ✓ $p"
    else
        echo "  … $p (already installed or unavailable)"
    fi
done

echo "  Done. Restart Claude Code to load newly installed plugins."
