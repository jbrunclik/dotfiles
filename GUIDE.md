# Productivity Guide

A reference for all the tools, shortcuts, and workflows in this setup.
Bookmark this and revisit as you get comfortable — don't try to learn
everything at once.

## Terminal (Ghostty)

| Action | Shortcut |
|---|---|
| New tab | `Cmd+T` |
| Split right / down | `Cmd+D` / `Cmd+Shift+D` |
| Move between splits | `Alt+H/J/K/L` (also `Cmd+Option+Arrow`) |
| Resize a split | `Alt+Shift+H/J/K/L` |
| Zoom a split (toggle) | `Alt+Z` (also `Cmd+Shift+Enter`) |
| Equalize splits | `Alt+=` |
| Fullscreen | `Cmd+Enter` |
| Jump to previous / next prompt | `Cmd+Up` / `Cmd+Down` |
| Clear screen and scrollback | `Cmd+K` |
| Open a URL | `Cmd`+click |
| Quick terminal (global) | `` Ctrl+` `` |
| Find in scrollback | `Cmd+F` |
| Edit config | `Cmd+,` |
| Reload config | `Cmd+Shift+,` |
| Previous / next tab | `Hyper+,` / `Hyper+.` (Karabiner), `Ctrl+Shift+Tab` / `Ctrl+Tab`, or `Cmd+Shift+[` / `]` (U.S. layout only) |
| Move tab left / right | `Ctrl+,` / `Ctrl+.` (the `<` `>` keys) |

The quick terminal is a system-wide dropdown terminal — press
`` Ctrl+` `` from any app to toggle it.

Prompt jumping (`Cmd+Up/Down`) needs shell integration, which is on: it scrolls
straight to the start of each command's output — the fastest way back through
a long build log or a Claude Code session.

**Splits and Neovim windows share the home row:** `Alt+H/J/K/L` moves between
Ghostty splits, `Ctrl+H/J/K/L` between Neovim windows. Ctrl can't do both —
the shell and Claude Code need `Ctrl+L` (clear) and `Ctrl+K` (kill to end of
line) — so the modifier says which layer you're moving in. They're bound to
physical keys, so the Czech layout doesn't move them. The one casualty is
readline's `Alt+L` (lowercase the next word).

**Tabs move on the same keys they switch on:** `Hyper+,/.` switches tabs,
`Ctrl+,/.` moves the current one (wrapping at the ends). Nothing is given up:
a terminal has no control character for `,` or `.`, so programs in it never
receive these chords, and Ghostty's own `,` shortcuts are on Cmd.

Two things to know:

- **Config changes need a reload before a new tab.** Ghostty doesn't watch its
  config file; new tabs use the config that was loaded last. Press
  `Cmd+Shift+,` first. Shell-integration changes then only reach new tabs.
- **`sudo` keeps Ghostty's terminfo.** `TERM=xterm-ghostty` is only described
  inside Ghostty.app, and `sudo` strips the `TERMINFO` variable that points
  there, so root TUIs failed with `Error opening terminal: xterm-ghostty`.
  `shell-integration-features = sudo` wraps `sudo` with
  `--preserve-env=TERMINFO`. `type sudo` should say "sudo is a function".

## Shell

### History search (readline)

Type the beginning of a command, then press **Up/Down arrow** to cycle
through only commands matching what you've typed. This is the single
biggest readline productivity boost.

Examples:
- Type `git` then press Up → cycles through your git commands
- Type `ssh` then press Up → cycles through your SSH sessions
- Type `docker` then press Up → cycles through docker commands

### Line editing (readline)

The same keys work in every readline prompt — bash, `python`, `psql`, `mysql`.

| Action | Shortcut |
|---|---|
| Start / end of line | `Ctrl+A` / `Ctrl+E` (or `Hyper+O` / `Hyper+P`) |
| Delete word back, stopping at punctuation | `Option+Backspace` |
| Delete back to the previous space (a whole path or URL) | `Ctrl+W` |
| Delete to start / end of line | `Ctrl+U` / `Ctrl+K` |
| Paste back what you just deleted | `Ctrl+Y` |
| Undo the last edit | `Ctrl+_` |
| Insert the previous command's last argument (repeat to go further back) | `Option+.` |
| Edit the current command in `$EDITOR` (nvim), run it on save and quit | `Ctrl+X` `Ctrl+E` |

Two shell shorthands worth knowing: `cd -` returns to the previous directory,
and `sudo !!` re-runs the last command with sudo.

The Option-based keys work because Ghostty sends Option as Alt
(`macos-option-as-alt`).

### Tab completion

- **Single tab** shows all completions (no need to double-tap)
- **Case-insensitive** — `cd doc` Tab → `cd Documents/`
- **Hyphen-underscore equivalent** — `my-proj` matches `my_proj`

### Fuzzy finder (fzf)

| Action | Shortcut |
|---|---|
| Search command history | `Ctrl+R` |
| Insert file path(s), with `bat` preview | `Ctrl+T` |
| Jump into a directory, with tree preview | `Alt+C` (Option+C) |
| Find files | Type then `**` Tab (e.g., `vim **` Tab) |
| Change directory | `cd **` Tab |

All of these walk the filesystem with `fd`, not `find`: hidden files are
included, while `.git` and anything gitignored (`node_modules`, build output)
are skipped. `Tab` multi-selects in `Ctrl+T`. `Alt+C` works because Ghostty
sends Option as Alt (`macos-option-as-alt`).

### Smart cd (zoxide)

Zoxide learns which directories you visit frequently. After using `cd`
normally for a while, you can jump directly:

```bash
cd projects        # first few times, use full paths as normal
cd ~/src/dotfiles  # zoxide is learning...

# later, from anywhere:
cd dot             # jumps to ~/src/dotfiles
cd proj            # jumps to ~/projects

zi                 # interactive fuzzy directory picker
```

The more you visit a directory, the higher it ranks. Zoxide's `z`
command (aliased to `cd`) falls back to regular `cd` if it can't
find a match.

### Modern CLI tools

Most are aliased over the defaults. Use them as you normally would:

```bash
cat file.py        # syntax-highlighted output (bat)
ls                 # icons + git status + grouped dirs (eza)
ll                 # detailed listing
lt                 # tree view (2 levels)
fd .json           # find files matching pattern — not aliased over find (different arguments)
rg "TODO"          # search file contents (ripgrep) — not aliased, use rg directly
du                 # visual disk usage (dust)
top                # process monitor (btop)
diff a.txt b.txt   # syntax-highlighted diff (delta)
glow README.md     # render markdown in terminal
tldr tar           # the handful of invocations you actually need (tlrc)
batman rsync       # man page with bat highlighting
batgrep "TODO" src # rg results shown with bat, with context
batdiff            # git diff of the working tree, rendered by bat
just               # run a recipe from the project's justfile (lists them with `just --list`)
```

`tldr` downloads its page cache on first use and refreshes it automatically.

### JSON processing (jq)

```bash
cat data.json | jq '.results[].name'    # extract nested fields
curl -s api/endpoint | jq '.'           # pretty-print JSON
jq -r '.[] | [.id, .name] | @csv' data.json  # convert to CSV
```

Tips:
- `jq 'keys'` to see top-level keys in an object
- `jq -r` for raw output (no quotes around strings)
- `jq -e` to exit non-zero if result is null/false (useful in scripts)

### HTTP requests (httpie)

HTTPie is a human-friendly alternative to curl:

```bash
http GET api.example.com/users          # GET request
http POST api.example.com/users name=Jo # POST JSON
http -a user:pass api.example.com       # basic auth
https api.example.com Authorization:"Bearer $TOKEN"  # custom header
http --download example.com/file.zip    # download file
```

Tips:
- `http` for plain HTTP, `https` for HTTPS
- Request body: `field=value` for strings, `field:=123` for non-strings
- `http --print=HhBb` to show request+response headers+body
- Sessions: `http --session=myapi api.example.com` to persist auth/cookies

### CLI tips

Tips:
- `bat` supports `bat file.py -l python` to force a language
- `fd` respects `.gitignore` by default — use `fd -H` to include hidden files
- `rg -t py "import"` to search only Python files
- `dust -d 2` to limit directory depth
- `gm` is always GraphicsMagick: `bash_profile` pins the alias to the Homebrew
  binary, so a `gm` = `git merge` shorthand (oh-my-bash used to define one) can't shadow it

### Runtime version management (mise)

```bash
mise use python@3.12   # pin Python 3.12 in current project
mise use node@22       # pin Node 22
mise ls                # show active versions
mise install           # install versions from .mise.toml
```

Mise creates a `.mise.toml` per project. When you `cd` into a project
with a `.mise.toml`, the correct versions activate automatically.

## Python workflow

| Concern | Tool |
|---|---|
| Package/project management | `uv` |
| Linting + formatting | `ruff` (replaces black, isort, flake8) |
| Type checking (VS Code) | Pylance (built-in Pyright) |
| Type checking (Neovim) | basedpyright |

### Project setup with uv

```bash
uv init myproject      # create new project with pyproject.toml
cd myproject
uv add requests        # add dependency (creates .venv automatically)
uv add --dev pytest    # add dev dependency
uv sync                # install all dependencies
uv run pytest          # run command in the project's virtualenv
```

uv replaces pip, pip-tools, virtualenv, and pyenv. It's 10-100x faster
than pip. Both VS Code and Neovim auto-detect the `.venv` it creates.

### Ruff (linting + formatting)

Ruff replaces Black, isort, flake8, pydocstyle, and pyupgrade with one tool.
It runs on save in both VS Code and Neovim.

```bash
ruff check .           # lint
ruff check --fix .     # lint + auto-fix
ruff format .          # format (Black-compatible)
```

Configure per-project via `pyproject.toml`:
```toml
[tool.ruff]
line-length = 88
[tool.ruff.lint]
select = ["E", "F", "I", "UP"]
```

### Type checking

- **VS Code**: Pylance (built-in Pyright) — set to "basic" mode
- **Neovim**: basedpyright — open-source fork with Pylance features
- **mypy**: Not needed for most projects. Only relevant for Django/SQLAlchemy
  (mypy has ORM plugins that Pyright lacks)

## Editor (Neovim)

Plugins: LSP (basedpyright, ruff, ts_ls, yamlls, lua_ls), blink.cmp,
nvim-treesitter, fzf-lua, gitsigns, lualine, indent-blankline, which-key,
conform.nvim, nvim-lint, mini.surround, mini.pairs, copilot.vim.

Mason installs the LSP servers, but treesitter parsers are compiled by the
`tree-sitter` CLI and conform/nvim-lint shell out to `prettier` and `eslint_d` —
all three come from the `Brewfile`, and `drift.sh` verifies them.

### Getting around

| Action | Keys |
|---|---|
| Find files | `Ctrl+P` or `Space f f` |
| Live grep (search in files) | `Space f g` |
| Switch buffers | `Space f b` |
| Recent files | `Space f r` |
| File symbols | `Space f s` |
| Diagnostics | `Space f d` |
| Help tags | `Space f h` |

**Tip:** Press `Space` and wait — which-key will show all available
bindings.

### LSP (code intelligence)

| Action | Keys |
|---|---|
| Go to definition | `gd` |
| Find references | `gr` |
| Go to implementation | `gi` |
| Hover docs | `K` |
| Rename symbol | `Space r n` |
| Code action | `Space c a` |
| Type definition | `Space D` |
| Next diagnostic | `]d` |
| Previous diagnostic | `[d` |
| Show diagnostic float | `Space e` |

Language servers install automatically via Mason on first use.
Run `:Mason` to see status. Configured servers:
- **Python**: basedpyright (type checking) + ruff (linting/formatting)
- **TypeScript**: ts_ls
- **YAML**: yamlls
- **Lua**: lua_ls

### Git (gitsigns)

| Action | Keys |
|---|---|
| Next changed hunk | `]h` |
| Previous changed hunk | `[h` |
| Stage hunk | `Space h s` |
| Reset hunk | `Space h r` |
| Preview hunk | `Space h p` |
| Blame current line | `Space h b` |

### Editing

| Action | Keys |
|---|---|
| Move lines down (visual mode) | `J` |
| Move lines up (visual mode) | `K` |
| Surround with quotes | `sa` + motion + `"` |
| Delete surrounding | `sd` + `"` |
| Replace surrounding | `sr` + `"` + `'` |
| Format buffer | `Space c f` |
| Next buffer | `Space b n` |
| Previous buffer | `Space b p` |
| Close buffer | `Space b d` |

### Copilot

- Ghost text appears automatically as you type
- **Tab** to accept a suggestion
- Copilot status: `:Copilot status`
- Copilot logs: `:Copilot log`

### Completion (blink.cmp)

| Action | Keys |
|---|---|
| Navigate popup | `Ctrl+N` / `Ctrl+P` |
| Accept selection | `Enter` |
| Dismiss popup | `Ctrl+E` |
| Confirm selection | `Ctrl+Y` |

### Auto-formatting

Files are formatted on save:
- **Python**: ruff (format + organize imports)
- **TypeScript/JavaScript**: prettier
- **YAML/JSON/Markdown**: prettier

## VS Code

Settings are symlinked from the dotfiles repo. Key features:

- **Catppuccin Mocha** theme + icons (matches terminal)
- **Maple Mono NF** font with ligatures
- **Python**: Pylance (type checking) + Ruff (lint/format on save)
- **TypeScript/JS/YAML/JSON/Markdown**: Prettier (format on save)
- **Auto-save** on focus change
- **Claude Code** in panel mode

Extensions are managed via `config/vscode/extensions.txt` and installed
by `./install.sh`.

## Text editing everywhere (macOS)

These work in any native text field — Mail, Notes, Slack, browsers, VS Code —
and most also in Ghostty. Add `Shift` to any movement to select instead.

| Action | Shortcut |
|---|---|
| Word left / right | `Option+Left` / `Option+Right` (or `Hyper+B` / `Hyper+W`) |
| Line start / end | `Cmd+Left` / `Cmd+Right` (or `Hyper+O` / `Hyper+P`) |
| Document start / end | `Cmd+Up` / `Cmd+Down` |
| Delete word back / forward | `Option+Backspace` / `Option+Fn+Backspace` |
| Delete to line start | `Cmd+Backspace` |
| Forward delete | `Fn+Backspace` (or `Hyper+Backspace`) |
| Paste without formatting | `Cmd+Option+Shift+V` (Notion: `Cmd+Shift+V`) |

macOS text fields also understand the emacs keys from the shell: `Ctrl+A`/`E`
(line start/end), `Ctrl+K` (delete to line end) and `Ctrl+Y` (paste it back),
`Ctrl+D` (forward delete).

## macOS essentials

| Action | Shortcut |
|---|---|
| Cycle windows of the current app | ``Cmd+` `` |
| Show / hide dotfiles in Finder and open/save dialogs | `Cmd+Shift+.` |
| Type a path in Finder or any open/save dialog | `Cmd+Shift+G` |
| Move a file (cut + paste) in Finder | `Cmd+C`, then `Cmd+Option+V` |
| Emoji and symbol picker | `Cmd+Ctrl+Space` |
| Lock the screen | `Cmd+Ctrl+Q` |
| Keep the Mac awake (no sleep, screen stays on) | Click the cup in the menubar (KeepingYouAwake) |

## Finder default apps

`config/finder/default-apps` lists which app opens which file type; `./install.sh`
applies it and `./drift.sh` reports anything that has drifted. Text, config and
source files go to VS Code (out of the box they land in TextEdit, Notion, Claude
Desktop, Cursor, or Ghostty — which *executes* a double-clicked `.sh`). HEIC and
camera RAW go to Preview instead of GIMP; audio and video go to IINA (QuickTime
cannot play `.mkv` or `.webm`, and Music imports a double-clicked `.mp3` into the
library); `.rar` and `.7z` go to The Unarchiver.

Two things to know:

- macOS shows a "Do you want all documents with the extension … to open with …?"
  dialog for every type that actually changes. No supported API avoids it. Types
  already set correctly are skipped, so it only happens on first run or after
  something else claims a type.
- An app can only be assigned types it declares in its `Info.plist`. `.env`, `.tf`
  or `.jsonc` cannot be sent to VS Code because VS Code does not declare them.
  Check what an app declares with:

  ```bash
  plutil -convert json -o - "/Applications/Visual Studio Code.app/Contents/Info.plist" \
    | jq -r '.CFBundleDocumentTypes[].CFBundleTypeExtensions[]?' | sort -u
  ```

To add a type, append `<bundle id>  .<ext>` to the list. Find a bundle id with
`osascript -e 'id of app "Preview"'`.

## Wallpaper

`wallpaper` generates an abstract Catppuccin Mocha wallpaper — **Low-poly**: a
faceted triangle mesh in blue, sapphire and teal, dark and calm at the top and
richer toward the bottom — at each screen's exact pixel size, and sets the Mac's:

| File (in `~/Pictures/Wallpapers/`) | For |
|---|---|
| `lowpoly-5120x2880.png` | 5K external display |
| `lowpoly-3024x1964.png` | 14" MacBook Pro |
| `lowpoly-1206x2622.png` | iPhone 17 Pro lock screen — save to Photos, then Settings → Wallpaper |
| `lowpoly-home-1206x2622.png` | iPhone 17 Pro home screen — the same facets, lower and dimmer, so icons read clearly |

In iOS, add the lock screen image, then choose **Customize Home Screen → Photos**
and pick the home version, so the pair stays together. Leave both unzoomed and
turn Perspective Zoom off: the files are the screen's exact size. The phone version is composed for the tall screen (pattern lower, more dark sky
for the clock), not cropped from the desktop one. Fine grain keeps the dark
gradients from banding, which is also why the files are large.

- `wallpaper --preview [variant…]` — a comparison sheet on the Desktop.
  Variants: `lowpoly` (default), `crystal`, `lattice`, `blocks`, `peaks`,
  `tide`, `contours`, `ripples`, `ridges`, `bokeh`, `hex`, `shards`,
  `halftone`, and warmer `aurora`, `ember`.
- `wallpaper <variant>` — render and set another one.
- The design lives in `config/wallpaper/generate.swift` (deterministic — same
  variant and size, same image). Screen sizes are at the top of `wallpaper`.

## Black menu bar

macOS 26's menu bar is transparent, so a bright wallpaper shows through it —
distracting on any display, and on the MacBook it frames the notch. Hammerspoon
draws a **dark band, exactly the menu bar's height**, into a copy of your
wallpaper and sets that copy: **pure black on the built-in display**, where the
notch disappears into it (even Catppuccin's darkest color would leave the notch
faintly outlined on that panel), and **Catppuccin Crust** (`#11111b`) on other
displays, where it blends with the wallpaper and Ghostty. No app needed — this is what TopNotch did, minus the part that broke.

- Pick wallpapers as usual in System Settings: the band is redrawn on the new
  one a second later. No polling — it reacts to the wallpaper store changing,
  to display changes (resolution, switching screens) and to wake. The original file is
  never changed; copies live in `~/Library/Caches/dotfiles-menubar-band/`.
- Each display gets a copy at its own pixel size and menu bar height (taller on
  the notched built-in screen), drawn with "fill" scaling so it lines up exactly.
  A wallpaper named `<name>-<w>x<h>` (like the generated ones) is swapped for
  its sibling at that screen's size when one exists, so nothing is cropped.
- To turn it off, remove the "Black menu bar" block from `init.lua` and pick
  your wallpaper again.

## macOS settings

`./install.sh` writes these with `defaults write`:

| Setting | Value | Why |
|---|---|---|
| Accent / highlight color | Catppuccin mauve | Matches everything else; contrasts with the blue-teal wallpaper the way Catppuccin apps use it |
| Appearance | Dark, dark-style app icons | Icons keep their own colors so apps stay recognizable |
| Wallpaper tinting in windows | On | With the blue-teal wallpaper, Finder and System Settings get a faint blue cast, closer to Catppuccin's base than neutral grey |
| Key repeat | 30 ms, 225 ms initial delay | Fastest the System Settings sliders allow; Hyper+HJKL and CapsLock Backspace rely on it |
| Press-and-hold | Off | Holding a letter repeats it instead of opening the accent picker |
| File extensions in Finder | Always shown | |
| Dock | Right edge, auto-hide, 0.2 s delay, quick slide, no magnification | A bottom Dock popped up over Zoom's toolbar on overshoot. The short delay keeps it from covering controls near the right edge, like Slack's thread close button |
| Minimize | Into the app's Dock icon | Dock doesn't grow a pile of minimized windows |
| Spaces order | Fixed (no reordering by recent use) | Positions stay where muscle memory expects them |
| Click wallpaper to reveal desktop | Off | A near-miss on a window edge no longer hides every window |
| `sudo` authentication | Touch ID | `pam_tid` in `/etc/pam.d/sudo_local`, which survives macOS updates; the password still works as a fallback |

If `sudo` still asks for a password with Touch ID enabled, check the log:
`log show --last 5m --predicate 'process == "sudo"' | grep -i "interaction"`.
"User interaction is required" (LocalAuthentication error -1004) in every terminal,
while Touch ID works for apps, means something outside the dotfiles blocks
biometric prompts for root processes — on a managed Mac, ask IT (endpoint
security or MDM). `pam_reattach`, the tmux fix, doesn't help in that case.

App preferences `install.sh` also sets (only the ones changed from default):

| App | Setting |
|---|---|
| AlDente | Charge limit 80 % (macOS native; its lowest), sailing mode 5 %, automatic discharge, heat protection (pauses charging above 35 °C — heat wears a battery faster than charge level), percentage in the menu bar |
| Scroll Reverser | Reverse scrolling for the mouse only, not the trackpad |
| gh | `~/.config/gh/config.yml` is symlinked (aliases such as `gh co`; `git_protocol: ssh`, so `gh repo clone`, `gh-new-repo` and fork checkouts get SSH remotes like every other repo); `hosts.yml` with the token stays out of the repo |

Key repeat needs a logout; Finder picks up the extension setting on restart
(`killall Finder`). The Dock settings apply when `install.sh` restarts the Dock.

Spaces aren't used on purpose: Hammerspoon layouts (Hyper+Z/X/C/V) and app
focus (Hyper+1–6) already switch context in one key, and Hammerspoon's window
queries only see the current Space, so layouts can't pull windows from another
one. Native fullscreen (Hyper+F) is the only thing that creates a Space.

Deliberately left on: smart quotes and dashes. Mail and other prose apps get
real typography; terminals and editors ignore the setting. Just don't draft
shell commands in Notes or Mail — `--force` turns into `—force` there.

## Git

### Delta pager

All git diffs are syntax-highlighted with line numbers. Navigation:

| Action | Keys |
|---|---|
| Next file | `n` |
| Previous file | `N` |
| Quit | `q` |

### Lazygit

Run `lazygit` in any repo for a full terminal UI. Key areas:

| Panel | What it shows |
|---|---|
| Left side | Files, branches, commits, stash |
| Right side | Diff preview |

Essential keys:
- `Space` — stage/unstage file
- `c` — commit
- `p` — pull, `P` — push
- `b` — branch operations
- `i` — interactive rebase
- `?` — full keybinding help
- `q` — quit

Lazygit makes interactive rebase, partial staging, and conflict resolution
visual and fast. Try it instead of `git add -p` or `git rebase -i`.

### GitHub CLI (gh)

```bash
gh pr list                     # list open PRs
gh pr view 123                 # view PR details
gh pr checkout 123             # check out a PR branch
gh pr create                   # create PR from current branch
gh pr review 123 --approve     # approve a PR
gh run list                    # list recent CI runs
gh run watch                   # live-watch current branch's CI
gh issue list                  # list open issues
gh dash                        # PR/issue dashboard (install: gh extension install dlvhdr/gh-dash)
```

Tips:
- `gh pr create --fill` auto-fills title/body from commits
- `gh pr merge --squash --delete-branch` for clean merges
- `gh api repos/{owner}/{repo}/pulls` for raw API access

### GitLab CLI (glab)

Work repos live on GitLab; `glab` mirrors `gh` there. It's in `~/Brewfile.local`,
not the public Brewfile. Log in once with `glab auth login`.

```bash
glab mr list                   # open merge requests
glab mr checkout 123           # check out an MR branch
glab mr view 123 --web         # open an MR in the browser
glab ci view                   # live pipeline view for the current branch
glab ci trace                  # follow a job's log
```

### Useful git config

- **`git push`** on a new branch automatically sets upstream (no `-u origin` needed)
- **`git pull`** rebases by default (cleaner history)
- **`rerere`** remembers conflict resolutions and auto-applies them next time
- **`fetch.prune`** auto-cleans stale remote branches
- **`diff.algorithm = histogram`** — better diffs for moved code
- **`diff.colorMoved`** — moved lines get their own color, so a refactor reads
  as a move instead of a delete plus an add
- **`push.followTags`** — `git push` also pushes annotated tags on the pushed
  commits. Lightweight tags (`git tag name`) stay local
- **`help.autocorrect = prompt`** — a typo like `git stauts` asks
  "Run 'status' instead [y/N]?" (interactive terminals only)

Tried and dropped: `core.fsmonitor` + `core.untrackedCache`. On a 31k-file repo
they made `git status` *slower* (30.6 ms vs 21.4 ms, warm cache) — APFS plus
macOS's metadata cache already make the scan cheap, and the watcher adds IPC
plus a background daemon per repo. Worth revisiting only for repos with
hundreds of thousands of files.

## SSH

`ssh_config` keeps one connection per host open and reuses it
(`ControlMaster auto`, `ControlPersist 10m`). The first `git fetch` to GitHub
pays the ~1 s handshake; later ones within 10 minutes skip it (measured: 1.67 s
→ 0.55 s for `git ls-remote`). It also covers scp, rsync and new sessions to
your own hosts.

| Task | Command |
|---|---|
| Is a shared connection open? | `ssh -O check <host>` (e.g. `git@github.com`) |
| Close it (hangs after sleep or Wi-Fi change) | `ssh -O exit <host>` |
| Opt a host out | `ControlMaster no` under its entry in `~/.ssh/config.local` |

Things to know:

- After the Mac sleeps or switches networks, the shared connection can be dead
  without SSH knowing; the next command waits until `ServerAlive` gives up
  (~45 s: a keepalive every 15 s, 3 missed). `ssh -O exit <host>` fixes it
  right away.
- Everything to one host shares one connection: a big `scp` slows an
  interactive session there, and if it drops, they all drop.
- **Agent forwarding follows the first connection.** If the shared connection
  was opened without forwarding — a host reached by IP that doesn't match its
  `Host` block, or a tool that passes its own options — every later `ssh -A`
  to that host gets no agent for up to 10 minutes. Symptom:
  `ssh -A <host> 'echo $SSH_AUTH_SOCK'` prints nothing while the same host
  over another address works. Fix: `ssh -O exit <host>`, and make sure the
  `Host` line lists every name and IP you use (`Host myserver 192.168.1.10`).
- A shared connection also keeps the local agent it started with. After
  switching agents (e.g. to 1Password's), close open ones with `ssh -O exit`.

## Hyper key

Hyper (Cmd+Option+Ctrl+Shift) is a dedicated modifier that doesn't
conflict with any app shortcuts. **Hold Hyper on its own for a moment to see a
cheatsheet of every Hyper binding**; release it (or press any key) to close.
It's triggered by:

| Keyboard | Key | Config |
|---|---|---|
| MacBook | CapsLock (hold) | Karabiner-Elements |
| Keyboardio Model 100 | Right thumb-cluster Fn key (hold) | Chrysalis (backed up in `config/keyboardio/`) |

Hyper shortcuts are tied to **physical keys**, so they stay put when you switch
to the Czech layout (QWERTZ swaps Y and Z): Karabiner matches physical keys,
and Hammerspoon's `bindHyper` binds by macOS key code instead of by character.

On MacBook, CapsLock is three keys in one:

| Gesture | Result |
|---|---|
| Hold + another key | Hyper |
| Tap (release within 250 ms) | Backspace |
| Tap, then press again within 250 ms and hold | Repeating Backspace |

Holding CapsLock and letting go without pressing anything sends nothing once
250 ms have passed, so an abandoned Hyper chord doesn't delete a character.
The catch: a Hyper chord started within 250 ms of a Backspace tap becomes
Backspace instead.

### Keyboardio Model 100

The keymap lives in the keyboard itself (Kaleidoscope firmware, edited with
Chrysalis), so it works on any computer without Karabiner. Keys that matter
here, layer 0:

| Key | Sends | Does |
|---|---|---|
| Right thumb-cluster Fn | Holds the **Hyper layer**, where every key sends Hyper + itself | Hyper, held — and the keys light up by what they do |
| Butterfly | `Cmd+Shift+4` | Shottr area capture (its hotkey; macOS's own `Cmd+Shift+4` is off) |
| Any | `F18` (custom code 109) | Zoom mute (Hammerspoon binds F18) |
| Prog | `F19` (custom code 110) | Messages show / hide (Hammerspoon binds F19) |

**Colors.** The LEDs run in Colormap mode with per-layer colors (Catppuccin
Mocha's color families, saturated — its pastels read as near-white on LEDs;
brightness 200/255):

- **Base** — every key softly lit in a dim left-to-right gradient (mauve,
  blue, teal, green — four columns each); Prog teal (Messages), Any red
  (mute), butterfly orange (screenshot), layer keys white.
- **Hyper** (hold the thumb key) — bound keys by what they do, unbound keys
  dark. The keyboard *is* the cheatsheet here:

  | Keys | Color |
  |---|---|
  | H J K L — arrows | sky (same as the Fn layer's arrows) |
  | B W, O P — word / line jumps | orange |
  | U I — page up / down | lavender |
  | Backspace — forward delete | pink |
  | `,` `.` — Ghostty tabs | white |
  | 1–6 — apps, each in its own color | Ghostty mauve (its Catppuccin accent), Dia yellow, Chrome green, Slack pink, Notion white, Zoom blue |
  | Z X C V — layouts · ` Tab Q A S D F, left thumb Cmd Shift — windows | mauve · blue |
  | T Messages · M Zoom mute · R reload | teal · red · yellow |
  | Space — launcher | green (like the app keys) |

- **Function** / **Numpad** — only their own keys lit, by kind: F-keys pink,
  arrows sky, media yellow, mouse keys green, brackets orange, editing and
  navigation lavender; digits green, operators yellow. The key that gets you
  back out of a layer stays white.

The Numpad is on **layer 4**, not the stock layer 1: the firmware's stock NumPad
plugin is tied to layer 1 and, while it's active, forces the number keys to its
own color (off here), so the color map can't light them. Layer 1 is left empty.

Only **16 colors** are usable: the color map stores 4 bits per key, even though
the palette holds 24. `keyboardio-layers` refuses to go past index 15. That's
why some keys share a color where they never sit side by side (Slack and
forward delete, Zoom and the window keys, Ghostty tabs and the Hyper key).

The color map is indexed by LED, not by key — the LEDs are wired in a different
order (the table is in `keyboardio-layers`, the same one Chrysalis uses).
`keyboardio-layers` generates all of this from the dotfiles — the Hyper layer
from the base layer, its colors from the live cheatsheet data — so **after
adding or moving a Hyper binding, run `keyboardio-layers --apply`, then
`keyboardio-backup`** and commit. Without `--apply` it only prints what would
change. It writes over the same protocol Chrysalis uses and reads every value
back; if something looks wrong, restore the committed backup with Chrysalis.

The base layer has no arrow keys, so on the Hyper layer the **left thumb's
Cmd and Shift send Hyper+← and Hyper+→** (focus left / right half). They're
idle during a Hyper chord anyway — Hyper already holds every modifier. This is
an override in `keyboardio-layers` (`THUMB_ARROWS`); everything else on the
layer is generated from the base layer.

Two consequences of Hyper being a layer here: holding Hyper *alone* sends
nothing, so the on-screen cheatsheet only opens from the MacBook's Caps Lock
(the lit keyboard replaces it); and Hyper + mouse click doesn't exist on the
Model 100.

**Back it up after every change in Chrysalis:** quit Chrysalis (it holds the
serial port), run `keyboardio-backup`, and commit `config/keyboardio/model100.json`.
The script asks the keyboard for every setting over the same protocol Chrysalis
uses (read-only — it skips reset/erase/trigger) and writes Chrysalis's own
backup format, so restoring is Chrysalis's restore-from-backup option. Chrysalis
only backs up by itself before a firmware update, which is why its last one
predated the Hyper and butterfly keys.

### Cheatsheet

Holding Hyper alone for 1.2 s opens an overlay listing every binding below.
Quick chords never trigger it: any key pressed within 1.2 s cancels it. The list
is generated, not written by hand:

- Hammerspoon bindings come from `bindHyper(key, section, description, fn)` in
  `init.lua` — a binding made with plain `hs.hotkey.bind` won't appear.
- Karabiner remaps come from `karabiner.json` rule descriptions written as
  `[App: ]Hyper+<keys> → <action>`; a trailing `(…)` note is left out.

Every Hammerspoon popup (this one and the Hyper+Space launcher) is drawn in
three columns sized to the widest entry: key, description, and a dimmed
trailing `(…)` note or hint.

### Printable cheatsheet

`hyper-cheatsheet` writes an A4 landscape PDF to `~/Desktop/hyper-cheatsheet.pdf`
(or a path you pass), for the desk — shortcuts to pick up a few at a time:

1. **Hyper** — every Hyper binding, asked live from Hammerspoon (exactly what
   the hold-Hyper overlay shows).
2. **Keyboard** — this guide's Ghostty, readline, fzf, "Text editing
   everywhere" and "macOS essentials" tables.

Nothing is listed by hand: page 2 is parsed from this file, so editing a table
here changes the printout. (Sections can also contribute `command  #
explanation` lines from their code blocks.) Which sections go on which page is the `pages`
list at the top of `config/hammerspoon/cheatsheet-pdf.swift`; renaming a listed
section makes the script fail rather than silently drop it. Each page shrinks
its font to fit. Rendering uses macOS's own WebKit, compiled on the fly — needs
Hammerspoon running and the Xcode Command Line Tools (`swiftc`).

### Navigation (Karabiner)

| Shortcut | Action |
|---|---|
| Hyper + H | Left arrow |
| Hyper + J | Down arrow |
| Hyper + K | Up arrow |
| Hyper + L | Right arrow |
| Hyper + U / I | Page up / Page down |
| Hyper + O / P | Line start / end (Cmd+Left/Right) |
| Hyper + B / W | Word back / forward (Option+Left/Right) |
| Hyper + Backspace | Forward delete |

Works system-wide: Slack, Notion, Chrome, Ghostty, etc.

O/P send Cmd+Left/Right rather than Home/End: in most Mac apps Home/End scroll to
the top or bottom of the document instead of moving within the line. In
Ghostty, Cmd+Left/Right and Option+Left/Right are already mapped to the shell's
line-start/end and word motions, so the whole layer works in the terminal too.
There's no Shift+ variant for selecting: Hyper already includes Shift.

### Ghostty tabs (Karabiner)

| Shortcut | Action |
|---|---|
| Hyper + , | Previous tab |
| Hyper + . | Next tab |

Only while Ghostty is frontmost. These have to live in Karabiner rather than
Ghostty's config: macOS reserves `Hyper+,`, `Hyper+.` and `Hyper+/` for
sysdiagnose and swallows them before any app sees them. Karabiner runs first and
rewrites them to Ghostty's `Ctrl+Shift+Tab` / `Ctrl+Tab` — not `Cmd+Shift+[` / `]`,
because on the Czech layout that physical key types `ú` and Ghostty's binding
no longer matches. Outside Ghostty they still start
a sysdiagnose (a ~400 MB archive in `/private/var/tmp`).

### Window management (Hammerspoon)

| Shortcut | Action |
|---|---|
| Hyper + A | Tile window left half |
| Hyper + S | Maximize window (no fullscreen) |
| Hyper + D | Tile window right half |
| Hyper + F | Toggle native fullscreen |
| Hyper + Tab | Toggle focus between left/right windows |
| Hyper + Left/Right | Focus window in that direction (MacBook arrows; Model 100: left thumb Cmd / Shift) |
| Hyper + ` | Cycle the windows stacked on this half (or at this spot) |
| Hyper + Q | Hide the front app (like `Cmd+H`); focus returns to the previous app |

Hyper+Q sends an app to the background; `Cmd+Q` on the same key quits it for
real (`Cmd+W` only closes the window — WhatsApp, Slack and Zoom keep running).
A stray Hyper+Q is harmless: Hyper+1–6 or the launcher brings the app back.

Hyper+` is Cmd+` per spot instead of per app: it cycles the windows that sit
exactly where the focused one is — Slack and Notion both tiled right, two
maximized windows, two floats on top of each other. Hyper+Tab and Hyper+Left/Right
only ever reach the topmost window of a half; this gets at the ones under it.
Each press raises the bottom-most of the stack, so three windows come round in
turn rather than the top two swapping.

### Layouts (Hammerspoon, bottom row)

| Shortcut | Layout |
|---|---|
| Hyper + Z | Coding — Ghostty left, Dia right |
| Hyper + X | Meeting + notes — Zoom left, Notion right |
| Hyper + C | Meeting + chat — Zoom left, Slack right |
| Hyper + V | Meeting + browsing — Zoom left, Dia right |

Press the same layout again to swap focus between the two sides. An app that
isn't running (or has no window) is launched first; the layout waits for its
window — up to 10 s, since Slack and Notion take a few seconds — then tiles,
and repeats the move half a second later because Electron apps restore their
own saved position right after opening.

### App focus (Hammerspoon)

| Shortcut | App |
|---|---|
| Hyper + 1 | Ghostty |
| Hyper + 2 | Dia |
| Hyper + 3 | Chrome |
| Hyper + 4 | Slack |
| Hyper + 5 | Notion |
| Hyper + 6 | Zoom |

The first press brings up the app's main window (launching the app if it has
no window). The second puts it **beside the window you came from**, so
`Hyper+4 4` from the terminal gives "terminal + Slack" without a fixed layout:

- The window you came from keeps its half if it's tiled; if it was maximized
  or floating, it takes the left half. The app gets the other half and the
  focus. Whatever was on that half stays underneath — Hyper+` reaches it.
- "The window you came from" is the next window down in the stacking order,
  so nothing is remembered between presses. With no other window it
  maximizes instead. Hyper+S is the maximize key now.

For Zoom that's the **call** window during a meeting, never the meetings list
("Zoom Workplace"); the Zoom layouts (Hyper+X/C/V) pick the same way.

### Launcher (Hammerspoon)

`Hyper+Space` opens a panel of one-key shortcuts; press the key (no modifiers)
and the app comes forward the same way as Hyper+1–6, launching it if needed.
For apps used often enough to want a key, not often enough to earn a Hyper
number — everything else stays with Spotlight.

| Key | App | Key | App |
|---|---|---|---|
| G | Ghostty (also Hyper+1) | 1 | 1Password |
| D | Dia (Hyper+2) | C | Claude |
| H | Chrome (Hyper+3) | F | Finder |
| S | Slack (Hyper+4) | M | Music |
| N | Notion (Hyper+5) | V | VS Code |
| Z | Zoom (Hyper+6) | W | WhatsApp |
| T | Messages (Hyper+T) | , | System Settings |

The panel lists them in this order: Hyper apps first, the rest
alphabetically, System Settings last.

- If the app is already in front, its key hides it instead (like Hyper+Q), so
  `Hyper+Space W` both summons and dismisses WhatsApp.
- **Shift+key puts the app beside the window you're in**, like a second
  press of Hyper+1–6: `Hyper+Space Shift+C` is "this + Claude". Same rules —
  a tiled window keeps its half, anything else takes the left — and a hidden
  or not-yet-running app is unhidden or launched first. Shift+T tiles Messages
  as a half instead of floating it.
- The panel shows straight away; typing the letter from memory just flashes it.
- `Escape`, any key not in the list, `Hyper+Space` again or 3 s of nothing
  closes it without doing anything. Its keys only work while it's open — an
  event tap swallows them — so they never reach the app underneath.
- `T` does what Hyper+T does (Messages over the right third). `F` opens a new
  Finder window at home when none is open — otherwise Finder's only "window"
  is the Desktop and nothing would appear.
- The list is `launcherApps` in `init.lua`; a new app also needs its bundle ID
  in `BUNDLE_IDS`. Keys are physical, so they survive the Czech layout.

### Zoom (Hammerspoon)

| Shortcut | Action |
|---|---|
| Hyper + M | Toggle mute (works from any app, no focus switch) |
| Any (Model 100) | Same, as one key: Chrysalis maps Any to `F18`, Hammerspoon binds `F18` |

### Messages (Hammerspoon)

| Shortcut | Action |
|---|---|
| Hyper + T | Show Messages over the right third; press again to hide it and return to the app you were in |
| Prog (Model 100) | Same, as one key: Chrysalis maps Prog to `F19`, Hammerspoon binds `F19` |

For quick replies without touching the current layout. It's the one Hyper key
where "again" hides instead of putting the app beside the last window. Pin the conversations you reply to
most, so Messages opens on them, and allow those people through your work
Focus (System Settings → Focus → People).

### Utilities

| Shortcut | Action |
|---|---|
| Hyper + R | Reload Hammerspoon config |

Saving any `.lua` file in `config/hammerspoon/` reloads Hammerspoon on its own
(`hs.pathwatcher`), so Hyper+R is rarely needed.

### Debugging

The `hs` CLI lets you query Hammerspoon from the terminal:

```bash
hs -c 'hs.window.focusedWindow():frame()'   # inspect focused window
hs -c 'hs.application.get("Slack"):allWindows()'  # list app windows
```

If an app's windows are invisible to Hammerspoon (returns 0 windows),
restart the app — Electron apps like Slack can lose their accessibility
registration after updates.

### Editing the Karabiner config

- `~/.config/karabiner` is a symlink to the whole `config/karabiner/` directory,
  not just the JSON file. Karabiner saves by writing a temp file and renaming it
  over `karabiner.json`, which used to replace a file symlink with a plain copy.
- Karabiner reformats `karabiner.json` (compact arrays, sorted keys) whenever it
  saves. After editing by hand, let it save once and commit what it wrote, so
  later diffs only show real changes.
- It doesn't always notice hand edits. Force a reload with:

  ```bash
  launchctl kickstart -k gui/$(id -u)/org.pqrs.service.agent.Karabiner-Console-User-Server
  ```

- Check a rule set with `karabiner_cli --lint-complex-modifications` (in
  `/Library/Application Support/org.pqrs/Karabiner-Elements/bin/`); it expects
  a `{"title", "rules"}` file, not the full config.

## Clipboard (Maccy)

Maccy keeps a searchable clipboard history. Press `Cmd+Shift+C` (Maccy's
default) to open the picker, then type to fuzzy-search past copies.

| Action | Shortcut |
|---|---|
| Open clipboard history | `Cmd+Shift+C` |
| Pin / unpin an item | `Option+P` |
| Delete an item | `Option+Backspace` |

The global hotkey takes `Cmd+Shift+C` from every app, e.g. Chrome's "inspect
element" and VS Code's "open terminal". That's deliberate: the more common
`Cmd+Shift+V` is "paste without formatting" in Slack, Notion and Chrome, which
gets used far more. Settings are all Maccy's defaults, so
none are tracked; only "launch at login" needs setting once.

## Screenshots (Shottr)

Shottr replaces the built-in screenshot tool with annotation and OCR:

| Action | Shortcut |
|---|---|
| Capture area | Configure in Shottr preferences |
| Capture window | Configure in Shottr preferences |
| Scrolling capture | Configure in Shottr preferences |

After capture: annotate with arrows, boxes, blur, or text.
Use the OCR button to extract text from any screenshot.

### Adding a new layout

Edit `config/hammerspoon/init.lua` and bind a key to `tilePair(leftApp, rightApp)`.
Add each new app to `BUNDLE_IDS` with its bundle ID
(`osascript -e 'id of app "Figma"'`): apps are looked up by bundle ID, because a
name matches any process whose name contains it — Zoom runs a helper called
"zoom.us Sidebar Web Content" that a name lookup picked instead of Zoom, which
broke the Zoom layouts and mute. Bind through `bindHyper(key, section,
description, fn)` rather than `hs.hotkey.bind`, so the binding shows up in the
cheatsheet:

```lua
["Figma"] = "com.figma.Desktop",  -- in BUNDLE_IDS
bindHyper("g", "Layouts", "Figma | Chrome", function() tilePair("Figma", "Google Chrome") end)
```

Pick a key that isn't already bound — the bottom row `Z`/`X`/`C`/`V` holds the
existing layouts, `A`/`S`/`D`/`F` do single-window placement, `1`–`6` focus apps,
`M` mutes Zoom, `R` reloads, `Tab`/`Left`/`Right` move focus, `H`/`J`/`K`/`L` are
arrow keys in Karabiner, and `,`/`.`/`/` are reserved by macOS (see Ghostty
tabs above). Saving the file reloads Hammerspoon.

## Learning path

Week 1:
- Get used to the new prompt (starship) and colors (catppuccin)
- Use `cat`, `ls`, `ll` as normal — they're aliased to modern tools
- Practice `Ctrl+R` for fuzzy history search
- Type partial commands + Up arrow for filtered history

Week 2:
- Start using zoxide — just `cd` normally, it learns
- Try `rg "pattern"` instead of grep
- Open files with `vim` (aliased to nvim)
- Use `Ctrl+P` to find files, `Space f g` to search in files

Week 3:
- Explore LSP features: hover with `K`, go-to-definition with `gd`
- Try gitsigns: `]h` / `[h` to jump between changes, `Space h p` to preview
- Use `Space` to discover more keybindings via which-key
- Try `uv init` and `uv add` for a new Python project

Week 4:
- Get comfortable with format-on-save
- Try `mise` for project-specific Python/Node versions
- Customize — edit configs directly in `~/src/dotfiles/` (they're symlinked)
