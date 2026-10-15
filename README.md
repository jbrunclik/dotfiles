# dotfiles

macOS development environment configuration. Catppuccin Mocha everywhere.

## What's included

| Component | Tool | Config |
|---|---|---|
| Terminal | [Ghostty](https://ghostty.org/) | `config/ghostty/config` |
| Shell | Bash + [Starship](https://starship.rs/) prompt | `bash_profile`, `inputrc`, `config/starship.toml` |
| Editor | [Neovim](https://neovim.io/) with LSP, Treesitter, Copilot | `config/nvim/` |
| Claude Code | [ccstatusline](https://github.com/sirmalloc/ccstatusline) — Mocha powerline status line (matches Starship) | `config/ccstatusline/settings.json` |
| IDE | [VS Code](https://code.visualstudio.com/) with Catppuccin, Ruff, Prettier | `config/vscode/` |
| Default apps | Finder "open with" per file type — text/code → VS Code, HEIC/RAW → Preview, media → IINA, .rar/.7z → The Unarchiver | `config/finder/default-apps` |
| Git | [delta](https://github.com/dandavison/delta) pager, [lazygit](https://github.com/jesseduffield/lazygit) TUI, [gh](https://cli.github.com/) CLI | `gitconfig` |
| Keyboard | [Karabiner-Elements](https://karabiner-elements.pqrs.org/) — CapsLock as Hyper / Backspace, Hyper+HJKL arrows, Hyper+,/. Ghostty tabs | `config/karabiner/` |
| Window layouts | [Hammerspoon](https://www.hammerspoon.org/) — hotkey-triggered layouts, app focus, Zoom mute; reloads on save | `config/hammerspoon/init.lua` |
| Clipboard | [Maccy](https://maccy.app/) — clipboard history | — |
| Screenshots | [Shottr](https://shottr.cc/) — capture, annotate, OCR | — |
| SSH | Shared defaults (agent, keepalive, compression, connection reuse) | `ssh_config` |
| File manager | [Midnight Commander](https://midnight-commander.org/) | `config/mc/skins/catppuccin-mocha.ini` |
| Syntax highlighting | [bat](https://github.com/sharkdp/bat) | `config/bat/config` |
| Packages | [Homebrew](https://brew.sh/) | `Brewfile` |

### Modern CLI replacements

| Classic | Replacement |
|---|---|
| `cat` | `bat` |
| `ls` | `eza` |
| `find` | `fd` |
| `grep` | `ripgrep` (`rg`) |
| `du` | `dust` |
| `top` | `btop` |
| `diff` | `delta` |
| `cd` | `zoxide` (`z`) |
| `curl` | `httpie` (`http` / `https`) |

### Python toolchain

| Concern | Tool |
|---|---|
| Package/project management | `uv` |
| Linting + formatting | `ruff` (replaces black, isort, flake8) |
| Type checking (VS Code) | Pylance (built-in Pyright) |
| Type checking (Neovim) | basedpyright |

### Neovim plugins

LSP (basedpyright, ruff, ts_ls, yamlls, lua_ls), blink.cmp, nvim-treesitter,
fzf-lua, gitsigns, lualine, indent-blankline, which-key, conform.nvim,
nvim-lint, mini.surround, mini.pairs, copilot.vim.

Mason installs the LSP servers, but treesitter parsers are compiled by the
`tree-sitter` CLI and conform/nvim-lint shell out to `prettier` and `eslint_d` —
all three come from the `Brewfile`, and `drift.sh` verifies them.

### Font

[Maple Mono NF](https://github.com/subframe7536/maple-font) — rounded monospace with built-in Nerd Font support.

## Install

```bash
git clone git@github.com:jbrunclik/dotfiles.git ~/src/dotfiles
cd ~/src/dotfiles
./install.sh
```

The install script:
1. Installs Homebrew packages from `Brewfile`
2. Symlinks all config files (backs up existing files to `*.bak`)
3. Sets macOS defaults: accent color, key repeat, press-and-hold off, Finder
   file extensions (see [GUIDE.md](GUIDE.md#macos-settings))
4. Installs VS Code extensions
5. Warns if any required binary is missing from `PATH`
6. Warns if local-only config files are missing

`install.sh` and `drift.sh` share one symlink manifest (`lib/links.sh`), so the
two can't disagree about what "installed" means.

## Files not in this repo

These files contain personal information and must be created manually:

| File | Contents |
|---|---|
| `~/.bash_profile.local` | API tokens, machine-local env vars and `PATH` entries |
| `~/.gitconfig.local` | `[user]` name/email, `[filter "lfs"]` config |
| `~/.ssh/config.local` | Host entries (hostnames, usernames, keys) |
| `~/.ssh/id_ed25519` | SSH private key |
| `~/.ssh/id_ed25519.pub` | SSH public key |

**This repo is public — no secret belongs in a tracked file.** `bash_profile`
sources `~/.bash_profile.local` last, so anything machine-specific or sensitive
goes there:

```bash
export SOME_API_TOKEN="..."
```

### Example `~/.gitconfig.local`

```gitconfig
[user]
    name = Your Name
    email = you@example.com
```

### Example `~/.ssh/config.local`

```ssh-config
Host myserver
    HostName myserver.example.com
    User myuser
```

## Drift detection

Check if local config has diverged from the repo:

```bash
./drift.sh
```

Checks symlinks, local files, Brewfile packages, required binaries, Neovim
treesitter parsers, and VS Code extensions. Non-zero exit on drift.

## Working on this repo with Claude Code

`CLAUDE.md` holds the repo's conventions and tool gotchas. `.claude/settings.json`
adds a PostToolUse hook (`.claude/hooks/check-config.sh`) that validates every
edited file — shellcheck, JSON, Lua syntax, Karabiner lint, Ghostty config — so
mistakes surface right away instead of in CI. Personal overrides go in the
untracked `.claude/settings.local.json`.

## Guide

See [GUIDE.md](GUIDE.md) for a complete reference of shortcuts, workflows,
and a week-by-week learning path.
