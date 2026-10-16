# Productivity Guide

A reference for all the tools, shortcuts, and workflows in this setup.
Bookmark this and revisit as you get comfortable — don't try to learn
everything at once.

## Terminal (Ghostty)

| Action | Shortcut |
|---|---|
| New tab | `Cmd+T` |
| Split right / down | `Cmd+D` / `Cmd+Shift+D` |
| Navigate splits | `Cmd+Option+Arrow` |
| Zoom a split (toggle) | `Cmd+Shift+Enter` |
| Fullscreen | `Cmd+Enter` |
| Jump to previous / next prompt | `Cmd+Up` / `Cmd+Down` |
| Clear screen and scrollback | `Cmd+K` |
| Open a URL | `Cmd`+click |
| Quick terminal (global) | `` Ctrl+` `` |
| Find in scrollback | `Cmd+F` |
| Edit config | `Cmd+,` |
| Reload config | `Cmd+Shift+,` |
| Previous / next tab | `Hyper+,` / `Hyper+.` (Karabiner), `Ctrl+Shift+Tab` / `Ctrl+Tab`, or `Cmd+Shift+[` / `]` (U.S. layout only) |

The quick terminal is a system-wide dropdown terminal — press
`` Ctrl+` `` from any app to toggle it.

Prompt jumping (`Cmd+Up/Down`) needs shell integration, which is on: it scrolls
straight to the start of each command's output — the fastest way back through
a long build log or a Claude Code session.

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

## macOS settings

`./install.sh` writes these with `defaults write`:

| Setting | Value | Why |
|---|---|---|
| Accent / highlight color | Catppuccin mauve | Matches everything else |
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
| Keyboardio Model 100 | Any key (hold) | Chrysalis firmware |

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

### Cheatsheet

Holding Hyper alone for 1.2 s opens an overlay listing every binding below.
Quick chords never trigger it: any key pressed within 1.2 s cancels it. The list
is generated, not written by hand:

- Hammerspoon bindings come from `bindHyper(key, section, description, fn)` in
  `init.lua` — a binding made with plain `hs.hotkey.bind` won't appear.
- Karabiner remaps come from `karabiner.json` rule descriptions written as
  `[App: ]Hyper+<keys> → <action>`; a trailing `(…)` note is left out.

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
| Hyper + Left/Right | Focus window in that direction (MacBook arrow keys) |

### Layouts (Hammerspoon, bottom row)

| Shortcut | Layout |
|---|---|
| Hyper + Z | Coding — Ghostty left, Dia right |
| Hyper + X | Meeting + notes — Zoom left, Notion right |
| Hyper + C | Meeting + chat — Zoom left, Slack right |
| Hyper + V | Meeting + browsing — Zoom left, Dia right |

### App focus (Hammerspoon)

| Shortcut | App |
|---|---|
| Hyper + 1 | Ghostty |
| Hyper + 2 | Dia |
| Hyper + 3 | Chrome |
| Hyper + 4 | Slack |
| Hyper + 5 | Notion |
| Hyper + 6 | Zoom |

Press twice to maximize the focused app's window.

### Zoom (Hammerspoon)

| Shortcut | Action |
|---|---|
| Hyper + M | Toggle mute (works from any app, no focus switch) |

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
Use the app's exact name as macOS reports it (`Ghostty`, `zoom.us`, `Google Chrome`).
Bind through `bindHyper(key, section, description, fn)` rather than
`hs.hotkey.bind`, so the binding shows up in the cheatsheet:

```lua
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
