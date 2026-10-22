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
| Zoom a split (toggle) | `Alt+Z` (also `Cmd+Shift+Enter`); `Alt+H/J/K/L` while zoomed zooms the next split |
| Equalize splits | `Alt+=` |
| Fullscreen | `Cmd+Enter` |
| Jump to previous / next prompt | `Cmd+Up` / `Cmd+Down` |
| Clear screen and scrollback | `Cmd+K` |
| Open a URL | `Cmd`+click |
| Quick terminal (global) | `` Ctrl+` `` |
| Find in scrollback | `Cmd+F` |
| Command palette (every action, searchable) | `Cmd+Shift+P` |
| Edit config | `Cmd+,` |
| Reload config | `Cmd+Shift+,` |
| Previous / next tab | `Hyper+,` / `Hyper+.` (Karabiner; Model 100: also `Fn+,` / `Fn+.`), `Ctrl+Shift+Tab` / `Ctrl+Tab`, or `Cmd+Shift+[` / `]` (U.S. layout only) |
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
physical keys, so the Czech layout doesn't move them. Each `Alt` key is only
taken when there's a split in that direction; otherwise it goes through to the
program, so readline's `Alt+L` (lowercase the next word) still works in a
single pane or the rightmost split. The catch: these keys no longer show in
Ghostty's menu.

**Tabs move on the same keys they switch on:** `Hyper+,/.` switches tabs,
`Ctrl+,/.` moves the current one (wrapping at the ends). Nothing is given up:
a terminal has no control character for `,` or `.`, so programs in it never
receive these chords, and Ghostty's own `,` shortcuts are on Cmd.

Things to know:

- **Programs can write the clipboard, but reading it asks.** A program in the
  terminal reads the clipboard through an escape code (OSC 52), which Ghostty
  prompts for (`clipboard-read = ask`). With `allow` any program, a remote
  host over ssh, or escape codes hidden in a `cat`'d file could read it
  silently — and it often holds a 1Password secret. Writes stay allowed:
  remote Neovim and tmux copy through them.
- **A long command finishing in the background rings and notifies.** A
  command that ran 10 s or more and ends while Ghostty isn't focused bounces
  the dock icon, puts 🔔 in its tab title (no sound) and posts a banner. The
  banner needs Ghostty allowed in System Settings → Notifications; if it's
  off, Ghostty logs `Error while requesting notification authorization` and
  only the bell shows.
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

History keeps 100,000 lines with timestamps (`history | tail` shows when each
command ran). Every command is written to the file as it runs, and **Ctrl+R
searches every tab's commands**: it reads in what other tabs have run first.
Up-arrow sticks to this tab's own commands (until Ctrl+R pulls the others
in), so it doesn't jump between tabs. `~/.bashrc` only sources
`~/.bash_profile`: a non-login shell (typing `bash`, some editor terminals)
reads only `.bashrc`, and without it ran on bash's defaults — and on exit
trimmed the shared history file to 500 lines.

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
- **git** completes subcommands, branches, remotes and options (`git che` Tab,
  `git switch ma` Tab), plus `git lfs` subcommands. It's the completion that
  ships with the Command Line Tools for Apple's git, loaded on first use.

### Startup

A new tab's shell starts in ~70 ms (it was ~185; measure with
`hyperfine -N 'bash -lic exit'`). Three things keep it there:

- **Completions load on the first Tab**, not at startup. Homebrew puts each
  tool's completion in `etc/bash_completion.d`, which bash-completion would
  source in full (~50 files, ~70 ms). `bash_profile` points it elsewhere and
  wraps `_comp_load` — what bash-completion and fzf both call on a command's
  first Tab — to source that command's file then; files named differently
  from their command (`aws_bash_completer`, …) are mapped there. A new
  tool's completion needs nothing.
- **Tool init scripts are cached** in `~/.cache/bash-init` for fzf, starship
  and zoxide, and rebuilt when Homebrew installs a new version of the tool.
  If a prompt or key binding looks stale after changing one of these tools'
  setup, delete that file. mise isn't cached: its script embeds the PATH it
  was made with.
- **`brew shellenv` is written out** rather than run.

### Prompt (Starship)

Left to right: user and host, directory, git branch and status, language and
tool versions, battery, then the last command's time if it took over 3 s.
Segments that only appear when they matter:

- **`REBASING 2/5`** (also MERGING, CHERRY-PICKING, BISECTING) after the git
  status, while one is in progress — so a half-finished rebase isn't
  forgotten.
- **`✦`** after the duration when a job is in the background (`Ctrl+Z`,
  `cmd &`), with a count from two — so a suspended `nvim` isn't left behind.
- **`󱃾 <context> (<namespace>)`** in a directory with Kubernetes files
  (`Chart.yaml`, `kustomization.yaml`, `helmfile.yaml`, a `k8s/` or `charts/`
  folder, …): the cluster the next `kubectl`/`helm` will hit.

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

**`cd <fragment>` from anywhere** — no `cd ~/src/...` first:

```bash
cd dotfiles        # a directory in ~/src (or ~) by name, from anywhere
cd dot             # zoxide: the best-ranked directory matching "dot"
cd src dot         # several fragments, matched in order along the path
zi                 # interactive fuzzy picker over everything zoxide knows
cd -               # back to where you were
```

`cd` is zoxide's: it first tries a plain `cd`, which also looks in `~` and
`~/src` (`CDPATH`), so any project under `~/src` works by its full name even
before zoxide has seen it — it prints where it went. Otherwise zoxide picks,
among directories you've been to, the one you visit most and most recently
that matches the fragments. A
directory in the current one always wins, and `CDPATH` isn't exported, so
scripts' `cd` is unaffected.

### Modern CLI tools

Most are aliased over the defaults. Use them as you normally would:

```bash
cat file.py        # syntax-highlighted output (bat)
ls                 # icons + git status + grouped dirs (eza)
ll                 # detailed listing, with a git status column
lt                 # tree view (2 levels)
fd .json           # find files matching pattern — not aliased over find (different arguments)
rg "TODO"          # search file contents (ripgrep) — not aliased, use rg directly
du                 # visual disk usage (dust)
top                # process monitor (btop)
diff a.txt b.txt   # syntax-highlighted diff (delta)
glow README.md     # render markdown in terminal
tldr tar           # the handful of invocations you actually need (tlrc)
man rsync          # man pages are highlighted by bat (MANPAGER)
batgrep "TODO" src # rg results shown with bat, with context
batdiff            # git diff of the working tree, rendered by bat
just               # run a recipe from the project's justfile (lists them with `just --list`)
sd 'old' 'new' *.lua   # find-and-replace in files: ripgrep's regex, no sed -i quirks
tokei              # lines of code per language (code / comments / blanks)
hyperfine 'cmd1' 'cmd2'  # benchmark: many runs, mean ± spread, which is faster
```

`sd` is the replace half of `rg`: same regex syntax (no `\(` escaping), and it
edits in place the same way everywhere — `sed -i` takes different arguments on
macOS and Linux. `hyperfine` beats a single `time cmd`: it warms up, repeats
and reports the spread, so a 5 % difference is real or noise, not a guess.

`tldr` downloads its page cache on first use and refreshes it automatically.

### JSON processing (jq)

```bash
cat data.json | jq '.results[].name'    # extract nested fields
curl -s api/endpoint | jq '.'           # pretty-print JSON
jq -r '.[] | [.id, .name] | @csv' data.json  # convert to CSV
jless data.json                         # browse it: fold, search, copy a path
http GET api/endpoint | jless           # … or straight from httpie / curl
```

In `jless`: `j`/`k` move, `h`/`l` collapse/expand, `/` searches, `yp` copies
the path of the current node (`.results[3].name`) — paste it into `jq`.

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
- **mypy**: where a project runs it (`[tool.mypy]`, a `make` target, CI), the
  VS Code mypy extension shows the same errors live, from the project's own
  config — Pylance's checker doesn't report the same ones. Neovim leaves
  mypy to `make`.

## Editor (Neovim)

Plugins: LSP (basedpyright, ruff, ts_ls, yamlls, lua_ls, bashls, jsonls,
taplo, dockerls), blink.cmp, nvim-treesitter, fzf-lua, gitsigns, lualine,
indent-blankline, which-key, conform.nvim, nvim-lint, mini.surround,
mini.pairs, oil.nvim.

Mason installs the LSP servers, but treesitter parsers are compiled by the
`tree-sitter` CLI and conform/nvim-lint shell out to `prettier`, `eslint_d`
and `shfmt` — all of them come from the `Brewfile`, and `drift.sh` verifies
them.

Plugin versions are pinned in the tracked `config/nvim/lazy-lock.json`, and
nothing checks for updates in the background. To update: `:Lazy update`, try
it, commit the lock. If an update breaks something, `:Lazy restore` goes
back to the locked versions (after `git checkout` of the lock, to an older
one).

### Getting around

| Action | Keys |
|---|---|
| Find files (also `Space f f`) | `Ctrl+P` |
| Live grep (search in files) | `Space f g` |
| Grep the word under the cursor | `Space f w` |
| Changed files (git status, with diff preview) | `Space g s` |
| Commits (with diff preview) | `Space g c` |
| Switch buffers | `Space f b` |
| Recent files | `Space f r` |
| File symbols | `Space f s` |
| Diagnostics | `Space f d` |
| Help tags | `Space f h` |

**Tip:** Press `Space` and wait — which-key will show all available
bindings.

### Files (oil.nvim)

A directory opens as a buffer listing its files — **edit the list to change
the files**, then `:w`. Oil shows every change and asks before applying it.

| Action | Keys |
|---|---|
| Open the current file's folder (again: up a level) | `-` |
| Open a file or folder | `Enter` |
| Rename (type a path to move) | `ciw` |
| Delete (to the Trash) | `dd` |
| Copy / move to another folder | `yy` / `dd`, then `p` there |
| New file (end with `/` for a folder) | `o` + name |
| Apply changes | `:w` |

`nvim .` opens Oil instead of netrw. Hidden files are shown — dotfiles are
most of what gets edited here.

### LSP (code intelligence)

| Action | Keys |
|---|---|
| Go to definition | `gd` |
| Find references | `grr` |
| Go to implementation | `gri` |
| Type definition | `grt` |
| Rename symbol | `grn` |
| Code action | `gra` |
| Document symbols | `gO` |
| Hover docs | `K` |
| Signature help (insert mode) | `Ctrl+S` |
| Next / previous diagnostic | `]d` / `[d` |
| Show diagnostic under cursor | `Ctrl+W d` |

The diagnostic message for the cursor's line shows at its end; other lines
only have the sign in the gutter, so a file full of warnings stays readable.
Floats (hover, signature help, `Ctrl+W d`) have rounded borders.

All but `gd` are Neovim's own defaults (0.11+), so they work the same in any
Neovim. The config only adds `gd`: mapping `gr` or `gi` itself used to shadow
them — and `gi` is Vim's "go back to where you last typed".

Language servers install automatically via Mason on first use.
Run `:Mason` to see status. Configured servers:
- **Python**: basedpyright (type checking, open files only — like Pylance's
  default) + ruff (linting/formatting)
- **TypeScript**: ts_ls
- **YAML**: yamlls
- **Shell**: bashls (shellcheck's warnings inline)
- **JSON**: jsonls; **TOML**: taplo; **Dockerfile**: dockerls
- **Lua**: lua_ls. Each Lua tree says which Lua it is in a `.luarc.json`:
  `config/nvim` is LuaJIT with Neovim's runtime as a library (so `vim.*` has
  types), `config/hammerspoon` is Lua 5.4 with `hs` and `spoon` as globals.
  Without them lua_ls flagged every `hs` and `vim` as undefined.

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
| Taller / shorter split | `Ctrl+W +` / `-` |
| Wider / narrower split | `Ctrl+W >` / `<` |

`j` / `k` move by screen line through wrapped text, but with a count (`5j`)
by real lines — the ones the relative line numbers count. Ctrl+arrow resizing
isn't mapped: macOS takes Ctrl+←/→ to switch Spaces before Neovim sees them.

### Completion (blink.cmp)

| Action | Keys |
|---|---|
| Navigate popup | `Ctrl+N` / `Ctrl+P` |
| Accept selection | `Enter` (or `Ctrl+Y`) |
| Dismiss popup | `Ctrl+E` |

### Auto-formatting

Files are formatted on save:
- **Python**: ruff — safe fixes (e.g. unused imports removed), organize
  imports, format; the same as VS Code's on-save actions
- **TypeScript/JavaScript**: prettier
- **YAML/JSON/Markdown**: prettier
- **Shell scripts**: shfmt, 4-space indent with `case` branches indented
  (`-ci`). It also splits `{ …; exit 1; }` one-liners and drops column
  alignment, so the first save of an older script reformats more than the
  lines touched — commit that separately if the diff matters.
- **TOML**: taplo (through the language server)

## VS Code

Settings are symlinked from the dotfiles repo. Key features:

- **Catppuccin Mocha** theme + icons (matches terminal)
- **Maple Mono NF** font with ligatures
- **Python**: Pylance (type checking) + Ruff (lint, fixes, imports, format on
  save) + mypy where the project uses it
- **TypeScript/JS/YAML/JSON/Markdown**: Prettier (format on save); YAML also
  validated against its schema (GitHub Actions, compose, Kubernetes)
- **Shell**: ShellCheck as you type, shfmt on save (4 spaces, `-ci`, as in
  Neovim); **TOML**: Taplo (even-better-toml) on save
- **Makefiles**, **SQLite** files and **containers** (Container Tools,
  Dev Containers) have their extensions; telemetry is off
- **Auto-save** on focus change
- **Claude Code** in panel mode

Extensions are managed via `config/vscode/extensions.txt` and installed
by `./install.sh`. `./drift.sh` reports both missing and extra ones — an
extension installed from a recommendation prompt shows up as extra until
it's listed or uninstalled. Dependencies of listed extensions (Jupyter's
helpers, the Python extension's) don't count.

## Claude Code

`install.sh` runs `config/claude/bootstrap.sh`: it merges
`settings.base.json` into `~/.claude/settings.json` (auto mode, the status
line, …) and installs the plugin set. `drift.sh` reports a base setting that
has gone missing.

- **Plugins, kept lean:** superpowers (the workflow: brainstorm, plan, TDD,
  debugging, review), frontend-design, context7, claude-md-management,
  security-guidance and three LSP plugins. Every skill Claude can trigger
  costs context on each turn, and overlapping ones make it pick the wrong
  one — so feature-dev and commit-commands, which duplicated superpowers, are
  out. Matt Pocock's `mattpocock-skills` (official marketplace) is the leaner
  alternative to superpowers; they overlap almost entirely, so one, not both.
  Built in already: `/code-review`, `/simplify`, `/security-review`.
- **LSP plugins** (`pyright-lsp`, `typescript-lsp`, `lua-lsp`) give Claude
  diagnostics after each edit, go-to-definition and references. They launch
  `pyright-langserver`, `typescript-language-server` and
  `lua-language-server` from PATH — all in the Brewfile; without them the
  plugins silently do nothing. The TypeScript one needs the project's own
  `typescript` in `node_modules`; Lua reads each tree's `.luarc.json`. A
  repo's `.luarc.json` can name a Lua `runtime.plugin` for the server to run:
  through Claude Code's plugin it isn't loaded, and Neovim's lua_ls asks
  first (both tested); only `lua-language-server --check` runs it unasked, so
  don't use that on a repo you don't trust.
- **No Bash sandbox** (`sandbox.enabled`). It confines Claude's shell commands
  to writes in the project and `$TMPDIR`, and network to allowed hosts. Here
  it would break most of what Claude runs — git over SSH, `gh`/`glab`,
  `brew`, `docker`, `open`/`osascript`, `hs`, anything writing to `~/.cache`
  or `~/Library` — and by default a blocked command is simply retried outside
  it (auto mode's classifier approves that), so it adds little. Reads stay
  open either way (`~/.ssh` included). Worth it per project when Claude will
  run code you don't trust: `/sandbox` there (saves to that repo's
  `.claude/settings.local.json`), with `allowUnsandboxedCommands: false` and
  `failIfUnavailable: true` to make it binding.

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
| Switch to any window, with previews (AltTab) | `Cmd+Tab` (keep Cmd held: Tab / Shift+Tab to move, release to pick) |
| Switch between the current app's windows (AltTab) | ``Cmd+` `` |
| Show / hide dotfiles in Finder and open/save dialogs | `Cmd+Shift+.` |
| Type a path in Finder or any open/save dialog | `Cmd+Shift+G` |
| Move a file (cut + paste) in Finder | `Cmd+C`, then `Cmd+Option+V` |
| Emoji and symbol picker | `Cmd+Ctrl+Space` |
| Lock the screen | `Cmd+Ctrl+Q` |
| Keep the Mac awake (no sleep, screen stays on) | Click the cup in the menubar (KeepingYouAwake), or Hyper+0 |

**AltTab** replaces both of macOS's switchers. macOS's Cmd+Tab picks an
*app* and brings all its windows; AltTab picks a *window* — every window of
every app, minimized and other-Space ones included, with a thumbnail. Cmd+`
does the same for the front app's windows only. Its two shortcuts live in
`DEFAULTS` (`lib/links.sh`) as AltTab's own archived shortcut values; the
second one needs AltTab Pro (licensed here). Change them in AltTab's settings,
then copy them back with `defaults export com.lwouis.alt-tab-macos -`.
Hammerspoon's `hs.window.switcher` would be the in-repo alternative, but it's
slow with many windows and has no live previews.

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
| `lowpoly-2420x2420.png` / `lowpoly-home-2420x2420.png` | iPad Pro 11" (2024) lock / home screen. Square, the screen's long side (2420 × 1668): iPadOS turns the wallpaper with the device, so it has to fill portrait and landscape |

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

## Menu bar icons (Thaw)

[Thaw](https://github.com/thaw-app/Thaw) keeps the menu bar short: icons sit in
three sections — **Visible**, **Hidden** (shown when you click Thaw's icon) and
**Always-Hidden** (only in Thaw's own bar). Drag icons between them in Thaw's
settings; new apps land in Hidden.

- Why Thaw: a free, open-source, actively maintained fork of Ice (abandoned
  since late 2024). It replaced Bartender, which is paid.
- It needs **Accessibility** and **Screen Recording** — it reads the menu bar
  icons to manage them. Launch at login is its own setting.
- Leave its menu bar appearance options off: the black band is Hammerspoon's
  (above), and two tools drawing there fight.

**The layout lives in a file:** `config/thaw/layout`, one icon per line under
`[visible]`, `[hidden]` and `[always-hidden]`, left to right. Work-only icons
(the IT agents) go in the untracked `~/.config/thaw/layout.local`, same
format, so they stay out of this public repo. They land at the left end of
their section unless the line says where: `<id> after <other id>` (what
`--capture` writes for a work icon sitting among the others).

| Command | Does |
|---|---|
| `thaw-layout` | Compares the file with Thaw, in exact order in every section: the display's profile, and where each icon actually is on screen. Exits 1 on any difference; `drift.sh` runs it |
| `thaw-layout --apply` | Writes the file into Thaw's profile and preferences — quits and relaunches it — then checks every icon landed. Refuses on the built-in display unless `--force` |
| `thaw-layout --capture` | The other way: after dragging icons and Profiles → Update, writes the display's profile into the files (local icons stay local; it names anything new so you can move work-only ones) |

How it works: each display's profile
(`~/Library/Application Support/Thaw/Profiles/<id>.json`, `itemOrder`) holds
the layout Thaw restores. Its `savedSectionOrder` — in the preferences and in
each profile — lags behind the screen, which is why `thaw-layout` reads the
profile instead: comparing against `savedSectionOrder` failed even with
every icon in place. Where icons are is read back through each app's
accessibility tree via `hs` — Thaw's three icons are the section dividers.

Two limits are Thaw's. It restores which section an icon is in, **not the
order within a section**, so `--apply` can't reorder: drag in Thaw's
settings, Profiles → Update, then `--capture`. And it won't move an icon
*into* Visible from a collapsed section (its log says "skipping the
visible-bound move … parked offscreen"); drag that one too. Moves between
sections otherwise work.

**Per-display profiles.** Thaw switches layout by display (Settings →
Profiles → Auto-Switch): **Dell** is the full layout; **MacBook** moves
Weather to Always-Hidden, so more icons fit beside the notch.

- Icon spacing is 6 pt tighter than macOS's default — on **both** displays, on
  purpose. It's macOS's `NSStatusItemSpacing` (16 by default, 10 here), which
  is system-wide and read only when an app starts: different spacing per
  display would make Thaw relaunch every app with a menu bar icon on each
  plug and unplug — Zoom mid-call included. The same value means a switch
  changes nothing.
- A profile only knows displays Thaw has seen, so set one up while on that
  screen: arrange, set the spacing (Displays), then Profiles → Update.
- `config/thaw/layout` is the default (Dell) layout. On the MacBook's own
  display `thaw-layout` doesn't compare (the MacBook profile differs on
  purpose, Weather included), and `--apply` refuses: it would overwrite that
  profile until the next display switch.
- KeepingYouAwake is Visible: its cup shows at a glance whether the Mac is
  being kept awake (Hyper+0 toggles it).
- **Before macOS 27:** the menu bar changes there broke this whole class of
  tool; Thaw's 27 support is in its 3.0 betas (`thaw@beta`). Check the black
  band still works afterwards too.

## macOS settings

`./install.sh` writes these with `defaults write`, from the `DEFAULTS` list in
`lib/links.sh`; `./drift.sh` reports any that changed — macOS updates reset
settings without saying so. (Touch ID for `sudo` is a file, checked separately.)

| Setting | Value | Why |
|---|---|---|
| Accent / highlight color | Catppuccin mauve | Matches everything else; contrasts with the blue-teal wallpaper the way Catppuccin apps use it |
| Appearance | Dark, dark-style app icons | Icons keep their own colors so apps stay recognizable |
| Wallpaper tinting in windows | On | With the blue-teal wallpaper, Finder and System Settings get a faint blue cast, closer to Catppuccin's base than neutral grey |
| Key repeat | 30 ms, 225 ms initial delay | Fastest the System Settings sliders allow; Hyper+HJKL and CapsLock Backspace rely on it |
| Press-and-hold | Off | Holding a letter repeats it instead of opening the accent picker |
| File extensions in Finder | Always shown | |
| Dock | Right edge, auto-hide, 0.2 s delay, quick slide, no magnification | A bottom Dock popped up over Zoom's toolbar on overshoot. The short delay keeps it from covering controls near the right edge, like Slack's thread close button |
| Dock contents | The apps in `DOCK` (`lib/links.sh`), in that order, then Downloads (fan, newest first) | `install.sh` rebuilds the Dock from the list with `dockutil`, skipping apps that aren't installed, so work-only apps just don't appear on a personal Mac. `drift.sh` flags an icon an app install or macOS update added. To change the order, edit `DOCK`, not the Dock: rerunning `install.sh` would undo a drag |
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

## Updates

Two halves: what can run unattended does, weekly; the rest is one command,
with a reminder.

| What | How | When |
|---|---|---|
| Homebrew formulae, and claude-code | `brew-autoupdate`, a launchd agent | Mondays 9:30 (missed: at the next wake) |
| Neovim plugins, parsers, Mason servers · mise runtimes · App Store · other casks | `dotfiles-update` | when `drift.sh` says it's due (14 days) |

- **Unattended:** `brew update`, every outdated formula, and the casks in
  `AUTO_CASKS` (claude-code). The log is `~/Library/Logs/brew-autoupdate.log`;
  only a failure posts a notification. Most casks update themselves (Sparkle),
  and the rest can need sudo or quit the app, so they wait for
  `dotfiles-update`, which asks per cask. `brew pin <formula>` holds one back.
- **`dotfiles-update`** runs the Homebrew step too, then `mise upgrade`,
  `mas upgrade` and the Neovim updates, and checks Neovim afterwards: no
  startup errors, lua_ls and basedpyright attach, treesitter highlights. If
  that passes, the `lazy-lock.json` change is left to review and commit; if
  not, the lock is put back and `:Lazy restore` returns every plugin to it.
  `--no-casks` skips the cask questions.
- **`drift.sh`** reports the agent missing, or no successful run in 10 days
  (it failing every week, say), and says when `dotfiles-update` is due.
- A formula that builds from source can fail where bottles don't: proxmark3's
  tap detects Python 3.15 but declares 3.14, so its upgrade fails until the
  tap is fixed — and with it the weekly run's success, which `drift.sh` will
  flag.

## Git

### Delta pager

All git diffs are syntax-highlighted with line numbers. Navigation:

| Action | Keys |
|---|---|
| Next file | `n` |
| Previous file | `N` |
| Quit | `q` |

### Structural diffs and fixups

```bash
git dft              # structural diff of the working tree (difftastic)
git dft main         # … against a branch; any `git diff` arguments work
git absorb --and-rebase   # fold your fixes into the commits they belong to
```

- **`git dft`** is `git difftool` with **difftastic**, which compares syntax
  trees instead of lines: reformatting, re-indenting and re-wrapping don't
  show as changes, and moved code reads as moved. Use it when a refactor's
  `git diff` is a wall of red and green. delta stays the pager for `git diff`,
  `log` and `show` — difftastic is the second opinion, not the default.
- **`git absorb`** answers PR review the clean way: fix the comments, then
  `git absorb --and-rebase` works out which earlier commit each changed hunk
  belongs to, makes `fixup!` commits for them and squashes them in. With
  nothing staged it takes every change in the working tree. Hunks it can't
  place unambiguously stay as uncommitted changes, so check `git status`.
  Its commits skip the pre-commit secret scan (it doesn't run `git commit`);
  the global pre-push hook scans them before they leave the machine.

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

### Hooks

Every repo runs the global hooks in `config/git/hooks` (`core.hooksPath`):
gitleaks scans staged changes on commit and every outgoing commit on push,
and git-lfs gets its hooks. Each hook name there links to one script,
`dispatch`, which runs the global part (`config/git/hooks.d/<name>`) and then
the repo's own `.git/hooks/<name>` — so a repo's `commit-msg`,
`prepare-commit-msg`, `post-checkout` or pre-commit-framework hooks still run.
A failing global or repo hook stops the commit or push as usual.

- **The pre-commit framework** refuses to install while `core.hooksPath` is
  set. Hide it for that one command, then the dispatcher runs the hook:
  `GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.hooksPath GIT_CONFIG_VALUE_0= pre-commit install`
  (`git -c` can't do it: `pre-commit` isn't a git subcommand).
- **Not dispatched:** `reference-transaction` and `post-index-change`, which
  fire on nearly every git operation. A repo that sets its own
  `core.hooksPath` (Husky, lefthook) bypasses all of this, gitleaks included.

### Background maintenance

`git maintenance` keeps the repos you work in fresh from launchd: an hourly
prefetch (so `git pull` has little left to download) and commit-graph and
repack upkeep. Register a repo with

```bash
git -C <repo> maintenance register --config-file ~/.gitconfig.local
```

`--config-file` matters: without it, `register` and `start` write the repo's
absolute path into `--global` — the tracked `gitconfig`. List what's
registered with `git config --get-all maintenance.repo`. The launchd agents
(`git maintenance start`, once per machine) are already installed here.

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
- **`rebase.updateRefs`** — stacked branches: rebasing the top branch also
  moves every branch that points into it, so `feat1` → `feat2` stays a stack
- **`push.useForceIfIncludes`** — `git push --force-with-lease` also refuses
  when the remote has commits you fetched but never integrated; a background
  fetch (lazygit, VS Code) otherwise quietly updates the lease
- **`tag.sort = version:refname`** — `git tag` lists `v1.9` before `v1.10`
- **Global ignore** (`config/git/ignore`, linked to `~/.config/git/ignore`):
  only what no repo should ever track — `.DS_Store`, Claude Code's personal
  `.claude/settings.local.json`. Project patterns belong in each `.gitignore`.
- **`diff.mnemonicPrefix`** — paths in raw diffs say what's compared: `i/`
  index, `w/` working tree, `c/` commit, instead of `a/` and `b/` (delta's
  file headers strip them either way)

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

### The key: passphrase in the Keychain, commits signed

`~/.ssh/id_ed25519` keeps its passphrase, which lives in the login keychain:
`UseKeychain yes` loads the key after a reboot without asking. Store it once
with `ssh-add --apple-use-keychain ~/.ssh/id_ed25519` (in a terminal: it asks
for the passphrase).

Every commit and tag is **signed with the same key** (`gpg.format = ssh`,
`commit.gpgsign`), so they show **Verified** on GitHub and GitLab — once the
public key is uploaded there *as a signing key* (separate from the login key):

| Where | How |
|---|---|
| GitHub | `gh ssh-key add ~/.ssh/id_ed25519.pub --type signing` (needs `gh auth refresh -s admin:ssh_signing_key` once) |
| GitLab | Profile → SSH Keys → the key → usage *Authentication & Signing* |
| Check locally | `git log --show-signature -1` — verified against `~/.ssh/allowed_signers` |
| New machine | `user.signingkey = ~/.ssh/id_ed25519.pub` (full path) in `~/.gitconfig.local`, and an `allowed_signers` line: `<email> namespaces="git" <public key>` |

**Work repos get the work email by folder, not per repo.** In
`~/.gitconfig.local` (untracked, so the folder name stays out of this repo):

```ini
[includeIf "gitdir:~/work/"]
    path = ~/.gitconfig.work      # [user] email = you@company.com
```

Every repo under that folder — current and future clones — commits with the
work email and signs with the same SSH key; everything else stays personal.
Don't set `user.email` or signing in a repo's own `.git/config`: it wins over
the rule, silently. Add the work email to `~/.ssh/allowed_signers` too, for
local verification. GitLab shows Verified when the commit email is one
verified on that GitLab account.

Why not 1Password's SSH agent: with the lid closed (no Touch ID) and no Apple
Watch, each approval means typing the 1Password password.

### GnuPG: the PIN comes from a dialog, not the terminal

gpg asks for the passphrase or YubiKey PIN through gpg-agent, which shows
**pinentry-mac** (`config/gnupg/gpg-agent.conf`). That's what lets gpg run
where there is no terminal — scripts, password helpers such as an Ansible
vault script, Claude Code's shell.

**Never put `pinentry-mode loopback` in `gpg.conf`.** Loopback makes gpg read
the PIN from its own terminal instead of asking the agent, so every caller
without one fails with `gpg: cannot open '/dev/tty': Device not configured`
(and may then hang).

Over SSH, where no dialog can appear, opt into loopback for one command — the
agent allows it (`allow-loopback-pinentry`):

```bash
gpg --pinentry-mode loopback --clearsign file.txt
```

After editing either file, `gpgconf --kill gpg-agent`; the agent restarts on
the next gpg call. Only `gpg.conf` and `gpg-agent.conf` are linked:
`common.conf` (`use-keyboxd`) is gpg's own. `install.sh` keeps `~/.gnupg` at
700 — anything looser makes gpg warn about unsafe permissions.

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
| Tap (any number of times), then press again within 300 ms and hold | Repeating Backspace |

Holding CapsLock and letting go without pressing anything sends nothing once
250 ms have passed, so an abandoned Hyper chord doesn't delete a character.
The catch: a Hyper chord started within 300 ms of a Backspace tap becomes
Backspace instead (typing any other key in between resets it). Each tap stores
an expiry time (`caps_lock_tap_until`, compared with `system.now.milliseconds`)
rather than starting a timer: Karabiner's delayed actions run from the
*press* and an earlier tap's timer outlived a later tap, so the old rule gave a
~150 ms window and lost the repeat after two quick taps.

Karabiner lets go of the keyboard at sleep and grabs it again only a few
seconds after wake, so CapsLock pressed in that gap — a Hyper chord the
moment the lid opens — is a real Caps Lock and the light comes on.
Hammerspoon turns Caps Lock off a second after every unlock (nothing in this
setup wants it on); one pressed after that point is remapped as usual.

### Keyboardio Model 100

The keymap lives in the keyboard itself (Kaleidoscope firmware, edited with
Chrysalis), so it works on any computer without Karabiner. Keys that matter
here, layer 0:

| Key | Sends | Does |
|---|---|---|
| Right palm key (Fn) | Holds the **Hyper layer**, where every key sends Hyper + itself | Hyper, held — and the keys light up by what they do |
| Butterfly | `Cmd+Shift+4` | Shottr area capture (its hotkey; macOS's own `Cmd+Shift+4` is off) |
| Any | `F18` (custom code 109) | Zoom mute (Hammerspoon binds F18) |
| Prog | `F19` (custom code 110) | Messages show / hide (Hammerspoon binds F19) |
| Left palm key (Fn) | Holds the **Function layer** (below) | F-keys, arrows, brackets, media, tabs |

The **Function layer** (hold the left palm key):

| Keys | Fn gives |
|---|---|
| 1–0, Num, `=` | F1–F12 |
| H J K L | ← ↓ ↑ → |
| U I · O P · `/` `-` | `{` `}` · `[` `]` · `\` `\|` — the base layer has no `[ ] \` keys |
| W / S · X | Volume up / down · Mute |
| A / D · F | Previous / next track · Play/Pause |
| `,` / `.` | Previous / next tab (sends Hyper+`,` / `.`) |
| `` ` `` · ⌫ | Tab · Forward delete |

The media keys sit on WASD by direction (up/down is volume, left/right the
track, X under S mutes), where the stock layer had mouse keys; the stock
row N M `,` (mute, down, up) gave no hint which key went which way. Also
dropped from the stock layer, as useless with a trackpad on a Mac: mouse
keys and pointer warp, Home/End (they scroll rather than move the cursor),
Print Screen, Insert, Caps Lock, Fn+Space = Enter and the Menu key (it
opens the window's menu, not the selection's). **Fn+`,`/`.` are the tab
keys as a two-hand chord**: Hyper is the right palm, the same hand as `,` and
`.`, while Fn is the left. They send Hyper+`,`/`.`, so the Karabiner rule
(Tabs, below) still does the rest. These changes are `FN_KEYS` in
`keyboardio-layers`: change those keys there, not in Chrysalis — the next
`--apply` writes them back.

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
  | `,` `.` — previous / next tab | white |
  | 1–6 — apps, each in its own color | Ghostty mauve (its Catppuccin accent), Dia yellow, Chrome green, Slack pink, Notion white, Zoom blue |
  | Z X C V — layouts · ` ; Tab Q A S D E F G, left thumb arrows — windows | mauve · blue |
  | T Messages · M Return — Zoom mute, join | teal · red |
  | 0 — keep awake | yellow |
  | Space — launcher | green (like the app keys) |

- **Function** / **Numpad** — only their own keys lit, by kind: F-keys pink,
  arrows sky, volume blue, the other media keys yellow, mouse keys green, brackets orange, editing and
  navigation lavender, the Fn layer's tab keys white; digits green, operators
  yellow. The key that gets you back out of a layer stays white.

The Numpad is on **layer 4**, not the stock layer 1: the firmware's stock NumPad
plugin is tied to layer 1 and, while it's active, forces the number keys to its
own color (off here), so the color map can't light them. Layer 1 is left empty.

Only **16 colors** are usable: the color map stores 4 bits per key, even though
the palette holds 24. `keyboardio-layers` refuses to go past index 15. That's
why some keys share a color where they never sit side by side (Slack and
forward delete, Zoom and the window keys, the tab keys and the Hyper key).

The color map is indexed by LED, not by key — the LEDs are wired in a different
order (the table is in `keyboardio-layers`, the same one Chrysalis uses).
`keyboardio-layers` generates all of this from the dotfiles — the Hyper layer
from the base layer, its colors from the live cheatsheet data — so **after
adding or moving a Hyper binding, run `keyboardio-layers --apply`, then
`keyboardio-backup`** and commit. Without `--apply` it only prints what would
change. It writes over the same protocol Chrysalis uses and reads every value
back. Before writing it snapshots everything it is about to change, so a
timeout halfway through or a value that doesn't read back puts the keyboard
back as it was rather than half-written. Only if that restore fails too does
it fall back to the committed backup: `keyboardio-backup --restore`. A write cut
short is worse than it looks: the firmware keeps parsing numbers across the
newline, zero-filling each missing one after a second, and reads the next
command as more data, so the restore first floods it with filler to finish
that parse.

The base layer has no arrow keys, so on the Hyper layer the **left thumb arc
sends the four Hyper+arrows**, outer to inner: Ctrl ↑ (reading frame),
Backspace ↓ (restore), Cmd ← and Shift → (focus left / right half). The
modifiers are idle during a Hyper chord anyway — Hyper already holds every
one. Backspace gives up Hyper+⌫ (forward delete) on this keyboard; forward
delete stays on Fn+Backspace. This is an override in `keyboardio-layers`
(`THUMB_ARROWS`); everything else on the layer is generated from the base
layer.

Two consequences of Hyper being a layer here: holding Hyper *alone* sends
nothing, so the on-screen cheatsheet only opens from the MacBook's Caps Lock
(the lit keyboard replaces it); and Hyper + mouse click doesn't exist on the
Model 100.

**Back it up after every change in Chrysalis:** quit Chrysalis (it holds the
serial port), run `keyboardio-backup`, and commit `config/keyboardio/model100.json`.
The script asks the keyboard over the same protocol Chrysalis uses (read-only)
for an allow list: the settings Chrysalis itself backs up and restores, plus
the facts it records with them (firmware version, plugins). Not the raw
`eeprom.contents` dump, which Chrysalis's export drops too — restoring it
would rewrite every byte. A firmware command that's on neither list is
printed, so a new plugin's settings can't go unsaved quietly.

**Restore with `keyboardio-backup --restore`** (or `--restore other.json`):
it writes each setting back and reads it back to verify; if a write is cut
short it resyncs the keyboard and stops — run it again. Not with Chrysalis:
the file is the format Chrysalis saves before a firmware update, but its
"Restore from file" only reads its own export format (and only the layout),
and the backups list isn't shown in 0.13. The
lock works both ways: the scripts find the keyboard by Keyboardio's USB vendor
ID (not just the first `/dev/cu.usbmodem*`) and open it exclusively, so
Chrysalis can't connect while one is running. Chrysalis
only backs up by itself before a firmware update, which is why its last one
predated the Hyper and butterfly keys.

### Model 100 at a glance

What's different on the Model 100, at a glance (the printed cheatsheet's
Hyper page carries this table):

| Keys | Does |
|---|---|
| R palm | Hold: Hyper (the Hyper layer, every key sends Hyper + itself) |
| L thumb | With Hyper: Ctrl ↑ reading frame · ⌫ ↓ undo · Cmd ← · Shift → focus a half |
| R Shift | With Hyper + a nav key: select while moving |
| Fn+⌫ | Forward delete — Fn is the left palm key (Hyper+⌫ is ↓ here) |
| Fn+W S X | Volume up · down · mute (A D F: track back · forward · play) |
| Fn+, . | Previous / next tab, two-handed |
| Butterfly | Shottr area capture |
| Num | Numpad layer on / off |

Any (Zoom mute) and Prog (Messages) are on the Hyper page already, with
their sections.

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

The cheatsheet uses as few side-by-side panels as fit the screen's height —
one on the 5K, two on the MacBook. Sections are never split: each panel takes
whole sections in order, balanced by line count. `hyper-cheatsheet --readme`
renders on the current display, so the README image shows that display's
layout.

### Printable cheatsheet

`hyper-cheatsheet` writes an A4 landscape PDF to `~/Desktop/hyper-cheatsheet.pdf`
(or a path you pass), for the desk — shortcuts to pick up a few at a time:

1. **Hyper** — every Hyper binding, asked live from Hammerspoon (exactly what
   the hold-Hyper overlay shows).
2. **Keyboard** — this guide's Ghostty, readline, fzf, "Text editing
   everywhere" and "macOS essentials" tables.
3. **Neovim** — the Neovim section's tables: finding things, oil, LSP,
   editing, gitsigns, completion.

Nothing is listed by hand: pages 2 and 3 are parsed from this file, so editing a table
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
| Hyper + Backspace | Forward delete (Model 100: Fn+Backspace — its Hyper+Backspace is ↓) |
| Hyper + **right Shift** + any of the above but Backspace | The same, selecting (Shift+arrow, Shift+Cmd+←, …) |

Works system-wide: Slack, Notion, Chrome, Ghostty, etc.

O/P send Cmd+Left/Right rather than Home/End: in most Mac apps Home/End scroll to
the top or bottom of the document instead of moving within the line. In
Ghostty, Cmd+Left/Right and Option+Left/Right are already mapped to the shell's
line-start/end and word motions, so the whole layer works in the terminal too.
Two catches. **Inside Neovim** (in Ghostty) those same bytes are Neovim keys:
Hyper+O arrives as `Ctrl-A`, which *increments the number under the cursor*,
and Hyper+P as `Ctrl-E` (scroll one line) — use `0`/`^` and `$` there. And the
**Model 100's** Hyper+H/J/K/L… are Karabiner's, not the keyboard's: on a Mac
without Karabiner (or another computer) they're plain Hyper chords. The
MacBook's keyboard is ANSI (`ioreg` reports StandardType 0, U.S.), matching
Karabiner's `keyboard_type_v2`, so `` ` `` and `§` aren't swapped.
Selecting needs a second Shift: Hyper already holds (left) Shift, so the
select variants trigger on **right** Shift added to the chord — on the Model
100 the right-thumb Shift, which stays a Shift on the Hyper layer. On the
MacBook, right ⌘ works too (right Shift is a stretch with Caps Lock held).

### Tabs (Karabiner)

| Shortcut | Action |
|---|---|
| Hyper + , | Previous tab |
| Hyper + . | Next tab |

In every app: Ghostty, Chrome, Dia, Safari, Finder, VS Code (where Ctrl+Tab
cycles recent editors). On the Model 100, Fn+`,` / `.` send the same chords
from the other hand (see the Function layer). These have to live in Karabiner: macOS reserves
`Hyper+,`, `Hyper+.` and `Hyper+/` for sysdiagnose (a ~400 MB archive in
`/private/var/tmp`) and swallows them before any app sees them. Karabiner runs
first and rewrites them to `Ctrl+Shift+Tab` / `Ctrl+Tab` — not `Cmd+Shift+[` /
`]`, because on the Czech layout that physical key types `ú` and the shortcut
no longer matches. `Hyper+/` is swallowed, so a stray press no longer starts a
sysdiagnose.

### Window management (Hammerspoon)

| Shortcut | Action |
|---|---|
| Hyper + A | Tile window left, at the screen's split (a half if nothing's docked); again: ½, ⅔, ⅓ of the width (the split follows) |
| Hyper + S | Maximize window (no fullscreen); again: back where it was |
| Hyper + D | Tile window right, at the screen's split; again: ½, ⅔, ⅓ |
| Hyper + R | Move the split: 50 → 67 → 33 % (left side's share); every docked window follows. MacBook: 50 → 60 → 40 |
| Hyper + F | Toggle native fullscreen |
| Hyper + E | Swap the two sides, each keeping its width (the focused window keeps focus) |
| Hyper + Up | Reading frame: centered, ⅔ wide, full height; again: maximize. On the MacBook's screen: maximize (Model 100: left thumb Ctrl) |
| Hyper + Down | Undo the last move — every window it moved (both halves of a layout); again: redo (Model 100: left thumb Backspace) |
| Hyper + Tab | Toggle focus between left/right windows; nothing tiled, or the other half empty: the next window down |
| Hyper + Left/Right | Focus window in that direction (MacBook arrows; Model 100: left thumb Cmd / Shift) |
| Hyper + ` (or ;) | Cycle the windows stacked on this half (or at this spot) |
| Hyper + G | Pick any window from a list, typing part of its app or title |
| Hyper + Q | Hide the front app (like `Cmd+H`); focus returns to the previous app |

**Splits (Hyper+R, Hyper+A/D again).** Hyper+R moves the split between the
two sides to the next step after the nearest one, so a window dragged by hand
joins the cycle too. A second Hyper+A or Hyper+D on a window already docked
on that side steps *its own* width ½ → ⅔ → ⅓ (Rectangle's convention), so A
always resizes the left window and D the right one, while R steps the divider
the same way whichever side you're on. Both move the split the same way.

**One split per screen.** Every window *docked* on the screen moves with the
split — full height, flush with a screen edge, at any width: the window on
the other side, everything stacked behind either (Hyper+` only cycles
windows that share a frame), and windows left at an older split. Without
that last part, a 50/50 pair under a 33/66 one came back at 50/50 when
you switched to it. Undo is one Hyper+Down for all of them. Maximized and
floating windows aren't docked and stay put. Windows of hidden or minimized
apps aren't visible to Hammerspoon, so they keep their old width until the
next split move. A visible Messages float is docked too, and moves with the
split. Thirds only on the Dell — 60 % next to 67 % was
too close to tell apart. The MacBook uses 60/40 instead: a third there is
~500 pt, narrower than Messages or Slack will go. Hyper+E keeps the split
consistent too: the pair swaps sides and widths, and what's stacked behind
each side moves to the new split.

**Gaps and the focused-window border.** JankyBorders (`borders`, a login
service) draws a 6 pt Catppuccin blue border around the focused window —
macOS itself only darkens the title bar a little. It draws *outside* the
window, so a window flush with a screen edge lost that side of it: every
window placed here keeps 8 pt from the screen's edges (`GAP` in `init.lua`).
There's no gap between the two sides of a split. A gap there would show a
strip of whatever is underneath, and a maximized window under a pair stays
hidden only because both cover exactly the same rect. On that side the
focused window's border lies over its neighbour's edge instead. Colors and
width are in `config/borders/bordersrc`; after editing it, run it
(`~/.config/borders/bordersrc`) to update the running border. Off for a
while: `brew services stop borders`.

borders is patched (`Formula/borders.rb`) so it stays out of Zoom's share
picker. Each border is a separate window, and Zoom's "Windows" list used to
show a blank "borders" tile for every open window. Zoom lists only windows
on the normal layer and ignores whether a window allows capture, so the
patch moves the borders one layer up. The catch: a border now draws *over*
a window that covers its target, where it used to stay underneath, which
the tiled layouts rarely produce. The patch also turns off capture for the
border windows, so the border doesn't show up in screenshots, recordings
or a full-screen share. Viewers see your windows without it.

That's why the Brewfile takes borders from this repo instead of
felixkratz's tap. It taps the repo by its local path (`jbrunclik/dotfiles`),
so a *committed* formula change arrives with the next `brew update`
(uncommitted edits don't). Then run `brew reinstall borders`. Homebrew
loads a non-official tap only once trusted, so `install.sh` runs
`brew trust --tap jbrunclik/dotfiles`. Upstream releases don't arrive by
themselves: to move to a new one, bump `url` and `sha256` in the formula,
and if the patch no longer applies, regenerate it against the new tag.

The rest of the window keys follow the split instead of assuming halves.
Anything placed on a side takes **the screen's split**: the split of the
topmost docked window, or a half when nothing's docked. That covers a first
Hyper+A/D, a layout (Hyper+Z…), "beside" next to a maximized window, Hyper+S
again, and Hyper+E with one side empty. "Beside" next to a docked window (a
second Hyper+1–6 press, launcher Shift+key) takes the rest of its split. A
layout's second press still cycles focus, and Hyper+Tab / Left / Right go by each window's
**centre**: a two-thirds window flush right is a right window, though its
left edge is past the middle (the MacBook messenger float). One definition
— `dockedSide`, `sideOf`, `splitRatio` in `init.lua` — for every key;
before, four keys used three rules that agreed only at 50/50.

Every move is instant — Hammerspoon's default 0.2 s slide is off
(`hs.window.animationDuration = 0`), for tiling, layouts and the Messages float.

Hyper+Q sends an app to the background; `Cmd+Q` on the same key quits it for
real (`Cmd+W` only closes the window — WhatsApp, Slack and Zoom keep running).
A stray Hyper+Q is harmless: Hyper+1–6 or the launcher brings the app back.

Hyper+` is Cmd+` per spot instead of per app: it cycles the windows that sit
exactly where the focused one is — Slack and Notion both tiled right, two
maximized windows, two floats on top of each other. Hyper+Tab and Hyper+Left/Right
only ever reach the topmost window of a half; this gets at the ones under it.
Each press raises the bottom-most of the stack, so three windows come round in
turn rather than the top two swapping. Hyper+; does the same from the right
hand — on the MacBook, ` with Caps Lock held is a stretch.

Hyper+G lists every window front to back (minimized ones last) with its app's
icon; typing filters on title and app name. Ghostty's titles carry the folder
and the running command, so a particular Claude session is a few keystrokes.

**Hyper+Down is the one thing that remembers.** Everything else is derived
from live window positions on each press, but "where was it before" can't be
read off the screen. So the last action is kept: every window one Hyper press
moved (a layout or swap moves two; tiles, maximize, the reading frame, the
messenger floats, "beside", a split), each with its frame from before, by
window id — used only to restore. Its one other reader is Hyper+S's second
press: when the last move was that window maximizing, it goes back to the
recorded frame; otherwise (maximized some other way, or something moved
since) beside the window below it. A mistaken Hyper+Z is one press from undone, both halves
at once, whichever window is in front. Moves made by dragging or by an app
itself aren't recorded.

A layout started cold (an app launching) moves its windows again 0.5 s later,
because Slack and Notion restore their own saved frame just after appearing.
That second pass stands down if you've pressed another Hyper key meanwhile,
so it can't undo it.

### Layouts (Hammerspoon, bottom row)

| Shortcut | Layout |
|---|---|
| Hyper + Z | Coding — Ghostty left, Dia right |
| Hyper + X | Meeting + notes — Zoom left, Notion right |
| Hyper + C | Meeting + chat — Zoom left, Slack right |
| Hyper + V | Meeting + browsing — Zoom left, Dia right |

The pair takes the screen's current split (halves when nothing's docked), so
a layout doesn't undo a Hyper+R; Hyper+R steps it from there. Press the same
layout again to swap focus between the two sides. An app that
isn't running (or has no window) is launched first; the layout waits for its
window — up to 10 s, since Slack and Notion take a few seconds — then tiles,
and repeats the move half a second later because Electron apps restore their
own saved position right after opening.

#### Adding a new layout

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

Pick a key that isn't already bound — hold Hyper for the cheatsheet, or look
at the lit Hyper layer on the Model 100 (dark keys are free). `,`/`.`/`/` are
reserved by macOS (see Tabs above). Saving the file reloads
Hammerspoon.

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

- The window you came from keeps its side and width if it's tiled; if it was
  maximized or floating, it takes the left side of the screen's split (a half
  when nothing's docked). The app gets the other half and the
  focus. Whatever was on that half stays underneath — Hyper+` reaches it.
- "The window you came from" is the next window down in the stacking order
  (skipping the app's own other windows), so nothing is remembered between
  presses. With no other window it maximizes instead.
- **A third press maximizes** — the undo for a second press made by mistake;
  a fourth goes beside again. "Third" is read off the screen too: already
  side by side with the window you came from means the next press maximizes.

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
  as a half instead of floating it. With no window in front (the desktop
  focused), Shift+key just brings the app forward, as the plain key does;
  on an app that's already beside you, it maximizes it (like a third
  Hyper+1–6 press).
- The panel shows straight away; typing the letter from memory just flashes it.
- `Escape`, any key not in the list, `Hyper+Space` again or 3 s of nothing
  closes it without doing anything. Its keys only work while it's open — an
  event tap swallows them — so they never reach the app underneath.
- `T` does what Hyper+T does (Messages over the right third), and `W` floats
  WhatsApp the same way — a quick reply without disturbing the layout; `W`
  again hides it and focus returns to where you were. `F` opens a new
  Finder window at home when none is open — otherwise Finder's only "window"
  is the Desktop and nothing would appear.
- The list is `launcherApps` in `init.lua`; a new app also needs its bundle ID
  in `BUNDLE_IDS`. Keys are physical, so they survive the Czech layout.

### Zoom (Hammerspoon)

| Shortcut | Action |
|---|---|
| Hyper + M | Toggle mute (works from any app, no focus switch) |
| Any (Model 100) | Same, as one key: Chrysalis maps Any to `F18`, Hammerspoon binds `F18` |
| Hyper + Return | Start / join the meeting about to begin |

**The mute alert comes about a second after the key.** It reads the state
back from Zoom's toolbar mic button, which (like the Meeting menu) only
catches up ~1.2 s after a toggle; Hammerspoon waits for it to flip rather
than guessing. Quick repeated presses count as one burst: the state at the
first press plus the number of presses says where you'll end up, and only
the last press shows an alert, once Zoom agrees. Not from the participant
tiles: there is one per person, and the first is usually someone else's —
which is how it once said "Unmuted" while you were muted. "Toggled" means
Zoom's state couldn't be read.

**Hyper+Return** joins the meeting about to begin from any app, without
touching Zoom. The work calendar isn't in macOS Calendar, so it reads Zoom's
own: the calendar sidebar on Zoom's home screen. About 10 minutes before a
meeting (and while it's under way) its card gets a **Start** button (you host)
or **Join**; Hyper+Return presses it. That works for any meeting link Zoom
knows, not only Zoom's: Join on a Teams meeting opens it in the browser.

- Meetings that already ended are skipped — a finished meeting still open in
  Zoom keeps its Start button.
- Of the rest, the one whose **start is nearest to now** wins: at 16:29 the
  16:30 meeting beats the one running since 16:00 (you're presumably in it).
  Only starts within 5 minutes of each other ask — a picker, soonest first
  (⌘1–9 pick a row). None → "No Zoom meeting starting soon".
- Times read in either clock — `15:30` or `3:30 PM` — and nearness wraps
  midnight (at 23:58, a 00:05 start is 7 minutes away). A card whose time
  can't be read at all is still offered, in the picker, rather than dropped.
- To see what it would do: `hs -c 'return zoomJoinableMeetings()'`.

- Zoom only has to be running: hidden is fine (it's unhidden first, since a
  hidden app's windows are invisible to accessibility); if it isn't running,
  it's launched and the sidebar gets ~9 s to load.
- It depends on Zoom's interface: if an update renames the button, it says
  "no meeting" rather than pressing anything else.

### Links: work in Chrome, the rest in Dia (Hammerspoon)

Hammerspoon is the default browser and routes every link opened from another
app — Slack, Notion, Zoom, Mail, the terminal: hosts on your work list open in
**Chrome's Work profile**, everything else in **Dia**. Links clicked inside a
browser stay in that browser.

- **Zoom meeting links** (`…zoom.us/j/<id>`, webinars `/w/<id>`) open the
  Zoom app straight into the meeting, as a `zoommtg://` join link with the
  password — no browser tab left on Zoom's "launching" page. Other Zoom pages
  stay in the browser.
- **Hold Option while clicking** to send a link to the other browser — for a
  host both accounts use, without editing the list.

The list is `~/.config/url-router/work.local` — machine-local and untracked,
so no employer detail lands in this repo; without it every link goes to Dia.
One rule per line: with a dot it matches that domain and its subdomains
(`miro.com` matches `app.miro.com`, not `evilmiro.com`); a single word matches
any host containing it (`yourcompany` covers all its domains, and its Slack,
Zoom and SSO subdomains); either one followed by a path matches only URLs
under it. It's re-read per link, so edits apply at once.

- **Slack's sign-in redirect:** links into an app that signs in through Slack
  (Jira, for one) leave Slack as `slack.com/openid/connect/…` with the real
  destination kept by Slack, not in the URL — so they went to Dia. A
  `slack.com/openid/` line in the work list sends that redirect to Chrome;
  ordinary links from Slack are unaffected.

- Shared domains are the limit: Gmail and Calendar serve both accounts from
  the same host, so a host can only go one way. Docs/Drive/Calendar → work,
  Gmail → Dia (personal mail lives there).
- Check where a URL would go: `hs -c 'return urlRouterTarget("https://…")'`.
- Becoming the default browser takes a click in macOS's dialog:
  `hs -c 'hs.urlevent.setDefaultHandler("http")'`. An MDM may reset it —
  `drift.sh` checks, whenever the work list exists.
- The Work profile is Chrome's `Default` folder (`CHROME_WORK_PROFILE` in
  `init.lua`; `chrome://version` shows a profile's folder).

### Screen-share guard (Hammerspoon)

When you start sharing your **screen** in Zoom, **Slack, Messages, WhatsApp,
Signal and Dia hide** — the messengers and the personal browser — silently,
since an alert would show on the shared screen. Sharing a single window hides
nothing: viewers see only that window, and the guard used to hide the very
app being shared (a Dia window). They stay hidden afterwards (Hyper+4, Hyper+T
or the launcher bring each back), so sharing again can't re-expose them.

- Trigger: Zoom's "zoom share toolbar window", which exists only while you
  share, checked every half second. A window filter caught only the first
  share — Zoom's floating windows don't reliably send the notifications it
  relies on. Screen or window: Zoom's "Annotation - Zoom" window covers
  exactly what's shared — the whole screen with its menu bar, or the window's
  frame (observed on test shares). `hs -c 'return zoomShareKind()'` shows
  what it sees.
- The check reads Zoom's windows with a 0.25 s accessibility timeout, so a
  hung Zoom can't freeze Hammerspoon (and every hotkey) on each tick.
- Dia ignores the normal hide request; the guard falls back to its own
  "Hide Dia" menu item (what Cmd+H does), which works.
- Notification banners are macOS's job, and it already does it: with
  "Allow notifications when mirroring or sharing the display" **off** (the
  default; System Settings → Notifications), a Zoom share counts, so banners
  don't show — tested with a real iMessage mid-share (no banner; the watch
  still buzzed). Leave that switch off.

### Messages (Hammerspoon)

| Shortcut | Action |
|---|---|
| Hyper + T | Show Messages over the right third; press again to hide it and return to the app you were in |
| Prog (Model 100) | Same, as one key: Chrysalis maps Prog to `F19`, Hammerspoon binds `F19` |

For quick replies without touching the current layout. It floats over the
right third — or the right **two thirds** where the app can't fit in a third.
That's the MacBook: a third is 504 pt, but Messages won't go below ~660 and
WhatsApp (launcher `W`, same float) below 800, and squeezed to the minimum
their fixed sidebars leave a narrow strip for the conversation. On the Dell
a third (853 pt) fits both. The minimums are measured constants in
`FLOAT_MIN_WIDTH` in `init.lua`; asking an app for less makes it keep its
left edge and run off the screen. It's the one Hyper key
where "again" hides instead of putting the app beside the last window. Pin the conversations you reply to
most, so Messages opens on them, and allow those people through your work
Focus (System Settings → Focus → People).

### Keep awake (Hammerspoon)

| Shortcut | Action |
|---|---|
| Hyper + 0 | Toggle KeepingYouAwake — the Mac and display stay awake while on |

It goes through KeepingYouAwake's URL scheme, no click on its menu bar cup
(which stays visible, as the at-a-glance state). The state is read, never assumed: while on, KeepingYouAwake runs
a `caffeinate` child process. Hyper+0 checks it, asks for the opposite
(`keepingyouawake:///activate` or `///deactivate` — not the blind `///toggle`),
waits up to 2 s for the process to follow and shows what it found. So clicking
the cup by hand in between never puts the alert out of step; "(didn't change)"
means KeepingYouAwake ignored the request.

### Reloading

Saving any `.lua` file in `config/hammerspoon/` reloads Hammerspoon on its own
(`hs.pathwatcher`), so there's no reload key. To reload
without an edit: `(hs -c 'hs.reload()' &)` in a terminal (in the background:
in the foreground `hs` waits on the reload and hangs).

### Debugging

The `hs` CLI lets you query Hammerspoon from the terminal:

```bash
hs -c 'hs.window.focusedWindow():frame()'   # inspect focused window
hs -c 'hs.application.applicationsForBundleID("com.tinyspeck.slackmacgap")[1]:allWindows()'  # an app's windows
```

Look apps up by bundle ID, as `getApp` does in `init.lua` (it's local, so `hs
-c` can't call it): `hs.application.get("name")` can return a helper process
instead of the app. If an app's windows are invisible to Hammerspoon (returns 0
windows),
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

Passwords stay out of it: 1Password marks what it copies as concealed, and
Maccy's default ignore list skips concealed and transient clipboard types.
macOS 26's own clipboard history in Spotlight doesn't — it would keep them
for hours — so **System Settings → Spotlight → Results from Clipboard is
off**. It can't be set from a script (the settings pane is sandboxed), so
`install.sh` lists it among the manual steps.

## Screenshots (Shottr)

Shottr replaces the built-in screenshot tool with annotation and OCR:

| Action | Shortcut |
|---|---|
| Capture an area | `Cmd+Shift+4` (the Model 100's butterfly key sends it) |
| Capture the whole screen | `Cmd+Shift+3` |
| Recognize text or a QR code on screen | `Cmd+Ctrl+Option+O` |
| Scrolling capture, a window, repeat the last area, delayed | Shottr's menu (its icon is in Thaw's always-hidden section) |

Shottr took over `Cmd+Shift+3`/`4` from macOS (whose own shortcuts are off in
System Settings → Keyboard → Keyboard Shortcuts → Screenshots); its settings
live in its sandbox, set in its own Settings window.

After capture: annotate with arrows, boxes, blur, or text.
Use the OCR button to extract text from any screenshot.

## Habits worth building

Each of these is set up and fast; the shell history says the old habit still
wins. Swap one at a time.

| Instead of | Use | Why |
|---|---|---|
| `cd`, then `cd src/<project>` | `cd <project>` (or `cd <fragment>`) from anywhere | `CDPATH` finds anything in `~/src`; zoxide ranks the rest |
| `git status`, `log`, `diff`, `add -p`, `commit` one at a time | `lazygit` | All of them on one screen; space stages a file, or a hunk or line inside it |
| `cat`/`less` on a Markdown file | `glow file.md` | Rendered: headings, tables, code blocks |
| `grep -r` | `rg pattern` | Recursive by default, skips `.gitignore`d files, much faster |
| `find . -name` | `fd pattern` | Same, for file names; `-e py` for an extension |
| `caffeinate` in a spare tab | Hyper+0 | KeepingYouAwake, shown in the menu bar; no tab to keep open |
| Retyping a long command | `Ctrl+R` | Fuzzy search over every tab's history |
