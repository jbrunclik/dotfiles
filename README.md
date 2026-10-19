# dotfiles

[![CI](https://github.com/jbrunclik/dotfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/jbrunclik/dotfiles/actions/workflows/ci.yml)

A keyboard-first macOS setup, built around one **Hyper** key that works the
same on a MacBook and a Keyboardio Model 100. Catppuccin Mocha everywhere.

<img src="docs/model100.jpg" alt="Keyboardio Model 100 with the base layer's dim mauve-to-green gradient; Prog, Any and the butterfly key lit in their own colors" width="720">

## Highlights

- **One Hyper key, two keyboards.** Caps Lock on the MacBook, the thumb key
  on the Model 100 — Cmd+Option+Ctrl+Shift, a modifier no app uses. Shortcuts
  are bound to physical keys, so they stay put when switching to the Czech
  (QWERTZ) layout.
- **Windows and apps on one hand.** Hyper+Z/X/C/V tile a pair of apps side by
  side (press again to swap focus), Hyper+1–6 jump to an app — press again
  to put it beside the window you came from — Hyper+Space then one letter
  reaches the rest (W WhatsApp, C Claude…; Shift+letter for "beside"),
  Hyper+A/S/D tile or maximize. Messages pops over the current layout and hides again
  (Hyper+T); Zoom mutes from any app (Hyper+M, or one key on the Model 100),
  and Hyper+Return joins the meeting about to begin.
- **A nav layer under the right hand.** Hyper+H/J/K/L are arrows; U/I page,
  O/P line start/end, B/W word jumps — in every app, terminal included.
- **It documents itself.** Hold Hyper alone for an on-screen cheatsheet; hold
  it on the Model 100 and the bound keys light up by what they do; run
  `hyper-cheatsheet` for a printable PDF. All three are generated from the
  config, so they can't drift from it.
- **Keyboard firmware as code.** The Model 100's keymap and colors are backed
  up into the repo and its lit Hyper layer is generated from the dotfiles.
- **Kept honest.** `drift.sh` checks the machine against the repo, CI lints
  every push, global pre-commit and pre-push hooks scan for secrets, and a Claude Code
  hook validates every config file as it's edited.

| On screen: hold Hyper | On the desk: `hyper-cheatsheet` |
|---|---|
| <img src="docs/hyper-cheatsheet-overlay.png" alt="On-screen Hyper cheatsheet listing every binding by section" width="520"> | <img src="docs/hyper-cheatsheet-print.png" alt="Printable A4 cheatsheet, Hyper page" width="400"> |

See **[GUIDE.md](GUIDE.md)** for every shortcut, the reasoning behind it, and
what to watch out for.

## What's included

**Terminal and shell**

| Component | Tool | Config |
|---|---|---|
| Terminal | [Ghostty](https://ghostty.org/) — tabs on Hyper+,/., `sudo` keeps its terminfo | `config/ghostty/config` |
| Shell | Bash + [Starship](https://starship.rs/), [fzf](https://github.com/junegunn/fzf) on `fd` with previews, [zoxide](https://github.com/ajeetdsouza/zoxide) | `bash_profile`, `inputrc`, `config/starship.toml` |
| Modern CLI | `bat`, `eza`, `fd`, `ripgrep`, `sd`, `dust`, `btop`, `delta`, `difftastic`, `jless`, `tldr`, `bat-extras`, `just`, `hyperfine`, `tokei` | `Brewfile`, `config/bat/` |
| Runtimes | [mise](https://mise.jdx.dev/) for Node, Go and Java; `uv` and `ruff` for Python | `config/mise/config.toml` |
| SSH | Agent, keepalive, one reused connection per host | `ssh_config` |

**Keyboard and windows**

| Component | Tool | Config |
|---|---|---|
| Hyper key, nav layer | [Karabiner-Elements](https://karabiner-elements.pqrs.org/) — Caps Lock is Hyper when held, Backspace when tapped | `config/karabiner/` |
| Keyboardio Model 100 | Firmware keymap with a lit Hyper layer — `keyboardio-layers`, `keyboardio-backup` | `config/keyboardio/model100.json` |
| Windows, apps, cheatsheet | [Hammerspoon](https://www.hammerspoon.org/) — layouts, app focus, Messages, Zoom mute and join, a link router (work → Chrome, rest → Dia); reloads on save | `config/hammerspoon/` |

**Editors and Git**

| Component | Tool | Config |
|---|---|---|
| IDE | [VS Code](https://code.visualstudio.com/) with Catppuccin, Ruff, Prettier | `config/vscode/` |
| Editor | [Neovim](https://neovim.io/) with LSP, Treesitter, fzf-lua | `config/nvim/` |
| Git | [delta](https://github.com/dandavison/delta), [lazygit](https://github.com/jesseduffield/lazygit), [gh](https://cli.github.com/), secret-scanning pre-commit hook | `gitconfig`, `config/git/hooks/`, `config/gh/` |
| Claude Code | [ccstatusline](https://github.com/sirmalloc/ccstatusline) status line matching Starship | `config/ccstatusline/`, `config/claude/` |

**macOS**

| Component | Tool | Config |
|---|---|---|
| System settings | Fast key repeat, Dock on the right, fixed Spaces, Touch ID for `sudo`, … | `install.sh` |
| Dark menu bar | Hammerspoon draws a band into the wallpaper under macOS 26's transparent menu bar — black on the MacBook (hides the notch), Catppuccin Crust elsewhere | `config/hammerspoon/init.lua` |
| Wallpaper | Generated low-poly Catppuccin Mocha wallpaper at each screen's exact size, Mac and iPhone — `wallpaper` | `config/wallpaper/generate.swift` |
| Default apps | Finder "open with" per file type — text/code → VS Code, media → IINA, archives → The Unarchiver | `config/finder/default-apps` |
| Utilities | [Maccy](https://maccy.app/) clipboard, [Shottr](https://shottr.cc/) screenshots, [Thaw](https://github.com/thaw-app/Thaw) menu bar icons (layout in a file, `thaw-layout`), AlDente, KeepingYouAwake | `Brewfile`, `install.sh` |
| Packages | [Homebrew](https://brew.sh/), App Store apps via `mas` | `Brewfile` |

Font: [Maple Mono NF](https://github.com/subframe7536/maple-font), a rounded
monospace with Nerd Font icons.

## Install

```bash
xcode-select --install    # git, swiftc; skip if already installed
git clone https://github.com/jbrunclik/dotfiles.git ~/src/dotfiles
cd ~/src/dotfiles
./install.sh              # installs Homebrew first if it's missing
```

The clone is over https because a new Mac has no SSH key yet. Once the key is
set up (and added to GitHub), switch the remote:
`git remote set-url origin git@github.com:jbrunclik/dotfiles.git`.

The install script:

1. Stops with the installer open if the Xcode Command Line Tools are missing,
   and installs Homebrew if it's missing. Then installs packages from
   `Brewfile` (plus `~/Brewfile.local`, if present) and App Store apps via
   `mas` — sign in to the App Store first. A package that fails is reported,
   not fatal.
2. Symlinks every config file. An existing file is moved to `*.bak`, or
   `*.bak.<timestamp>` if a backup is already there.
3. Sets macOS defaults — accent color, key repeat, Dock and Spaces, Finder
   extensions, Touch ID for `sudo` — and a few app preferences (see
   [GUIDE.md](GUIDE.md#macos-settings)).
4. Sets Finder's default apps, configures Claude Code, installs VS Code
   extensions.
5. Warns about missing binaries and local-only files, then lists the manual
   steps (accessibility permissions, apps without a cask).

`install.sh` and `drift.sh` share one symlink manifest (`lib/links.sh`), so the
two can't disagree about what "installed" means.

### Files not in this repo

**This repo is public — no secret belongs in a tracked file.** These are
created by hand:

| File | Contents |
|---|---|
| `~/.bash_profile.local` | API tokens, machine-local env vars and `PATH` entries; sourced last |
| `~/Brewfile.local` | Work tools and this-machine-only apps; the `Brewfile` loads it if present |
| `~/.gitconfig.local` | `[user]` name and email, `[filter "lfs"]` |
| `~/.ssh/config.local` | Host entries |
| `~/.ssh/id_ed25519`, `.pub` | SSH key |

<details>
<summary>Examples</summary>

```gitconfig
# ~/.gitconfig.local
[user]
    name = Your Name
    email = you@example.com
```

```ssh-config
# ~/.ssh/config.local
Host myserver
    HostName myserver.example.com
    User myuser
```

</details>

## Keyboardio Model 100

The keymap lives in the keyboard's firmware, edited with Chrysalis. Two
scripts keep it in the repo (quit Chrysalis first — it holds the port):

- `keyboardio-backup` — reads every setting and writes
  `config/keyboardio/model100.json` in Chrysalis's own backup format, so
  Chrysalis can restore it.
- `keyboardio-layers` — builds the Hyper layer from the base layer and colors
  every layer: the Hyper layer by what each key does, read live from the same
  data as the on-screen cheatsheet. Dry run by default; `--apply` writes it and
  reads it back.

## Keeping it honest

- `./drift.sh` — symlinks, packages (missing is drift, merely outdated is a
  note), required binaries, local files, macOS settings, mise runtimes, Claude
  Code settings, Neovim parsers, VS Code extensions, Touch ID for `sudo`.
  Non-zero exit on drift.
- CI lints every push: shellcheck, Python/Lua/JSON/YAML syntax, and that every
  binary a config shells out to has a Brewfile entry. A macOS job checks every
  Brewfile formula and cask still exists (and isn't disabled or deprecated),
  links everything into an empty `$HOME`, and validates the Ghostty config.
- Global git hooks run [gitleaks](https://github.com/gitleaks/gitleaks) in every
  repo: pre-commit on each commit, and pre-push on every commit about to leave
  the machine — the backstop for commits that skip pre-commit (git absorb's
  fixups, rebases, other libgit2 tools).
- Working on the repo with Claude Code: [CLAUDE.md](CLAUDE.md) holds the
  conventions and the after-every-change checklist, and a hook in
  `.claude/settings.json` validates each edited file — shellcheck, JSON, Lua,
  Karabiner lint, Ghostty config.
