# dotfiles

macOS development environment configuration. Catppuccin Mocha everywhere.

## What's included

| Component | Tool | Config |
|---|---|---|
| Terminal | [Ghostty](https://ghostty.org/) | `config/ghostty/config` |
| Shell | Bash + [Starship](https://starship.rs/) prompt | `bash_profile`, `inputrc`, `config/starship.toml` |
| Editor | [Neovim](https://neovim.io/) with LSP, Treesitter, Copilot | `config/nvim/` |
| IDE | [VS Code](https://code.visualstudio.com/) with Catppuccin, Ruff, Prettier | `config/vscode/` |
| Git | [delta](https://github.com/dandavison/delta) pager, [lazygit](https://github.com/jesseduffield/lazygit) TUI, [gh](https://cli.github.com/) CLI | `gitconfig` |
| Keyboard | [Karabiner-Elements](https://karabiner-elements.pqrs.org/) — CapsLock as Hyper/Escape | `config/karabiner/karabiner.json` |
| Window layouts | [Hammerspoon](https://www.hammerspoon.org/) — hotkey-triggered layouts | `config/hammerspoon/init.lua` |
| Clipboard | [Maccy](https://maccy.app/) — clipboard history | — |
| Screenshots | [Shottr](https://shottr.cc/) — capture, annotate, OCR | — |
| SSH | Shared defaults (agent, keepalive, compression) | `ssh_config` |
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
3. Installs VS Code extensions
4. Warns if local-only config files are missing

## Files not in this repo

These files contain personal information and must be created manually:

| File | Contents |
|---|---|
| `~/.gitconfig.local` | `[user]` name/email, `[filter "lfs"]` config |
| `~/.ssh/config.local` | Host entries (hostnames, usernames, keys) |
| `~/.ssh/id_ed25519` | SSH private key |
| `~/.ssh/id_ed25519.pub` | SSH public key |

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

Checks symlinks, local files, installed packages, and VS Code extensions.
Non-zero exit on drift.

## Guide

See [GUIDE.md](GUIDE.md) for a complete reference of shortcuts, workflows,
and a week-by-week learning path.
