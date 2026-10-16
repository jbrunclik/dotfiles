-- Hammerspoon config
-- Hyper key (Cmd+Option+Ctrl+Shift) via:
--   MacBook:    CapsLock (remapped by Karabiner-Elements)
--   Keyboardio: right thumb-cluster Fn key (set in firmware with Chrysalis;
--               backed up in config/keyboardio/model100.json)

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
    Messages = "again: hide",
}
local function bindHyper(key, section, desc, fn)
    table.insert(cheatsheet, { key = key, section = section, desc = desc })
    hs.hotkey.bind(hyper, ansiKeys[key] or key, fn)
end

-- A plain key (no Hyper) that should still be on the cheatsheet — e.g. F18,
-- which the Model 100's Any key sends. `label` is what the sheet shows.
-- F13–F20 are physical keys nothing in macOS or the apps uses.
local function bindPlain(key, label, section, desc, fn)
    table.insert(cheatsheet, { key = key, label = label, section = section, desc = desc })
    hs.hotkey.bind({}, key, fn)
end

-- Apps are looked up by bundle ID, never by name: a name matches any process
-- whose display name contains it, and Zoom runs a WebKit helper called
-- "zoom.us Sidebar Web Content" that getApp("zoom.us") returned
-- instead of Zoom — no windows, so layouts waited out their timeout and mute
-- reported "not in a meeting". Keys are the names used throughout this file.
local BUNDLE_IDS = {
    ["Ghostty"] = "com.mitchellh.ghostty",
    ["Dia"] = "company.thebrowser.dia",
    ["Google Chrome"] = "com.google.Chrome",
    ["Slack"] = "com.tinyspeck.slackmacgap",
    ["Notion"] = "notion.id",
    ["zoom.us"] = "us.zoom.xos",
    ["Messages"] = "com.apple.MobileSMS",
}

local function getApp(name)
    local id = BUNDLE_IDS[name]
    if not id then return hs.application.get(name) end
    return hs.application.applicationsForBundleID(id)[1]
end

local function launchApp(name)
    local id = BUNDLE_IDS[name]
    if id then hs.application.launchOrFocusByBundleID(id) else hs.application.launchOrFocus(name) end
end

-- Find the best window for an app (handles Zoom's multiple windows)
local function bestWindow(appName)
    local app = getApp(appName)
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
-- Cold start (an app not running, or running without a window): launchOrFocus()
-- returns before the window exists, and Slack or Notion take seconds to create
-- one. So poll every 0.1 s, up to 10 s, until both windows exist, then tile —
-- and move them once more 0.5 s later, because Electron apps restore their own
-- saved frame just after the window appears, undoing the first move. When both
-- apps already have windows, tiling takes ~50 ms (one timer tick).
local function tilePair(leftApp, rightApp)
    local lw = bestWindow(leftApp)
    local rw = bestWindow(rightApp)
    -- If both windows are already in position, cycle focus
    if isTiled(lw, left) and isTiled(rw, right) then
        local la = getApp(leftApp)
        if la and la:isFrontmost() then rw:focus() else lw:focus() end
        return
    end
    -- Launch any app that isn't running yet
    if not lw then launchApp(leftApp) end
    if not rw then launchApp(rightApp) end
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
    if lw and rw then
        tile()
        return
    end
    local deadline = hs.timer.secondsSinceEpoch() + 10
    hs.timer.waitUntil(function()
        lw = lw or bestWindow(leftApp)
        rw = rw or bestWindow(rightApp)
        return (lw and rw) or hs.timer.secondsSinceEpoch() > deadline
    end, function()
        tile()
        hs.timer.doAfter(0.5, function()
            if lw then lw:move(left) end
            if rw then rw:move(right) end
        end)
    end, 0.1)
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
-- Both presses go through bestWindow, so Zoom in a call means the call window,
-- never its meetings list ("Zoom Workplace"), and every app gets its real
-- window rather than whichever one macOS last activated.
for _, binding in ipairs(appKeys) do
    bindHyper(binding[1], "Apps", binding[3] or binding[2], function()
        local win = bestWindow(binding[2])
        if win and win == hs.window.focusedWindow() then
            win:maximize()
        elseif win then
            win:focus()
        else
            launchApp(binding[2])
        end
    end)
end

-- Check Zoom mute state by reading the toolbar button's accessibility description
local function isZoomMuted()
    local zoom = getApp("zoom.us")
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

-- Toggle Zoom mute from any app, without switching focus
local function toggleZoomMute()
    local zoom = getApp("zoom.us")
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
end
bindHyper("m", "Zoom", "Mute / unmute (from any app)", toggleZoomMute)
bindPlain("f18", "Any", "Zoom", "Mute / unmute (Model 100 Any key → F18)", toggleZoomMute)

-- Hyper+T = summon / dismiss Messages for a quick reply without touching the
-- current layout. Messages floats over the right third; pressing again hides
-- it, and macOS hands focus back to the app you were in. Nothing is remembered
-- between presses: whether Messages is frontmost decides. On a cold start,
-- wait (up to 5 s) for its window before placing it.
local messagesFrame = hs.geometry.rect(2 / 3, 0, 1 / 3, 1)
local function toggleMessages()
    local app = getApp("Messages")
    if app and app:isFrontmost() then
        app:hide()
        return
    end
    launchApp("Messages")
    local deadline = hs.timer.secondsSinceEpoch() + 5
    local function window()
        local messages = getApp("Messages")
        return messages and messages:mainWindow()
    end
    hs.timer.waitUntil(function()
        return window() or hs.timer.secondsSinceEpoch() > deadline
    end, function()
        local win = window()
        if win then win:move(messagesFrame) end
    end, 0.05)
end
bindHyper("t", "Messages", "Show / hide Messages", toggleMessages)
bindPlain("f19", "Prog", "Messages", "Show / hide Messages (Model 100 Prog key → F19)", toggleMessages)

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

-- The cheatsheet as data: Hammerspoon sections in bind order, then the
-- Karabiner remaps. Both the overlay and the printable PDF (the
-- hyper-cheatsheet script) render this, so they always list the same bindings.
local function cheatsheetSections()
    local sections, byName = {}, {}
    local function label(key) return keyLabels[key] or key:upper() end
    for _, e in ipairs(cheatsheet) do
        if not byName[e.section] then
            byName[e.section] = { name = e.section, note = sectionNotes[e.section], entries = {} }
            table.insert(sections, byName[e.section])
        end
        table.insert(byName[e.section].entries, { key = e.label or label(e.key), desc = e.desc })
    end
    local remaps = karabinerEntries()
    if #remaps > 0 then
        local karabiner = { name = "Karabiner", entries = {} }
        for _, e in ipairs(remaps) do
            table.insert(karabiner.entries, { key = label(e.key), desc = e.desc })
        end
        table.insert(sections, karabiner)
    end
    return sections
end

-- Used by the hyper-cheatsheet script: writes the sections, plus the CapsLock
-- rule's description, as JSON to `path`. Global so `hs -c` can call it.
function hyperCheatsheetExport(path)
    local config = hs.json.read(configDir .. "/../karabiner/karabiner.json")
    local caps
    for _, rule in ipairs(config and config.profiles[1].complex_modifications.rules or {}) do
        if rule.description:match("^CapsLock") then caps = rule.description end
    end
    return hs.json.write({ sections = cheatsheetSections(), caps = caps }, path, false, true)
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
    for _, section in ipairs(cheatsheetSections()) do
        add(section.name, mocha.section)
        add((section.note and "  · " .. section.note or "") .. "\n", mocha.dim)
        for _, e in ipairs(section.entries) do
            -- Pad by characters, not bytes: "←" is three bytes in UTF-8
            add("  " .. e.key .. string.rep(" ", 8 - utf8.len(e.key)), mocha.key)
            add(e.desc .. "\n", mocha.text)
        end
        add("\n", mocha.text)
    end
    add("Release Hyper to close", mocha.dim)
    return out
end

-- The overlay, centered on the main screen; not shown yet
local function cheatsheetCanvas()
    local text = cheatsheetText()
    local size = hs.drawing.getTextDrawingSize(text)
    local pad = 28
    local w, h = size.w + 2 * pad, size.h + 2 * pad
    local f = hs.screen.mainScreen():frame()
    local canvas = hs.canvas.new({ x = f.x + (f.w - w) / 2, y = f.y + (f.h - h) / 2, w = w, h = h })
    canvas:appendElements(
        {
            type = "rectangle", action = "strokeAndFill",
            fillColor = { hex = "#1e1e2e", alpha = 0.97 },
            strokeColor = { hex = "#cba6f7" }, strokeWidth = 2,
            roundedRectRadii = { xRadius = 12, yRadius = 12 },
        },
        { type = "text", text = text, frame = { x = pad, y = pad, w = size.w + 4, h = size.h } }
    )
    return canvas
end

-- Used by `hyper-cheatsheet --readme`: renders the overlay to a PNG for the
-- README. Drawn from the canvas itself, never a screenshot, so nothing else on
-- screen can end up in the image.
function hyperCheatsheetImage(path)
    local canvas = cheatsheetCanvas()
    local ok = canvas:imageFromCanvas():saveToFile(path)
    canvas:delete()
    return ok
end

local sheet
local function showCheatsheet()
    sheet = cheatsheetCanvas()
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
