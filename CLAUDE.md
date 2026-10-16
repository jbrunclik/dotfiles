# dotfiles

macOS dotfiles, Catppuccin Mocha everywhere. This repo is **public**: no secrets,
hostnames, or employer-specific detail in tracked files.

## Layout

- `lib/links.sh` — the symlink manifest (`LINKS`) plus `REQUIRED_BINS` and
  `LOCAL_FILES`. `install.sh` and `drift.sh` both source it.
- `install.sh` — Brewfile, symlinks, macOS `defaults`, Finder default apps,
  Claude Code bootstrap, VS Code extensions. `drift.sh` reports divergence.
- `config/<tool>/` — per-tool config; most files are symlinked into place, so
  editing the repo file changes the live config.
- `GUIDE.md` — user-facing reference for every shortcut and workaround.
  `README.md` — what's included and how to install.

## Keep the docs in step with behavior

Every change to behavior — a shortcut, remap, setting, workaround or new tool —
updates `GUIDE.md` in the same commit, and `README.md` too when it changes what
is included or what `install.sh` does. Document the non-obvious part: why it
works this way and what to watch out for, not only the key.

## Conventions

- A tool that a config shells out to goes in both `Brewfile` and
  `REQUIRED_BINS` in `lib/links.sh`. CI asserts they agree.
- macOS settings worth keeping go in `install.sh` as `defaults write`, next to
  the existing ones — and get applied on this machine too.
- `~/.gitconfig` is a symlink to the tracked `gitconfig`, so
  `git config --global` and `git maintenance start` write into the repo.
  Machine-local git config goes in `~/.gitconfig.local`; check `gitconfig`
  diffs for absolute `/Users/...` paths before committing.
- Hyper is Cmd+Option+Ctrl+Shift. Before binding a Hyper chord, check
  `GUIDE.md` for what's taken. macOS reserves `Hyper+,` `Hyper+.` `Hyper+/`
  (sysdiagnose); only Karabiner can use them.

## Tool gotchas

- **Karabiner** reformats `karabiner.json` on save, and `~/.config/karabiner`
  is a directory link because it replaces file symlinks. After hand edits,
  reload with
  `launchctl kickstart -k gui/$(id -u)/org.pqrs.service.agent.Karabiner-Console-User-Server`,
  then commit the file as Karabiner rewrote it.
- **Hammerspoon** reloads itself when a `.lua` file in `config/hammerspoon/`
  is saved. Query live state with `hs -c '<lua>'`; don't run `hs -c 'hs.reload()'`
  in the foreground, it hangs. In scripts, give `hs` `</dev/null` — it reads
  commands from stdin when that isn't a terminal and otherwise waits forever. Never memoize window state — derive it from live
  positions. Use `hs.alert` only for state feedback (mute, errors), not routine
  actions.
  After adding or moving a Hyper binding, also run `keyboardio-layers --apply`
  (the Model 100's lit Hyper layer is generated from it) and `keyboardio-backup`.
  Bind Hyper keys with `bindHyper(key, section, description, fn)` (it binds by
  physical key code, so shortcuts survive the Czech layout), and write
  Karabiner rule descriptions as `[App: ]Hyper+<keys> → <action>`: the
  hold-Hyper cheatsheet is generated from both.
- **Ghostty** doesn't watch its config: Cmd+Shift+, (or the Ghostty >
  Reload Configuration menu) before testing in a new tab. Validate with
  `/Applications/Ghostty.app/Contents/MacOS/ghostty +validate-config`.

## Verifying changes

A PostToolUse hook (`.claude/hooks/check-config.sh`) validates each edited file
— shellcheck, JSON, Lua syntax, Karabiner lint, Ghostty config. Beyond that:

- `./drift.sh` — symlinks, packages, required binaries, local files.
- CI (`.github/workflows/ci.yml`) runs shellcheck, Lua/JSON/YAML syntax and the
  Brewfile ↔ `REQUIRED_BINS` check on every push.
- Keyboard and GUI behavior can't be exercised from a shell: apply it, check
  the tool's log or state, then ask the user to press the keys.

## Commits

One commit per finished, verified change, with docs in the same commit.
Messages start with the area (`Karabiner:`, `install.sh:`, `Docs:`) and the
body explains why. Push only when asked.
