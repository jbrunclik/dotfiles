-- Window tiling scenarios: the real init.lua, loaded under the fake hs in
-- mock.lua, driven by Hyper presses against fake windows.
-- Run from the repo root: lua tests/hammerspoon/run.lua

local hs = require("mock")
local test = require("runner").test

local CONFIG = os.getenv("HS_CONFIG") or "config/hammerspoon/init.lua"
local DELL = { "DELL U2723QE", 2560, 1440 }
local MACBOOK = { "Built-in Retina Display", 1512, 982 }

local IDS = {
    Ghostty = "com.mitchellh.ghostty",
    Dia = "company.thebrowser.dia",
    Slack = "com.tinyspeck.slackmacgap",
    Notion = "notion.id",
    Claude = "com.anthropic.claudefordesktop",
    ["Visual Studio Code"] = "com.microsoft.VSCode",
    Messages = "com.apple.MobileSMS",
}

-- Each test gets a fresh world and a freshly loaded config (hotkeys and
-- Hyper+Down's memory start empty)
local screen
local function setup(display)
    hs.reset()
    screen = hs.screen(table.unpack(display or DELL))
    hs.load(CONFIG)
end

-- Where init.lua puts a window that takes the share [x, x + w) of the
-- screen's width, full height: GAP in from each screen edge it reaches,
-- none at a split. Written out here rather than read from init.lua, so a
-- change to the gaps has to change both.
local GAP = 8
local function at(x, w)
    local s = screen:frame()
    local l = x < 0.001 and GAP or 0
    local r = x + w > 0.999 and GAP or 0
    return hs.rect(s.x + x * s.w + l, s.y + GAP, w * s.w - l - r, s.h - 2 * GAP)
end
-- The same share flush with the screen's edges: dragged there by hand, or
-- tiled by macOS itself
local function flush(x, w)
    local s = screen:frame()
    return hs.rect(s.x + x * s.w, s.y, w * s.w, s.h)
end
local function win(app, x, w, opts)
    return hs.window(app, IDS[app], at(x, w), opts)
end
local function float(app)
    local s = screen:frame()
    return hs.window(app, IDS[app], hs.rect(s.x + 400, s.y + 200, 900, 700))
end

-- Assertions ------------------------------------------------------------------

local function near(a, b) return math.abs(a - b) < 1 end
local function describe(f) return string.format("{x=%.0f y=%.0f w=%.0f h=%.0f}", f.x, f.y, f.w, f.h) end

-- `w` occupies the share [x, x + width) of the screen, full height
local function assertAt(w, x, width, label)
    local want, got = at(x, width), w:frame()
    if not (near(got.x, want.x) and near(got.y, want.y) and near(got.w, want.w) and near(got.h, want.h)) then
        error(string.format("%s: %s at %s, want %s", label or "frame", w:title(), describe(got), describe(want)), 2)
    end
end
local function assertFrame(w, want, label)
    local got = w:frame()
    if not (near(got.x, want.x) and near(got.y, want.y) and near(got.w, want.w) and near(got.h, want.h)) then
        error(string.format("%s: %s at %s, want %s", label or "frame", w:title(), describe(got), describe(want)), 2)
    end
end
local function assertFocused(w)
    local f = hs.focused()
    if f ~= w then
        error(string.format("focused %s, want %s", f and f:title() or "nothing", w:title()), 2)
    end
end
local function left(w, share, label) assertAt(w, 0, share, label) end
local function right(w, share, label) assertAt(w, 1 - share, share, label) end

-- Splits: Hyper+R ---------------------------------------------------------------

test("Hyper+R moves a 50/50 split to two thirds", function()
    setup()
    local g, d = win("Ghostty", 0, 1 / 2), win("Dia", 1 / 2, 1 / 2)
    g:focus()
    hs.press("r")
    left(g, 2 / 3)
    right(d, 1 / 3)
end)

test("Hyper+R cycles 50 → 67 → 33 → 50 on the Dell", function()
    setup()
    local g, d = win("Ghostty", 0, 1 / 2), win("Dia", 1 / 2, 1 / 2)
    d:focus()
    hs.press("r") left(g, 2 / 3)
    hs.press("r") left(g, 1 / 3)
    hs.press("r") left(g, 1 / 2)
    right(d, 1 / 2)
end)

test("Hyper+R steps 50 → 60 → 40 on the MacBook", function()
    setup(MACBOOK)
    local g, d = win("Ghostty", 0, 1 / 2), win("Dia", 1 / 2, 1 / 2)
    g:focus()
    hs.press("r") left(g, 0.6) right(d, 0.4)
    hs.press("r") left(g, 0.4) right(d, 0.6)
end)

test("Hyper+R moves windows left at an older split too", function()
    setup()
    -- A 67/33 pair underneath, a 33/67 pair on top
    local s, n = win("Slack", 0, 2 / 3), win("Notion", 2 / 3, 1 / 3)
    local g, d = win("Ghostty", 0, 1 / 3), win("Dia", 1 / 3, 2 / 3)
    g:focus()
    hs.press("r") -- 33 → 50
    left(g, 1 / 2) right(d, 1 / 2)
    left(s, 1 / 2, "stale left") right(n, 1 / 2, "stale right")
end)

test("Hyper+R leaves maximized and floating windows alone", function()
    setup()
    local m = win("Notion", 0, 1)
    local f = float("Claude")
    local fFrame = f:frame()
    local g, d = win("Ghostty", 0, 1 / 2), win("Dia", 1 / 2, 1 / 2)
    g:focus()
    hs.press("r")
    left(m, 1, "maximized")
    assertFrame(f, fFrame, "float")
end)

test("Hyper+R does nothing on an undocked window", function()
    setup()
    local g, d = win("Ghostty", 0, 1 / 2), win("Dia", 1 / 2, 1 / 2)
    local m = win("Notion", 0, 1)
    hs.press("r")
    left(m, 1) left(g, 1 / 2) right(d, 1 / 2)
end)

test("Hyper+Down undoes a split move, stale windows included", function()
    setup()
    local s, n = win("Slack", 0, 1 / 2), win("Notion", 1 / 2, 1 / 2)
    local g, d = win("Ghostty", 0, 1 / 3), win("Dia", 1 / 3, 2 / 3)
    g:focus()
    hs.press("r")
    hs.press("down")
    left(g, 1 / 3) right(d, 2 / 3)
    left(s, 1 / 2) right(n, 1 / 2)
end)

-- Splits: Hyper+A / Hyper+D -----------------------------------------------------

test("Hyper+A again steps the left window ½ → ⅔ → ⅓, the partner follows", function()
    setup()
    local g, d = win("Ghostty", 0, 1 / 2), win("Dia", 1 / 2, 1 / 2)
    g:focus()
    hs.press("a") left(g, 2 / 3) right(d, 1 / 3)
    hs.press("a") left(g, 1 / 3) right(d, 2 / 3)
    hs.press("a") left(g, 1 / 2) right(d, 1 / 2)
end)

test("Hyper+D again steps the right window's own width", function()
    setup()
    local g, d = win("Ghostty", 0, 1 / 2), win("Dia", 1 / 2, 1 / 2)
    d:focus()
    hs.press("d") right(d, 2 / 3) left(g, 1 / 3)
end)

test("Hyper+A steps move windows at an older split too", function()
    setup()
    local s, n = win("Slack", 0, 2 / 3), win("Notion", 2 / 3, 1 / 3)
    local g, d = win("Ghostty", 0, 1 / 3), win("Dia", 1 / 3, 2 / 3)
    g:focus()
    hs.press("a") -- ⅓ → ½
    left(g, 1 / 2) right(d, 1 / 2)
    left(s, 1 / 2, "stale left") right(n, 1 / 2, "stale right")
end)

test("Hyper+A on a maximized window takes the current split", function()
    setup()
    local g, d = win("Ghostty", 0, 1 / 3), win("Dia", 1 / 3, 2 / 3)
    local v = win("Visual Studio Code", 0, 1)
    hs.press("a")
    left(v, 1 / 3)
end)

test("Hyper+D on a floating window takes the rest of the split", function()
    setup()
    local g, d = win("Ghostty", 0, 1 / 3), win("Dia", 1 / 3, 2 / 3)
    local c = float("Claude")
    hs.press("d")
    right(c, 2 / 3)
end)

test("Hyper+A with nothing docked: a half", function()
    setup()
    win("Notion", 0, 1)
    local c = float("Claude")
    hs.press("a")
    left(c, 1 / 2)
end)

test("Hyper+A on the right window of a split moves it to the left side", function()
    setup()
    local g, d = win("Ghostty", 0, 1 / 3), win("Dia", 1 / 3, 2 / 3)
    d:focus()
    hs.press("a")
    left(d, 1 / 3)
end)

test("Hyper+A on the only docked window: a half", function()
    setup()
    local d = win("Dia", 1 / 3, 2 / 3)
    hs.press("a")
    left(d, 1 / 2)
end)

-- Swap: Hyper+E -----------------------------------------------------------------

test("Hyper+E swaps the pair, each keeping its width", function()
    setup()
    local g, d = win("Ghostty", 0, 1 / 3), win("Dia", 1 / 3, 2 / 3)
    g:focus()
    hs.press("e")
    right(g, 1 / 3) left(d, 2 / 3)
end)

test("Hyper+E moves windows at an older split to the new one", function()
    setup()
    local s, n = win("Slack", 0, 1 / 2), win("Notion", 1 / 2, 1 / 2)
    local g, d = win("Ghostty", 0, 1 / 3), win("Dia", 1 / 3, 2 / 3)
    g:focus()
    hs.press("e")
    left(s, 2 / 3, "stale left") right(n, 1 / 3, "stale right")
end)

test("Hyper+E with one side empty moves the focused window over", function()
    setup()
    local g = win("Ghostty", 0, 1 / 3)
    hs.press("e")
    right(g, 1 / 3)
end)

test("Hyper+E on an undocked window beside one docked side: the other side", function()
    setup()
    local g = win("Ghostty", 0, 1 / 3)
    local c = float("Claude")
    hs.press("e")
    right(c, 2 / 3)
end)

-- Maximize: Hyper+S -------------------------------------------------------------

test("Hyper+S maximizes; again puts it back where it was", function()
    setup()
    local g, d = win("Ghostty", 0, 1 / 3), win("Dia", 1 / 3, 2 / 3)
    g:focus()
    hs.press("s") left(g, 1)
    hs.press("s") left(g, 1 / 3)
end)

test("Hyper+S again on a window maximized elsewhere: beside the one below", function()
    setup()
    local d = win("Dia", 1 / 3, 2 / 3)
    local g = win("Ghostty", 0, 1)
    hs.press("s")
    left(g, 1 / 3)
end)

test("Hyper+S again with a maximized window below: the screen's split", function()
    setup()
    local s, n = win("Slack", 0, 1 / 3), win("Notion", 1 / 3, 2 / 3)
    local v = win("Visual Studio Code", 0, 1)
    local g = win("Ghostty", 0, 1)
    hs.press("s")
    -- Below is the maximized VS Code, which has no side: the left side of
    -- the split Slack | Notion share
    left(g, 1 / 3)
end)

-- Layouts: Hyper+Z --------------------------------------------------------------

test("A layout tiles its pair at the screen's current split", function()
    setup()
    local s, n = win("Slack", 0, 1 / 3), win("Notion", 1 / 3, 2 / 3)
    local g, d = win("Ghostty", 0, 1), win("Dia", 0, 1)
    hs.press("z")
    left(g, 1 / 3) right(d, 2 / 3)
    assertFocused(g)
end)

test("A layout with nothing docked tiles halves", function()
    setup()
    local d, g = win("Dia", 0, 1), win("Ghostty", 0, 1)
    hs.press("z")
    left(g, 1 / 2) right(d, 1 / 2)
end)

test("A layout's second press swaps focus and keeps the split", function()
    setup()
    local g, d = win("Ghostty", 0, 1 / 3), win("Dia", 1 / 3, 2 / 3)
    g:focus()
    hs.press("z")
    assertFocused(d)
    left(g, 1 / 3) right(d, 2 / 3)
    hs.press("z")
    assertFocused(g)
end)

-- Beside: an app key pressed twice ------------------------------------------------

-- appKeys in init.lua: Hyper+1 is Ghostty, Hyper+2 Dia
test("An app key twice puts it beside a docked window at its split", function()
    setup()
    local d = win("Dia", 1 / 3, 2 / 3)
    local g = win("Ghostty", 0, 1)
    hs.press("1")
    left(g, 1 / 3) right(d, 2 / 3)
    assertFocused(g)
end)

test("An app key twice beside a maximized window: the screen's split", function()
    setup()
    local s, n = win("Slack", 0, 1 / 3), win("Notion", 1 / 3, 2 / 3)
    local d = win("Dia", 0, 1)
    local g = win("Ghostty", 0, 1)
    hs.press("1")
    left(d, 1 / 3) right(g, 2 / 3)
end)

test("An app key twice beside a maximized window, nothing docked: halves", function()
    setup()
    local d = win("Dia", 0, 1)
    local g = win("Ghostty", 0, 1)
    hs.press("1")
    left(d, 1 / 2) right(g, 1 / 2)
end)

-- Gaps ------------------------------------------------------------------------

test("Tiles and maximize keep a gap from the screen's edges, none at the split", function()
    setup()
    local g, d = win("Ghostty", 0, 1 / 2), win("Dia", 1 / 2, 1 / 2)
    g:focus()
    hs.press("r")
    local s, gf, df = screen:frame(), g:frame(), d:frame()
    assert(near(gf.x, s.x + GAP) and near(gf.y, s.y + GAP) and near(gf.h, s.h - 2 * GAP), "left: outer gaps")
    assert(near(df.x + df.w, s.x + s.w - GAP), "right: outer gap")
    assert(near(gf.x + gf.w, df.x), "no gap at the split")
    hs.press("s")
    local m = g:frame()
    assert(near(m.x, s.x + GAP) and near(m.w, s.w - 2 * GAP), "maximized: outer gaps")
end)

test("A maximized window under a pair is covered exactly", function()
    setup()
    local v = win("Visual Studio Code", 0, 1)
    local g, d = win("Ghostty", 0, 1 / 3), win("Dia", 1 / 3, 2 / 3)
    local vf, gf, df = v:frame(), g:frame(), d:frame()
    assert(near(vf.x, gf.x) and near(vf.y, gf.y) and near(vf.h, gf.h), "left edges")
    assert(near(vf.x + vf.w, df.x + df.w), "right edges")
    assert(near(gf.x + gf.w, df.x), "pair meets")
end)

test("Windows flush with the screen's edges still count as docked", function()
    setup()
    local g = hs.window("Ghostty", IDS.Ghostty, flush(0, 1 / 2))
    local d = hs.window("Dia", IDS.Dia, flush(1 / 2, 1 / 2))
    g:focus()
    hs.press("r")
    left(g, 2 / 3) right(d, 1 / 3)
end)

test("A window flush with every edge counts as maximized, not docked", function()
    setup()
    local d = win("Dia", 1 / 3, 2 / 3)
    local m = hs.window("Notion", IDS.Notion, flush(0, 1))
    d:focus()
    hs.press("r")
    assertFrame(m, flush(0, 1), "maximized untouched")
end)

test("The Messages float lines up with a tiled third", function()
    setup()
    local g, d = win("Ghostty", 0, 2 / 3), win("Dia", 2 / 3, 1 / 3)
    local m = hs.window("Messages", IDS.Messages, at(0.2, 0.5))
    g:focus()
    hs.press("t")
    assertFocused(m)
    assertFrame(m, d:frame(), "float")
end)

test("The Messages float on the MacBook: two thirds, its minimum won't fit a third", function()
    setup(MACBOOK)
    local m = hs.window("Messages", IDS.Messages, at(0.2, 0.5))
    win("Ghostty", 0, 1):focus()
    hs.press("t")
    right(m, 2 / 3)
end)

-- Focus: Hyper+Tab, Left/Right, ` ----------------------------------------------

test("Hyper+Tab focuses the other side of an uneven split", function()
    setup()
    local g, d = win("Ghostty", 0, 1 / 3), win("Dia", 1 / 3, 2 / 3)
    hs.press("tab") assertFocused(g)
    hs.press("tab") assertFocused(d)
end)

test("Hyper+Left/Right go by each window's centre", function()
    setup()
    local g, d = win("Ghostty", 0, 1 / 3), win("Dia", 1 / 3, 2 / 3)
    hs.press("left") assertFocused(g)
    hs.press("right") assertFocused(d)
end)

test("Hyper+` brings the bottom of the stack forward", function()
    setup()
    local s = win("Slack", 1 / 2, 1 / 2)
    local n = win("Notion", 1 / 2, 1 / 2)
    local d = win("Dia", 1 / 2, 1 / 2)
    hs.press("`") assertFocused(s)
    hs.press("`") assertFocused(n)
end)
