-- Hammerspoon config
-- Hyper key (Cmd+Option+Ctrl+Shift) via:
--   MacBook:    CapsLock (remapped by Karabiner-Elements)
--   Keyboardio: Any key (configured in Chrysalis firmware)

require("hs.ipc")

local hyper = { "cmd", "alt", "ctrl", "shift" }

-- Every Hyper binding goes through bindHyper so the cheatsheet (hold Hyper
-- alone) lists it. Entries keep bind order; sections appear in first-use order.
--
-- Keys are bound by physical position (macOS kVK_ANSI_* codes), not by
-- character: hs.hotkey resolves "z" with whatever layout is active when the
-- config loads, so a reload while on Czech QWERTZ would move Hyper+Z onto the
-- Y key. Karabiner matches physical keys too, so the whole Hyper layer stays
-- put on any layout. Names missing here (tab, left, right) are
-- layout-independent already.
local ansiKeys = {
    a = 0, s = 1, d = 2, f = 3, h = 4, g = 5, z = 6, x = 7, c = 8, v = 9,
    b = 11, q = 12, w = 13, e = 14, r = 15, y = 16, t = 17, o = 31, u = 32,
    i = 34, p = 35, l = 37, j = 38, k = 40, n = 45, m = 46,
    ["1"] = 18, ["2"] = 19, ["3"] = 20, ["4"] = 21, ["5"] = 23, ["6"] = 22,
    ["7"] = 26, ["8"] = 28, ["9"] = 25, ["0"] = 29,
}
local cheatsheet = {}
-- What pressing a key again does, shown once per cheatsheet section
local sectionNotes = {
    Layouts = "again: swap focus",
    Apps = "again: maximize",
}
local function bindHyper(key, section, desc, fn)
    table.insert(cheatsheet, { key = key, section = section, desc = desc })
    hs.hotkey.bind(hyper, ansiKeys[key] or key, fn)
end

-- Find the best window for an app (handles Zoom's multiple windows)
local function bestWindow(appName)
    local app = hs.application.get(appName)
    if not app then return nil end

    -- For Zoom: prefer the meeting/webinar window over the dashboard
    if appName == "zoom.us" then
        -- Strategy 1: exact title match
        for _, title in ipairs({ "Zoom Meeting", "Zoom Webinar" }) do
            local win = app:getWindow(title)
            if win and win:isVisible() then return win end
        end
        -- Strategy 2: title containing "Meeting" or "Webinar"
        for _, w in ipairs(app:allWindows()) do
            local t = w:title()
            if w:isStandard() and w:isVisible() and
               (t:find("Meeting") or t:find("Webinar")) then
                return w
            end
        end
        -- Strategy 3: largest visible window (skip the "Zoom" dashboard)
        local best, bestArea = nil, 0
        for _, w in ipairs(app:allWindows()) do
            if w:isStandard() and w:isVisible() and w:title() ~= "Zoom" then
                local s = w:size()
                local area = s.w * s.h
                if area > bestArea then best, bestArea = w, area end
            end
        end
        if best then return best end
    end

    return app:mainWindow()
end

local left  = hs.geometry.rect(0, 0, 0.5, 1)
local right = hs.geometry.rect(0.5, 0, 0.5, 1)

-- Check if a window occupies a given unit rect AND is the topmost window there.
-- Position-only checks are fooled by windows stacked at the same coordinates
-- (e.g. Slack and Dia both tiled right, with one covering the other).
local function isTiled(win, unitRect)
    if not win then return false end
    local f = win:frame()
    local s = win:screen():frame()
    local threshold = 20
    local inPosition = math.abs(f.x - (s.x + unitRect.x * s.w)) < threshold
        and math.abs(f.y - (s.y + unitRect.y * s.h)) < threshold
        and math.abs(f.w - unitRect.w * s.w) < threshold
        and math.abs(f.h - unitRect.h * s.h) < threshold
    if not inPosition then return false end
    -- Check that no other standard window is above this one at the same position
    for _, w in ipairs(hs.window.orderedWindows()) do
        if w == win then return true end
        if w:isStandard() then
            local wf = w:frame()
            if math.abs(wf.x - f.x) < threshold and math.abs(wf.w - f.w) < threshold then
                return false -- another window is above ours at the same spot
            end
        end
    end
    return true
end

-- Tile two apps side by side; repeat press cycles focus.
--
-- KEY PRINCIPLE: never rely on memoized state — always derive from live window
-- positions. Memoized flags (like "tiled = true") go stale when the user moves
-- or maximizes windows between presses.
--
-- Cycle-vs-tile decision uses isTiled() on BOTH windows: only cycles when both
-- the expected apps are actually in position. This also handles layout switching
-- (e.g. Hyper+V then Hyper+C) correctly — a leftover window from a previous
-- layout won't match because isTiled checks the specific app's window.
--
-- Rapid focus() calls race with the macOS window server — the second call
-- lands before the first is processed, so the final z-order is unpredictable.
-- A 50 ms gap between focus(right) and focus(left) lets each call settle.
-- This is imperceptible to humans but enough for the window server.
--
-- The 0.3 s delay in the launch path lets launchOrFocus() finish creating the
-- window before we try to move it — only fires when an app wasn't running yet.
-- When both apps are already running, tiling takes ~50 ms (one timer tick).
local function tilePair(leftApp, rightApp)
    local lw = bestWindow(leftApp)
    local rw = bestWindow(rightApp)
    -- If both windows are already in position, cycle focus
    if isTiled(lw, left) and isTiled(rw, right) then
        local la = hs.application.get(leftApp)
        if la and la:isFrontmost() then rw:focus() else lw:focus() end
        return
    end
    -- Launch any app that isn't running yet
    if not lw then hs.application.launchOrFocus(leftApp) end
    if not rw then hs.application.launchOrFocus(rightApp) end
    -- Position windows and set z-order with a gap between focus calls
    local function tile()
        lw = lw or bestWindow(leftApp)
        rw = rw or bestWindow(rightApp)
        if lw then lw:move(left) end
        if rw then rw:move(right) end
        -- Focus right first (brings above old occupant), then left after a tick
        if rw then rw:focus() end
        hs.timer.doAfter(0.05, function()
            if lw then lw:focus() end
        end)
    end
    if lw and rw then tile() else hs.timer.doAfter(0.3, tile) end
end

-- Layouts (bottom row: Z, X, C, V)
bindHyper("z", "Layouts", "Ghostty | Dia", function() tilePair("Ghostty", "Dia") end)
bindHyper("x", "Layouts", "Zoom | Notion", function() tilePair("zoom.us", "Notion") end)
bindHyper("c", "Layouts", "Zoom | Slack", function() tilePair("zoom.us", "Slack") end)
bindHyper("v", "Layouts", "Zoom | Dia", function() tilePair("zoom.us", "Dia") end)

-- Hyper+Tab = toggle focus between left and right windows
bindHyper("tab", "Windows", "Focus the other half", function()
    local screen = hs.screen.mainScreen()
    local mid = screen:frame().w / 2
    local current = hs.window.focusedWindow()
    if not current then return end
    local targetSide = current:frame().x < mid and "right" or "left"
    local wins = hs.fnutils.filter(hs.window.orderedWindows(), function(w)
        if targetSide == "left" then
            return w:frame().x < mid
        else
            return w:frame().x >= mid
        end
    end)
    if wins[1] then wins[1]:focus() end
end)

-- Hyper+Left/Right = focus window in that direction
bindHyper("left", "Windows", "Focus left half", function()
    local wins = hs.fnutils.filter(hs.window.orderedWindows(), function(w)
        return w:frame().x < hs.screen.mainScreen():frame().w / 2
    end)
    if wins[1] then wins[1]:focus() end
end)

bindHyper("right", "Windows", "Focus right half", function()
    local wins = hs.fnutils.filter(hs.window.orderedWindows(), function(w)
        return w:frame().x >= hs.screen.mainScreen():frame().w / 2
    end)
    if wins[1] then wins[1]:focus() end
end)

-- Hyper+F = toggle native fullscreen
bindHyper("f", "Windows", "Toggle native fullscreen", function()
    local win = hs.window.focusedWindow()
    if win then win:toggleFullScreen() end
end)

-- Hyper+ASD = tile left / maximize / tile right
bindHyper("a", "Windows", "Tile left half", function()
    local win = hs.window.focusedWindow()
    if win then win:move(left) end
end)

bindHyper("d", "Windows", "Tile right half", function()
    local win = hs.window.focusedWindow()
    if win then win:move(right) end
end)

bindHyper("s", "Windows", "Maximize", function()
    local win = hs.window.focusedWindow()
    if win then win:maximize() end
end)

-- Hyper+1-6 = focus app (repeat to maximize). Third field: cheatsheet label
-- when the process name isn't the one people say.
local appKeys = {
    { "1", "Ghostty" },
    { "2", "Dia" },
    { "3", "Google Chrome", "Chrome" },
    { "4", "Slack" },
    { "5", "Notion" },
    { "6", "zoom.us", "Zoom" },
}
for _, binding in ipairs(appKeys) do
    bindHyper(binding[1], "Apps", binding[3] or binding[2], function()
        local app = hs.application.get(binding[2])
        if app and app:isFrontmost() then
            local win = app:mainWindow()
            if win then win:maximize() end
        else
            hs.application.launchOrFocus(binding[2])
        end
    end)
end

-- Check Zoom mute state by reading the toolbar button's accessibility description
local function isZoomMuted()
    local zoom = hs.application.get("zoom.us")
    if not zoom then return nil end
    local axApp = hs.axuielement.applicationElement(zoom)
    for _, win in ipairs(axApp:childrenWithRole("AXWindow")) do
        for _, elem in ipairs(win:childrenWithRole("AXTabGroup")) do
            local desc = elem:attributeValue("AXDescription") or ""
            if desc:find("audio unmuted") then return false end
            if desc:find("audio muted") then return true end
        end
    end
    return nil -- not in a meeting
end

-- Hyper+M = toggle Zoom mute (works from any app, no focus switch)
bindHyper("m", "Zoom", "Mute / unmute (from any app)", function()
    local zoom = hs.application.get("zoom.us")
    if not zoom then
        hs.alert.show("\u{1F4F5} Zoom not running")
        return
    end
    if zoom:selectMenuItem({ "Meeting", "Unmute audio" }) or
       zoom:selectMenuItem({ "Meeting", "Mute audio" }) then
        -- Brief delay for Zoom to update its UI state
        hs.timer.doAfter(0.2, function()
            local muted = isZoomMuted()
            if muted == true then
                hs.alert.show("\u{1F507} Muted")
            elseif muted == false then
                hs.alert.show("\u{1F50A} Unmuted")
            else
                hs.alert.show("\u{1F50A} Toggled")
            end
        end)
    else
        hs.alert.show("\u{26A0}\u{FE0F} Not in a meeting")
    end
end)

-- Reload config
bindHyper("r", "Hammerspoon", "Reload config (saving a .lua file also does)", function()
    hs.reload()
end)

-- Auto-reload when a .lua file in this directory is saved. Watches the repo
-- directory this file was dofile'd from, not hs.configdir (~/.hammerspoon only
-- holds the loader). Kept in a global so the watcher isn't garbage-collected.
local configDir = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$")
configWatcher = hs.pathwatcher.new(configDir, function(paths)
    for _, path in ipairs(paths) do
        if path:match("%.lua$") then
            hs.reload()
            return
        end
    end
end):start()

-- Cheatsheet: hold Hyper alone for a moment to list every Hyper binding;
-- release it or press any key to hide. Hammerspoon bindings come from the
-- bindHyper registry, Karabiner remaps from karabiner.json's rule descriptions
-- (any rule written "[App: ]Hyper+<keys> → <action>"), so nothing is listed by
-- hand.
local keyLabels = { tab = "Tab", left = "←", right = "→" }

local function karabinerEntries()
    local config = hs.json.read(configDir .. "/../karabiner/karabiner.json")
    local entries = {}
    if not config then return entries end
    for _, rule in ipairs(config.profiles[1].complex_modifications.rules) do
        local app, keys, action = rule.description:match("^(.-)Hyper%+(%S+) → (.-)%s*%b()$")
        if not keys then
            app, keys, action = rule.description:match("^(.-)Hyper%+(%S+) → (.+)$")
        end
        if keys then
            app = app:gsub(":%s*$", "")
            table.insert(entries, {
                key = keys,
                desc = action:gsub("^%l", string.upper) .. (app ~= "" and " (" .. app .. ")" or ""),
            })
        end
    end
    return entries
end

local function cheatsheetText()
    local font = { name = "Maple Mono NF", size = 15 }
    local mocha = {
        text = { hex = "#cdd6f4" }, key = { hex = "#cba6f7" },
        section = { hex = "#89b4fa" }, dim = { hex = "#7f849c" },
    }
    local out = hs.styledtext.new("")
    local function add(str, color)
        out = out .. hs.styledtext.new(str, { font = font, color = color })
    end
    local function entry(key, desc)
        local label = keyLabels[key] or key:upper()
        -- Pad by characters, not bytes: "←" is three bytes in UTF-8
        add("  " .. label .. string.rep(" ", 8 - utf8.len(label)), mocha.key)
        add(desc .. "\n", mocha.text)
    end

    local order, bySection = {}, {}
    for _, e in ipairs(cheatsheet) do
        if not bySection[e.section] then
            bySection[e.section] = {}
            table.insert(order, e.section)
        end
        table.insert(bySection[e.section], e)
    end
    for _, name in ipairs(order) do
        add(name, mocha.section)
        add((sectionNotes[name] and "  · " .. sectionNotes[name] or "") .. "\n", mocha.dim)
        for _, e in ipairs(bySection[name]) do entry(e.key, e.desc) end
        add("\n", mocha.text)
    end
    local remaps = karabinerEntries()
    if #remaps > 0 then
        add("Karabiner\n", mocha.section)
        for _, e in ipairs(remaps) do entry(e.key, e.desc) end
        add("\n", mocha.text)
    end
    add("Release Hyper to close", mocha.dim)
    return out
end

local sheet
local function showCheatsheet()
    local text = cheatsheetText()
    local size = hs.drawing.getTextDrawingSize(text)
    local pad = 28
    local w, h = size.w + 2 * pad, size.h + 2 * pad
    local f = hs.screen.mainScreen():frame()
    sheet = hs.canvas.new({ x = f.x + (f.w - w) / 2, y = f.y + (f.h - h) / 2, w = w, h = h })
    sheet:appendElements(
        {
            type = "rectangle", action = "strokeAndFill",
            fillColor = { hex = "#1e1e2e", alpha = 0.97 },
            strokeColor = { hex = "#cba6f7" }, strokeWidth = 2,
            roundedRectRadii = { xRadius = 12, yRadius = 12 },
        },
        { type = "text", text = text, frame = { x = pad, y = pad, w = size.w + 4, h = size.h } }
    )
    sheet:level(hs.canvas.windowLevels.overlay):show()
end

local function hideCheatsheet()
    if sheet then sheet:delete(); sheet = nil end
end

-- Show after Hyper (all four modifiers, nothing else) has been held 1.2 s with
-- no key pressed, so normal chords never flash it. Globals so neither the tap
-- nor the timer is garbage-collected.
local types = hs.eventtap.event.types
cheatsheetTimer = nil
cheatsheetTap = hs.eventtap.new({ types.flagsChanged, types.keyDown }, function(e)
    local m = e:getFlags()
    local hyperOnly = m.cmd and m.alt and m.ctrl and m.shift
    if e:getType() == types.keyDown or not hyperOnly then
        if cheatsheetTimer then cheatsheetTimer:stop(); cheatsheetTimer = nil end
        hideCheatsheet()
    elseif not cheatsheetTimer and not sheet then
        cheatsheetTimer = hs.timer.doAfter(1.2, function()
            cheatsheetTimer = nil
            showCheatsheet()
        end)
    end
    return false
end):start()

hs.alert.show("\u{1F528} Hammerspoon loaded")
