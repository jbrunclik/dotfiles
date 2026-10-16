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

## After every change: keep everything in step

A change isn't done until everything derived from it is updated, in the same
commit. Go through what applies:

- **Any behavior** (shortcut, remap, setting, workaround, new tool): `GUIDE.md`,
  plus `README.md` when it changes what's included or what `install.sh` does.
  Document the non-obvious part — why it works this way and what to watch out
  for — not only the key.
- **A Hyper binding added, moved or renamed** (Hammerspoon `bindHyper` or a
  Karabiner rule): the on-screen cheatsheet follows by itself; then run
  `keyboardio-layers --apply` (the Model 100's lit Hyper layer is generated
  from the same data) and `keyboardio-backup`, and commit the backup. A new
  cheatsheet section or app needs a color in `keyboardio-layers`
  (`SECTION_COLORS`, `APP_COLORS`, `KARABINER_COLORS`; 16 colors max) and a
  row in the GUIDE's color table.
- **Anything changed in Chrysalis** (keymap, macros, colors): quit Chrysalis,
  run `keyboardio-backup`, commit. If the base layer changed, rerun
  `keyboardio-layers --apply` first — the Hyper layer is built from it.
- **Printed cheatsheet and README images**: after Hyper bindings or the GUIDE's
  keyboard tables change, run `hyper-cheatsheet --readme` (refreshes the two
  images in `docs/`, commit them) and tell the user to rerun `hyper-cheatsheet`
  and reprint.
- **README.md is the GitHub storefront**: keep its Highlights and tables true
  when a headline feature appears, changes or goes away.
- **A new tool**: the public `Brewfile`, or `~/Brewfile.local` for work or
  machine-only tools (never MDM-installed apps); `REQUIRED_BINS` too if a config
  shells out to it.
- **A macOS setting**: `install.sh`, and apply it on this machine.
- **Last**: `./drift.sh` is clean.

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
  Bind Hyper keys with `bindHyper(key, section, description, fn)` (it binds by
  physical key code, so shortcuts survive the Czech layout). Look apps up
  with `getApp`/`launchApp` and add them to `BUNDLE_IDS` — never
  `hs.application.get("name")`, which can return a helper process (Zoom's
  "zoom.us Sidebar Web Content"). Write
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
