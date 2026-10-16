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
# Default app for text and source files (config/finder/default-apps), and
# install.sh installs its extensions
cask "visual-studio-code"
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
# Archive Utility cannot open .rar or .7z
cask "the-unarchiver"
# Menubar toggle that keeps the Mac awake (instead of a `caffeinate -d` tab)
cask "keepingyouawake"
# Menu bar manager: hides icons behind a divider. Free, open-source fork of
# the abandoned Ice; replaces Bartender
cask "thaw"
# Native mpv-based player; QuickTime cannot open .mkv/.webm/.ogg
cask "iina"

# Screenshots
cask "shottr"

# Apps
# Hyper+2 and the Hyper+Z/V layouts
cask "thebrowsercompany-dia"
cask "signal"
cask "tailscale-app"
# Keyboardio Model 100 configurator (its Hyper key is set in firmware)
cask "chrysalis"
cask "insta360-link-controller"

# App Store (needs signing in to the App Store app first)
brew "mas"
mas "WhatsApp", id: 310633997

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
brew "htop"
brew "git-delta"
# `tldr <cmd>`: the few invocations you actually need, not the man page
brew "tlrc"
# batman, batgrep, batdiff — bat-powered man pages, grep and diff
brew "bat-extras"

# Data + API
brew "jq"
brew "httpie"

# Network
brew "wget"
brew "mosh"
# Installs to /opt/homebrew/sbin (on PATH via brew shellenv); needs sudo to
# open the raw sockets it traces with.
brew "mtr"
brew "nmap"

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
# YubiKey CLI, and the GPG passphrase prompt for keys on it
brew "ykman"
brew "pinentry-mac"

# Other essentials
brew "glow"
# GraphicsMagick; bash_profile pins the `gm` alias to it
brew "graphicsmagick"
brew "lazygit"
brew "midnight-commander"
# 7z/.rar from the command line (The Unarchiver covers Finder)
brew "sevenzip"
brew "yt-dlp"
# Per-project command runner (justfile)
brew "just"

# Fonts
cask "font-maple-mono-nf"
cask "font-cascadia-code-nf"

# Machine-local additions — work tools, this-machine-only apps. Untracked;
# drift.sh checks it too. A Brewfile is Ruby, so this just evaluates the file.
# Apps an MDM installs (root-owned) belong in neither file: Homebrew can't
# adopt them, and two updaters would fight over them.
local_brewfile = File.expand_path("~/Brewfile.local")
instance_eval(File.read(local_brewfile), local_brewfile) if File.exist?(local_brewfile)
