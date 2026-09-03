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

LINKS=(
    "bash_profile|$HOME/.bash_profile"
    "inputrc|$HOME/.inputrc"
    "gitconfig|$HOME/.gitconfig"
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
    "config/btop/themes/catppuccin_mocha.theme|$HOME/.config/btop/themes/catppuccin_mocha.theme"
    "config/karabiner/karabiner.json|$HOME/.config/karabiner/karabiner.json"
    "gh-new-repo|$HOME/.local/bin/gh-new-repo"
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
    "fzf|shell fuzzy finder"
    "starship|prompt"
    "zoxide|cd replacement"
    "mise|runtime versions"
    "tree-sitter|compiling nvim-treesitter parsers"
    "prettier|conform.nvim formatter for ts/js/json/yaml/markdown"
    "eslint_d|nvim-lint linter for ts/js"
    "ruff|Python lint + format"
    "uv|Python packaging"
    "gitleaks|secret scanning in the global pre-commit hook"
    "git-lfs|git-lfs hooks in the global hooksPath; they exit 2 without it"
)

# Files that must exist locally but are deliberately not in the repo.
LOCAL_FILES=(
    "$HOME/.gitconfig.local"
    "$HOME/.ssh/config.local"
)

# Compiles config/finder/set-default-apps.swift into a temp dir and runs it
# against config/finder/default-apps. Pass --check to report drift only.
set_default_apps() {
    local bin
    bin="$(mktemp -d)/set-default-apps"
    swiftc -O -o "$bin" "$DOTFILES/config/finder/set-default-apps.swift" 2>/dev/null \
        || { echo "  failed to compile set-default-apps.swift" >&2; return 1; }
    "$bin" "$@" "$DOTFILES/config/finder/default-apps"
}
