# Terminal
cask "ghostty"

# Shell
brew "bash"
brew "bash-completion@2"
brew "fzf"
brew "starship"
brew "zoxide"
brew "mise"
# Shell-script linter. CI runs it on install.sh, drift.sh, gh-new-repo,
# lib/links.sh and the pre-commit hook — track it so the same lint is
# reproducible locally before pushing.
brew "shellcheck"

# Editor
brew "neovim"
# nvim-treesitter's main branch compiles parsers with the tree-sitter CLI
# rather than shipping prebuilt grammars — without it every :TSInstall fails
brew "tree-sitter-cli"

# Automation
cask "karabiner-elements"
cask "hammerspoon"
cask "maccy"

# macOS utilities
cask "alt-tab"
cask "aldente"
cask "scroll-reverser"

# Screenshots
cask "shottr"

# AI
# The desktop app. Self-updating, so Homebrew only bootstraps it.
cask "claude"
# @latest ships every Claude Code release; the plain `claude-code` cask is the
# slower stable channel. Both provide the same `claude` binary, so a machine
# still on the old one has to drop it first:
#   brew uninstall --cask claude-code
cask "claude-code@latest"

# Python
brew "uv"
brew "ruff"

# Formatters and linters that Neovim shells out to.
# conform.nvim and nvim-lint invoke these directly — Mason only manages LSP
# servers, so without them format-on-save silently no-ops and linting throws
# ENOENT on every TypeScript buffer.
brew "prettier"
brew "eslint_d"

# Modern CLI replacements
brew "bat"
brew "eza"
brew "fd"
brew "ripgrep"
brew "dust"
brew "btop"
brew "git-delta"

# Data + API
brew "jq"
brew "httpie"

# Network
brew "wget"
brew "mosh"
# Installs to /opt/homebrew/sbin (on PATH via brew shellenv); needs sudo to
# open the raw sockets it traces with.
brew "mtr"

# Git + GitHub
brew "gh"
# core.hooksPath (gitconfig) makes git ignore every repo's .git/hooks, so
# git-lfs's hooks live in config/git/hooks and run for EVERY repo. They
# abort with exit 2 when git-lfs is absent, which would brick git on a
# fresh machine — hence tracked here and in REQUIRED_BINS.
brew "git-lfs"
# Rewrites history across every commit — the cleanup half of the gitleaks
# guardrail, for when a secret gets past it into a published repo.
brew "git-filter-repo"

# Security
# Secret scanner invoked by the global pre-commit hook (core.hooksPath in
# gitconfig → config/git/hooks/pre-commit).
brew "gitleaks"
cask "1password"
# Lets ~/.bash_profile.local pull secrets at shell start with `op read`
# instead of storing them in plaintext.
cask "1password-cli"
brew "pwgen"

# Other essentials
brew "glow"
brew "lazygit"
brew "midnight-commander"

# Fonts
cask "font-maple-mono-nf"
cask "font-cascadia-code-nf"
