# Productivity Guide

A reference for all the tools, shortcuts, and workflows in this setup.
Bookmark this and revisit as you get comfortable — don't try to learn
everything at once.

## Terminal (Ghostty)

| Action | Shortcut |
|---|---|
| New tab | `Cmd+T` |
| Split horizontal | `Cmd+D` |
| Split vertical | `Cmd+Shift+D` |
| Navigate splits | `Cmd+Option+Arrow` |
| Zoom/focus a split | double-tap `Cmd+Enter` |
| Quick terminal (global) | `` Ctrl+` `` |
| Find in scrollback | `Cmd+F` |
| Edit config | `Cmd+,` |
| Reload config | `Cmd+Shift+,` |

The quick terminal is a system-wide dropdown terminal — press
`` Ctrl+` `` from any app to toggle it.

## Shell

### History search (readline)

Type the beginning of a command, then press **Up/Down arrow** to cycle
through only commands matching what you've typed. This is the single
biggest readline productivity boost.

Examples:
- Type `git` then press Up → cycles through your git commands
- Type `ssh` then press Up → cycles through your SSH sessions
- Type `docker` then press Up → cycles through docker commands

### Tab completion

- **Single tab** shows all completions (no need to double-tap)
- **Case-insensitive** — `cd doc` Tab → `cd Documents/`
- **Hyphen-underscore equivalent** — `my-proj` matches `my_proj`

### Fuzzy finder (fzf)

| Action | Shortcut |
|---|---|
| Search command history | `Ctrl+R` |
| Find files | Type then `**` Tab (e.g., `vim **` Tab) |
| Change directory | `cd **` Tab |

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

These are aliased over the defaults. Use them as you normally would:

```bash
cat file.py        # syntax-highlighted output (bat)
ls                 # icons + git status + grouped dirs (eza)
ll                 # detailed listing
lt                 # tree view (2 levels)
find .json         # find files matching pattern (fd)
rg "TODO"          # search file contents (ripgrep) — not aliased, use rg directly
du                 # visual disk usage (dust)
top                # process monitor (btop)
diff a.txt b.txt   # syntax-highlighted diff (delta)
glow README.md     # render markdown in terminal
```

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

### Useful git config

- **`git push`** on a new branch automatically sets upstream (no `-u origin` needed)
- **`git pull`** rebases by default (cleaner history)
- **`rerere`** remembers conflict resolutions and auto-applies them next time
- **`fetch.prune`** auto-cleans stale remote branches
- **`diff.algorithm = histogram`** — better diffs for moved code

## Hyper key

Hyper (Cmd+Option+Ctrl+Shift) is a dedicated modifier that doesn't
conflict with any app shortcuts. It's triggered by:

| Keyboard | Key | Config |
|---|---|---|
| MacBook | CapsLock (hold) | Karabiner-Elements |
| Keyboardio Model 100 | Any key (hold) | Chrysalis firmware |

On MacBook, tapping CapsLock sends Escape (great for Neovim).

### Navigation (Karabiner)

| Shortcut | Action |
|---|---|
| Hyper + H | Left arrow |
| Hyper + J | Down arrow |
| Hyper + K | Up arrow |
| Hyper + L | Right arrow |

Works system-wide: Slack, Notion, Chrome, etc.

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

### Debugging

The `hs` CLI lets you query Hammerspoon from the terminal:

```bash
hs -c 'hs.window.focusedWindow():frame()'   # inspect focused window
hs -c 'hs.application.get("Slack"):allWindows()'  # list app windows
```

If an app's windows are invisible to Hammerspoon (returns 0 windows),
restart the app — Electron apps like Slack can lose their accessibility
registration after updates.

## Clipboard (Maccy)

Maccy keeps a searchable clipboard history. Press `Cmd+Shift+V` (default)
to open the picker, then type to fuzzy-search past copies. Configure
the hotkey in Maccy preferences.

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

Edit `config/hammerspoon/init.lua`:

```lua
hs.hotkey.bind(hyper, "d", function()
    layout({
        { name = "Figma",  rect = left },
        { name = "Safari", rect = right },
    })
end)
```

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
