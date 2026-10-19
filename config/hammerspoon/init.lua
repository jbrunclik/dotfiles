-- Hammerspoon config
-- Hyper key (Cmd+Option+Ctrl+Shift) via:
--   MacBook:    CapsLock (remapped by Karabiner-Elements)
--   Keyboardio: right thumb-cluster Fn key (set in firmware with Chrysalis;
--               backed up in config/keyboardio/model100.json)

require("hs.ipc")

local hyper = { "cmd", "alt", "ctrl", "shift" }

-- Window moves are instant: the default 0.2 s slide made every tile, layout
-- and the Messages float visibly animate into place
hs.window.animationDuration = 0

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
    ["7"] = 26, ["8"] = 28, ["9"] = 25, ["0"] = 29, [","] = 43, ["`"] = 50,
}
local cheatsheet = {}
-- What pressing a key again does, shown once per cheatsheet section
local sectionNotes = {
    Layouts = "again: swap focus",
    Apps = "again: beside",
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
    ["Claude"] = "com.anthropic.claudefordesktop",
    ["WhatsApp"] = "net.whatsapp.WhatsApp",
    ["Visual Studio Code"] = "com.microsoft.VSCode",
    ["1Password"] = "com.1password.1password",
    ["Finder"] = "com.apple.finder",
    ["System Settings"] = "com.apple.systempreferences",
    ["Music"] = "com.apple.Music",
    ["Signal"] = "org.whispersystems.signal-desktop",
    ["KeepingYouAwake"] = "info.marcel-dierkes.KeepingYouAwake",
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

local threshold = 20

-- Check if a window occupies a given unit rect of its screen (position only)
local function inPosition(win, unitRect)
    if not win then return false end
    local f = win:frame()
    local s = win:screen():frame()
    return math.abs(f.x - (s.x + unitRect.x * s.w)) < threshold
        and math.abs(f.y - (s.y + unitRect.y * s.h)) < threshold
        and math.abs(f.w - unitRect.w * s.w) < threshold
        and math.abs(f.h - unitRect.h * s.h) < threshold
end

-- Check if a window occupies a given unit rect AND is the topmost window there.
-- Position-only checks are fooled by windows stacked at the same coordinates
-- (e.g. Slack and Dia both tiled right, with one covering the other).
local function isTiled(win, unitRect)
    if not inPosition(win, unitRect) then return false end
    local f = win:frame()
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

-- Apps whose window has to be opened rather than launched: with no Finder
-- window open, Finder's "main window" is the Desktop
local openers = {
    Finder = function() hs.task.new("/usr/bin/open", nil, { os.getenv("HOME") }):start() end,
}

-- Call ready(wins) once every named app has a standard window (bestWindow),
-- launching any that hasn't. Shared by the layouts and "beside".
--
-- Cold start (an app not running, or running without a window): launchOrFocus()
-- returns before the window exists, and Slack or Notion take seconds to create
-- one. So poll every 0.1 s, up to 10 s, until the windows exist, then call
-- ready — and again 0.5 s later with settling = true (move only, no focus),
-- because Electron apps restore their own saved frame just after the window
-- appears, undoing the first move. A window still missing at the deadline is
-- nil in wins. When all windows already exist, ready runs at once.
local function whenWindows(names, ready)
    local wins = {}
    local function found()
        local all = true
        for i, name in ipairs(names) do
            if not wins[i] then
                local w = bestWindow(name)
                if w and w:isStandard() then wins[i] = w else all = false end
            end
        end
        return all
    end
    -- A hidden app's windows are invisible to Hammerspoon until it's unhidden,
    -- so unhide first and give its windows 0.3 s to show (they take ~20 ms)
    -- before opening one — otherwise Finder's opener adds a second window
    -- next to the hidden one
    local unhidden = {}
    for i, name in ipairs(names) do
        local app = getApp(name)
        if app and app:isHidden() then
            app:unhide()
            unhidden[i] = true
        end
    end
    if found() then
        ready(wins)
        return
    end
    local function open(hidden)
        for i, name in ipairs(names) do
            if not wins[i] and (unhidden[i] or false) == hidden then
                (openers[name] or launchApp)(name)
            end
        end
    end
    open(false)
    local start, graceOver = hs.timer.secondsSinceEpoch(), false
    hs.timer.waitUntil(function()
        if found() then return true end
        local elapsed = hs.timer.secondsSinceEpoch() - start
        if not graceOver and elapsed > 0.3 then
            graceOver = true
            open(true)
        end
        return elapsed > 10
    end, function()
        ready(wins)
        hs.timer.doAfter(0.5, function() ready(wins, true) end)
    end, 0.1)
end

-- Raise `back`, then `front` over it. Rapid focus() calls race with the macOS
-- window server — the second call lands before the first is processed, so the
-- final z-order is unpredictable. A 50 ms gap lets each call settle; it's
-- imperceptible to humans but enough for the window server.
local function raisePair(back, front)
    if back then back:focus() end
    hs.timer.doAfter(0.05, function()
        if front then front:focus() end
    end)
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
local function tilePair(leftApp, rightApp)
    local lw = bestWindow(leftApp)
    local rw = bestWindow(rightApp)
    -- If both windows are already in position, cycle focus
    if isTiled(lw, left) and isTiled(rw, right) then
        local la = getApp(leftApp)
        if la and la:isFrontmost() then rw:focus() else lw:focus() end
        return
    end
    whenWindows({ leftApp, rightApp }, function(wins, settling)
        local l, r = wins[1], wins[2]
        if l then l:move(left) end
        if r then r:move(right) end
        -- Right first (brings it above the old occupant), then left on top
        if not settling then raisePair(r, l) end
    end)
end

-- Put an app's window on the other half from `anchor`, the window you're
-- working in: an anchor tiled right stays right and the app goes left;
-- tiled left, maximized or anything else, the anchor takes the left half.
-- The app ends up focused — it was summoned to be used. Whatever was on that
-- half stays underneath (Hyper+` reaches it). Sides are decided from the
-- anchor's live frame on every call, so the Electron re-move lands the same.
local function placeBeside(name, anchor)
    if not anchor then return end
    whenWindows({ name }, function(wins, settling)
        local win = wins[1]
        if not win or win == anchor then return end
        local anchorHalf, otherHalf = left, right
        if inPosition(anchor, right) then anchorHalf, otherHalf = right, left end
        anchor:move(anchorHalf)
        win:move(otherHalf)
        if not settling then raisePair(anchor, win) end
    end)
end

-- Layouts (bottom row: Z, X, C, V)
bindHyper("z", "Layouts", "Ghostty | Dia", function() tilePair("Ghostty", "Dia") end)
bindHyper("x", "Layouts", "Zoom | Notion", function() tilePair("zoom.us", "Notion") end)
bindHyper("c", "Layouts", "Zoom | Slack", function() tilePair("zoom.us", "Slack") end)
bindHyper("v", "Layouts", "Zoom | Dia", function() tilePair("zoom.us", "Dia") end)

-- Hyper+Tab = toggle focus between left and right windows.
-- These three only consider standard windows: the input-mode indicator macOS
-- shows beside the cursor after a US/CZ switch is an AXDialog owned by the
-- front app, sits on top of the z-order, and would otherwise be "focused" —
-- a press that does nothing. Zoom's control strips are non-standard too.
bindHyper("tab", "Windows", "Focus the other half", function()
    local screen = hs.screen.mainScreen()
    local mid = screen:frame().w / 2
    local current = hs.window.focusedWindow()
    if not current then return end
    local targetSide = current:frame().x < mid and "right" or "left"
    local wins = hs.fnutils.filter(hs.window.orderedWindows(), function(w)
        if not w:isStandard() then
            return false
        elseif targetSide == "left" then
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
        return w:isStandard() and w:frame().x < hs.screen.mainScreen():frame().w / 2
    end)
    if wins[1] then wins[1]:focus() end
end)

bindHyper("right", "Windows", "Focus right half", function()
    local wins = hs.fnutils.filter(hs.window.orderedWindows(), function(w)
        return w:isStandard() and w:frame().x >= hs.screen.mainScreen():frame().w / 2
    end)
    if wins[1] then wins[1]:focus() end
end)

-- Hyper+` = cycle the windows stacked where the focused one is (Slack and
-- Notion both tiled right, two maximized windows, two floats at the same
-- spot) — Cmd+`, but per spot instead of per app. Each press brings the
-- bottom-most window of the stack to the front: with A over B over C that's
-- C, then B, then A again. Raising the one just below the top would only
-- ever flip between the top two. Derived from live frames and z-order.
bindHyper("`", "Windows", "Cycle windows stacked on this half", function()
    local current = hs.window.focusedWindow()
    if not current then return end
    local f = current:frame()
    local function samePlace(w)
        local g = w:frame()
        return w:isStandard() and math.abs(g.x - f.x) < 20 and math.abs(g.y - f.y) < 20
            and math.abs(g.w - f.w) < 20 and math.abs(g.h - f.h) < 20
    end
    local stack = hs.fnutils.filter(hs.window.orderedWindows(), samePlace)
    if #stack > 1 then stack[#stack]:focus() end
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

-- Hyper+S again, on a window that's already maximized, puts it back on a half:
-- the one not taken by the next standard window below it (so terminal
-- maximized over Slack-on-the-right goes left). Decided from that window's
-- live center, nothing remembered; with nothing below, left.
bindHyper("s", "Windows", "Maximize (again: back to a half)", function()
    local win = hs.window.focusedWindow()
    if not win then return end
    if not inPosition(win, hs.geometry.rect(0, 0, 1, 1)) then
        win:maximize()
        return
    end
    local below = hs.fnutils.find(hs.window.orderedWindows(), function(w)
        return w ~= win and w:isStandard()
    end)
    local s = win:screen():frame()
    local belowLeft = below and below:frame().center.x < s.x + s.w / 2
    win:move(belowLeft and right or left)
end)

-- Hyper+Q = send the front app to the background, as Cmd+H does: macOS hands
-- focus back to the app used before. Cmd+Q next to it is the real quit; a
-- stray Hyper+Q only hides, and Hyper+1–6 or the launcher bring it back.
bindHyper("q", "Windows", "Hide the front app (like Cmd+H)", function()
    local app = hs.application.frontmostApplication()
    if app then app:hide() end
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
-- The second press puts the app beside the window you came from: the next
-- standard window below it in z-order, so nothing is remembered. With nothing
-- to pair with it maximizes, as Hyper+S does.
local function focusApp(name)
    local win = bestWindow(name)
    if win and win == hs.window.focusedWindow() then
        local cameFrom = hs.fnutils.find(hs.window.orderedWindows(), function(w)
            return w ~= win and w:isStandard()
        end)
        if cameFrom then placeBeside(name, cameFrom) else win:maximize() end
    elseif win then
        win:focus()
    else
        launchApp(name)
    end
end
-- App name → its Hyper key, for the launcher panel's hints
local appHyperKeys = {}
for _, binding in ipairs(appKeys) do
    appHyperKeys[binding[2]] = binding[1]
    bindHyper(binding[1], "Apps", binding[3] or binding[2], function() focusApp(binding[2]) end)
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

-- Hyper+Return = start / join the meeting that's about to begin, from any app.
-- The work calendar isn't in macOS Calendar, but Zoom's home window has it: its
-- calendar sidebar is a web view whose cards are readable through AX, and
-- about 10 minutes before a Zoom meeting (once it's under way too) the card
-- gains a button titled "Start" (you host) or "Join" — for any meeting link,
-- not only Zoom's: Join on a Teams meeting opens it in the browser. The cards
-- with that button are the candidates, minus meetings that have already ended
-- (a finished meeting still open in Zoom keeps its button). The one whose start
-- is nearest to now wins — at 16:29, the 16:30 meeting beats the one running
-- since 16:00, which you're presumably in. Only starts within 5 minutes of
-- each other ask (a picker, soonest first); none → say so. A hidden Zoom is unhidden first (its windows are invisible
-- to AX until then); a quit one is launched, and its sidebar takes ~9 s to load.
local function zoomMeetingCards()
    local zoom = getApp("zoom.us")
    if not zoom then return {} end
    local ax = hs.axuielement.applicationElement(zoom)
    ax:setTimeout(1)
    local cards = {}
    local function walk(e, depth)
        if depth > 16 then return end
        local children = e:attributeValue("AXChildren") or {}
        if e:attributeValue("AXRole") == "AXGroup" then
            local name, button
            for _, c in ipairs(children) do
                local role = c:attributeValue("AXRole")
                if role == "AXStaticText" and not name then name = c:attributeValue("AXValue") end
                if role == "AXButton" then
                    local t = c:attributeValue("AXTitle")
                    if t == "Start" or t == "Join" then button = c end
                end
            end
            if button then
                -- The card's own title reads "<name> In 6 min … 15:30 - 15:55 …"
                table.insert(cards, { name = name or "?", detail = e:attributeValue("AXTitle") or "", button = button })
                return
            end
        end
        for _, c in ipairs(children) do walk(c, depth + 1) end
    end
    for _, w in ipairs(ax:attributeValue("AXWindows") or {}) do walk(w, 0) end
    return cards
end
-- The card's title is its screen-reader text: "<name> <status> [Repeating
-- event Repeating event] 15:30 - 15:55 Organizer: … press Tab for more
-- options…". Status is "In 8 min", "Now" or a date. Pull out status and times,
-- drop meetings that ended (unless that leaves nothing), keep the nearest.
local function chooseMeetings(found, nowMin)
    -- Minutes since midnight from "15:30" or "3:30 PM"; nil if it doesn't parse
    local function minutes(h, m, ampm)
        h, m = tonumber(h), tonumber(m)
        ampm = (ampm or ""):upper()
        if ampm == "PM" and h < 12 then h = h + 12 elseif ampm == "AM" and h == 12 then h = 0 end
        return h * 60 + m
    end
    local all, open = {}, {}
    for _, c in ipairs(found) do
        local rest = c.detail:sub(#c.name + 2)
        local sh, sm, sap, eh, em, eap =
            rest:match("(%d%d?):(%d%d)%s*([AaPp]?[Mm]?)%s*[-–]%s*(%d%d?):(%d%d)%s*([AaPp]?[Mm]?)")
        c.status = rest:match("^(.-) Repeating event") or rest:match("^(.-) %d%d?:%d%d") or ""
        c.start = sh and minutes(sh, sm, sap ~= "" and sap or eap)
        local ending = eh and minutes(eh, em, eap)
        c.time = c.start and string.format("%02d:%02d – %02d:%02d", c.start // 60, c.start % 60, ending // 60, ending % 60) or ""
        table.insert(all, c)
        -- Over = ended earlier today. Not over: an end before the start (it
        -- runs past midnight), or a start in the next 12 hours counting across
        -- midnight (at 23:58, 00:05–00:30 is tonight's, not this morning's)
        local upcoming = c.start and (c.start - nowMin) % 1440 < 720
        if not ending or ending < c.start or ending > nowMin or upcoming then table.insert(open, c) end
    end
    local cards = #open > 0 and open or all
    local timed = {}
    for _, c in ipairs(cards) do
        if c.start then
            -- Around the clock: at 23:58 a 00:05 start is 7 minutes away
            local d = math.abs(c.start - nowMin)
            c.distance = math.min(d, 1440 - d)
            table.insert(timed, c)
        end
    end
    -- No card's time parsed: offer them all rather than nothing
    if #timed == 0 then return cards end
    table.sort(timed, function(a, b) return a.distance < b.distance end)
    -- Keep the nearest, plus any about as near (genuinely simultaneous starts)
    local picked = {}
    for _, c in ipairs(timed) do
        if c.distance - timed[1].distance < 5 then table.insert(picked, c) end
    end
    table.sort(picked, function(a, b) return a.start < b.start end)
    return picked
end
local function meetingCandidates()
    local now = os.date("*t")
    return chooseMeetings(zoomMeetingCards(), now.hour * 60 + now.min)
end
-- Global so `hs -c` can show what Hyper+Return would do, without pressing.
-- Tests pass made-up cards ({ name, detail } — detail as the card title reads)
-- and minutes since midnight instead of the live Zoom window and clock.
function zoomJoinableMeetings(cards, nowMin)
    local picked = cards and chooseMeetings(cards, nowMin) or meetingCandidates()
    local out = {}
    for _, c in ipairs(picked) do
        table.insert(out, string.format("%s (%s · %s)", c.name, c.status, c.time))
    end
    return (#picked > 1 and "picker: " or "press: ") .. table.concat(out, " | ")
end

local function pressMeeting(cards)
    if #cards == 1 then
        cards[1].button:performAction("AXPress")
        return
    end
    local chooser = hs.chooser.new(function(choice)
        if choice then cards[choice.index].button:performAction("AXPress") end
    end)
    local choices = {}
    for i, c in ipairs(cards) do
        table.insert(choices, { text = c.name, subText = c.status .. " · " .. c.time, index = i })
    end
    -- Sized to the meetings, not the default screenful; ⌘1–9 pick a row
    chooser:choices(choices):rows(#choices):width(30):show()
end

local function joinNextMeeting()
    local zoom = getApp("zoom.us")
    if zoom and zoom:isHidden() then zoom:unhide() end
    if zoom then
        local cards = meetingCandidates()
        if #cards > 0 then pressMeeting(cards) return end
        if #zoom:allWindows() > 0 then
            hs.alert.show("\u{1F4C5} No Zoom meeting starting soon")
            return
        end
    end
    -- Not running, or no home window: open it and wait for the sidebar
    launchApp("zoom.us")
    local deadline, cards = hs.timer.secondsSinceEpoch() + 15, {}
    hs.timer.waitUntil(function()
        cards = meetingCandidates()
        return #cards > 0 or hs.timer.secondsSinceEpoch() > deadline
    end, function()
        if #cards > 0 then pressMeeting(cards) else hs.alert.show("\u{1F4C5} No Zoom meeting starting soon") end
    end, 0.5)
end
bindHyper("return", "Zoom", "Start / join the meeting about to begin", joinNextMeeting)

-- Hyper+0 = toggle KeepingYouAwake through its URL scheme, no menu bar click.
-- Its state isn't visible otherwise, so the alert says which way it went.
-- The state is read, never assumed: while active it runs a `caffeinate` child
-- process. Hyper+0 asks for the opposite of what's running now (activate or
-- deactivate, not its blind `toggle`), then waits up to 2 s for the process to
-- match and reports what it finds — so a manual click on the icon in between
-- can't put the alert out of step.
local function awakeOn()
    local app = getApp("KeepingYouAwake")
    return app ~= nil and hs.execute("/usr/bin/pgrep -P " .. app:pid() .. " caffeinate"):match("%d") ~= nil
end

local function toggleAwake()
    local want = not awakeOn()
    hs.urlevent.openURL("keepingyouawake:///" .. (want and "activate" or "deactivate"))
    local deadline = hs.timer.secondsSinceEpoch() + 2
    hs.timer.waitUntil(function()
        return awakeOn() == want or hs.timer.secondsSinceEpoch() > deadline
    end, function()
        local on = awakeOn()
        hs.alert.show((on and "\u{2615} Awake: on" or "\u{1F634} Awake: off")
            .. (on ~= want and " (didn't change)" or ""))
    end, 0.1)
end
bindHyper("0", "Utilities", "Keep the Mac awake (KeepingYouAwake on / off)", toggleAwake)

-- Quick-reply floats: summon / dismiss a messenger without touching the
-- current layout. It floats over the right third; pressing again hides it,
-- and macOS hands focus back to the app you were in. Nothing is remembered
-- between presses: whether the app is frontmost decides. On a cold start,
-- wait (up to 5 s) for its window before placing it.
--
-- Each app refuses to be narrower than a minimum (measured), wider than a
-- third of the MacBook screen (504 pt): asked for a third, it kept the
-- third's left edge and ran off the right. A fixed property of the app, not
-- window state, so constants rather than something read back. The float is
-- a third, flush right — or two thirds where the minimum won't fit a third.
local FLOAT_MIN_WIDTH = {
    Messages = 660,
    WhatsApp = 800,
}

local function placeFloat(win, minWidth)
    local s = win:screen():frame()
    -- A third, or two thirds where the app can't fit in a third (both
    -- messengers on the MacBook): squeezed to its minimum, the fixed
    -- sidebars leave the conversation a narrow strip
    local w = minWidth > s.w / 3 and s.w * 2 / 3 or s.w / 3
    win:setFrame({ x = s.x + s.w - w, y = s.y, w = w, h = s.h })
    -- Fallback if a minimum ever grows: apps widen themselves back only some
    -- time after a move, so watch for an overflow for 1.5 s and pin the
    -- right edge
    local deadline = hs.timer.secondsSinceEpoch() + 1.5
    hs.timer.waitUntil(function()
        local f = win:frame()
        return f.x + f.w > s.x + s.w + 1 or hs.timer.secondsSinceEpoch() > deadline
    end, function()
        local f = win:frame()
        if f.x + f.w > s.x + s.w + 1 then
            f.x = s.x + s.w - f.w
            win:setFrame(f)
        end
    end, 0.05)
end

local function toggleFloat(name)
    local app = getApp(name)
    if app and app:isFrontmost() then
        app:hide()
        return
    end
    local function window()
        local running = getApp(name)
        return running and running:mainWindow()
    end
    local minWidth = FLOAT_MIN_WIDTH[name] or 0
    -- Running (hidden or behind): unhide and place in the same tick, so it
    -- doesn't show at its old spot first
    if app then
        app:unhide()
        local win = window()
        if win then
            placeFloat(win, minWidth)
            win:focus()
            return
        end
    end
    -- Cold start: wait (up to 5 s) for its window
    launchApp(name)
    local deadline = hs.timer.secondsSinceEpoch() + 5
    hs.timer.waitUntil(function()
        return window() or hs.timer.secondsSinceEpoch() > deadline
    end, function()
        local win = window()
        if win then placeFloat(win, minWidth) end
    end, 0.05)
end
local function toggleMessages() toggleFloat("Messages") end
bindHyper("t", "Messages", "Show / hide Messages", toggleMessages)
appHyperKeys["Messages"] = "t"
bindPlain("f19", "Prog", "Messages", "Show / hide Messages (Model 100 Prog key → F19)", toggleMessages)

-- No reload key: saving a .lua file reloads (below), so Hyper+R is free for
-- something used daily. Without an edit: `(hs -c 'hs.reload()' &)`.

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
local keyLabels = { tab = "Tab", left = "←", right = "→", space = "Space", ["return"] = "Return" }

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

-- Sections ({ name, note, entries = {{ key, desc }} }) as Catppuccin styled
-- text with `footer` dimmed at the end; the cheatsheet and the launcher panel
-- both draw with it
local function overlayText(sections, footer)
    local font = { name = "Maple Mono NF", size = 15 }
    local mocha = {
        text = { hex = "#cdd6f4" }, key = { hex = "#cba6f7" },
        section = { hex = "#89b4fa" }, dim = { hex = "#7f849c" },
    }
    local out = hs.styledtext.new("")
    local function add(str, color)
        out = out .. hs.styledtext.new(str, { font = font, color = color })
    end
    -- Three columns: key, description, and a dimmed hint — the entry's `hint`,
    -- else a trailing "(…)" split off the description. Widths come from the
    -- widest cell across all sections, counted in characters, not bytes ("←"
    -- is three bytes in UTF-8); the font is monospaced.
    local rows, keyW, descW = {}, 0, 0
    for _, section in ipairs(sections) do
        for _, e in ipairs(section.entries) do
            local desc, hint = e.desc, e.hint
            if not hint then
                local main, paren = desc:match("^(.-)%s+(%b())$")
                if main then desc, hint = main, paren end
            end
            rows[e] = { desc = desc, hint = hint }
            keyW = math.max(keyW, utf8.len(e.key))
            if hint then descW = math.max(descW, utf8.len(desc)) end
        end
    end
    local function pad(str, width) return str .. string.rep(" ", width - utf8.len(str)) end
    for i, section in ipairs(sections) do
        add(section.name, mocha.section)
        add((section.note and "  · " .. section.note or "") .. "\n", mocha.dim)
        for _, e in ipairs(section.entries) do
            local row = rows[e]
            add("  " .. pad(e.key, keyW + 3), mocha.key)
            if row.hint then
                add(pad(row.desc, descW + 3), mocha.text)
                add(row.hint .. "\n", mocha.dim)
            else
                add(row.desc .. "\n", mocha.text)
            end
        end
        if footer ~= "" or i < #sections then add("\n", mocha.text) end
    end
    add(footer, mocha.dim)
    return out
end

-- An overlay of `texts` side by side, one column each, centered on the main
-- screen; not shown yet
local function overlayCanvas(texts)
    local pad, gap = 28, 48
    local sizes, w, h = {}, 2 * pad - gap, 0
    for i, text in ipairs(texts) do
        sizes[i] = hs.drawing.getTextDrawingSize(text)
        w, h = w + sizes[i].w + gap, math.max(h, sizes[i].h)
    end
    h = h + 2 * pad
    local f = hs.screen.mainScreen():frame()
    local canvas = hs.canvas.new({ x = f.x + (f.w - w) / 2, y = f.y + (f.h - h) / 2, w = w, h = h })
    canvas:appendElements({
        type = "rectangle", action = "strokeAndFill",
        fillColor = { hex = "#1e1e2e", alpha = 0.97 },
        strokeColor = { hex = "#cba6f7" }, strokeWidth = 2,
        roundedRectRadii = { xRadius = 12, yRadius = 12 },
    })
    local x = pad
    for i, text in ipairs(texts) do
        canvas:appendElements({ type = "text", text = text, frame = { x = x, y = pad, w = sizes[i].w + 4, h = sizes[i].h } })
        x = x + sizes[i].w + gap
    end
    return canvas
end

-- The cheatsheet in as few columns as fit the main screen's height (one on
-- the 5K, more on the MacBook). Sections stay whole and in order; each column
-- takes sections until it reaches the line budget, raised until the sections
-- fit in that many columns, so the columns come out about even.
local function cheatsheetColumns(sections, footer)
    local maxH = hs.screen.mainScreen():frame().h - 2 * 28 - 40
    local lines, total = {}, 0
    for i, section in ipairs(sections) do
        lines[i] = #section.entries + 2
        total = total + lines[i]
    end
    local columns
    for n = 1, #sections do
        local limit = math.ceil(total / n)
        repeat
            columns = { {} }
            local used = 0
            for i, section in ipairs(sections) do
                if used > 0 and used + lines[i] > limit then
                    table.insert(columns, {}); used = 0
                end
                table.insert(columns[#columns], section)
                used = used + lines[i]
            end
            limit = limit + 1
        until #columns <= n
        local texts, fits = {}, true
        for i, column in ipairs(columns) do
            texts[i] = overlayText(column, i == #columns and footer or "")
            fits = fits and hs.drawing.getTextDrawingSize(texts[i]).h <= maxH
        end
        if fits or n == #sections then return texts end
    end
end

local function cheatsheetCanvas()
    return overlayCanvas(cheatsheetColumns(cheatsheetSections(), "Release Hyper to close"))
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

-- Hyper+Space = launcher: a panel of one-key shortcuts for apps without a
-- Hyper key of their own, plus the ones with (hinted), so it's a complete map.
-- Press the key with no modifiers and the app comes forward as with Hyper+1–6;
-- if it's already in front, it hides instead.
-- Escape, any other key, Hyper+Space again or 3 s of nothing closes it. Keys
-- go through an eventtap that runs only while the panel is up and swallows
-- them, so they never reach the app underneath or clash with its shortcuts.
-- Matched by physical key code, like bindHyper, so they survive the Czech
-- layout. Everything else stays with Spotlight.
-- Panel order: apps with a Hyper key (in Hyper order), the rest
-- alphabetically, System Settings last.
local launcherApps = {
    { "g", "Ghostty" },
    { "d", "Dia" },
    { "h", "Google Chrome", "Chrome" },
    { "s", "Slack" },
    { "n", "Notion" },
    { "z", "zoom.us", "Zoom" },
    { "t", "Messages" },
    { "1", "1Password" },
    { "c", "Claude" },
    { "f", "Finder" },
    { "m", "Music" },
    { "v", "Visual Studio Code", "VS Code" },
    { "w", "WhatsApp" },
    { ",", "System Settings" },
}
local launcherActions = {
    -- The same float-over-the-right-third as Hyper+T
    Messages = toggleMessages,
    WhatsApp = function() toggleFloat("WhatsApp") end,
    -- With no Finder window open, its "main window" is the Desktop: open one
    Finder = function()
        local win = bestWindow("Finder")
        if win and win:isStandard() then focusApp("Finder") else openers.Finder() end
    end,
}

-- Shift+key puts the app beside the front window instead (placeBeside) — a
-- tiled half even for Messages, whose plain key floats it
local launcherByCode, launcherEntries, launcherBeside = {}, {}, {}
for _, app in ipairs(launcherApps) do
    local key, name = app[1], app[2]
    -- An app already in front hides instead, so the same key summons and
    -- dismisses it (Messages' toggle does this itself)
    local action = launcherActions[name] or function() focusApp(name) end
    launcherByCode[ansiKeys[key]] = function()
        local running = getApp(name)
        if running and running:isFrontmost() then running:hide() else action() end
    end
    launcherBeside[ansiKeys[key]] = function() placeBeside(name, hs.window.focusedWindow()) end
    local hyperKey = appHyperKeys[name]
    table.insert(launcherEntries, {
        key = key:upper(),
        desc = app[3] or name,
        hint = hyperKey and "Hyper+" .. hyperKey:upper(),
    })
end

local launcherPanel, launcherTimer
local function closeLauncher()
    if launcherTimer then launcherTimer:stop(); launcherTimer = nil end
    launcherTap:stop()
    if launcherPanel then launcherPanel:delete(); launcherPanel = nil end
end
-- Global so it isn't garbage-collected. Hyper+Space itself never reaches it:
-- hotkeys are dispatched before event taps see the key.
launcherTap = hs.eventtap.new({ types.keyDown }, function(e)
    local m = e:getFlags()
    local action = not (m.cmd or m.alt or m.ctrl)
        and (m.shift and launcherBeside or launcherByCode)[e:getKeyCode()]
    closeLauncher()
    if action then action() end
    return true
end)

bindHyper("space", "Launcher", "App launcher: then one key (panel lists them)", function()
    if launcherPanel then closeLauncher(); return end
    launcherPanel = overlayCanvas({ overlayText(
        { { name = "Launcher", entries = launcherEntries } }, "Shift+key: beside this window · Esc or any other key to close") })
    launcherPanel:level(hs.canvas.windowLevels.overlay):show()
    launcherTap:start()
    launcherTimer = hs.timer.doAfter(3, closeLauncher)
end)

-- Screen-share guard: when a Zoom share starts, hide the apps that shouldn't
-- be on a shared screen — messengers and the personal browser. Zoom opens a
-- window titled "zoom share toolbar window" only while you share (observed
-- live; also a "zoom share statusbar window"), destroyed on stop and created
-- afresh on each share, so its appearance is the trigger. Checked every
-- 0.5 s: hs.window.filter caught only the first share's window — Zoom's
-- floating windows don't reliably send the AX notifications it relies on.
-- Nothing is restored afterwards: they stay hidden until summoned (Hyper+4,
-- Hyper+T, the launcher), so a second share can't re-expose them. Silent on
-- purpose: an alert would land on the very screen being shared.
-- Banners are macOS's job: with "Allow notifications when mirroring or sharing
-- the display" off (the default), it suppresses them during a Zoom share.
local SHARE_HIDE = { "Slack", "Messages", "WhatsApp", "Signal", "Dia" }

local function hideForShare()
    local hidden = {}
    for _, name in ipairs(SHARE_HIDE) do
        local app = getApp(name)
        if app and not app:isHidden() then
            app:hide()
            table.insert(hidden, name)
        end
    end
    -- Some apps ignore the hide request (Dia does: hide() and stays put).
    -- Their own "Hide <App>" menu item — what Cmd+H does — works, so use it
    -- for anything still visible a moment later.
    hs.timer.doAfter(0.3, function()
        for _, name in ipairs(hidden) do
            local app = getApp(name)
            if app and not app:isHidden() then app:selectMenuItem("Hide " .. name) end
        end
    end)
end

-- What Zoom is sharing: nil, "screen" or "window". Read through AX with a
-- short timeout rather than allWindows(): this runs every 0.5 s on
-- Hammerspoon's main thread, and a hung Zoom would otherwise hold it for the
-- default AX timeout each tick — every hotkey frozen. While Zoom isn't
-- running the check is just a bundle-ID lookup (~1 ms with it up).
-- A share always opens "zoom share toolbar window"; its "Annotation - Zoom"
-- window covers exactly what's shared (observed live): the whole screen,
-- menu bar included, for a screen share; the window's own frame for a window
-- share. No annotation window found → assume the screen, the safe side.
local function zoomShare()
    local zoom = getApp("zoom.us")
    if not zoom then return nil end
    local ax = hs.axuielement.applicationElement(zoom)
    ax:setTimeout(0.25)
    local ok, windows = pcall(function() return ax:attributeValue("AXWindows") end)
    local sharing, annotation = false, nil
    for _, w in ipairs(ok and windows or {}) do
        local title = w:attributeValue("AXTitle")
        if title == "zoom share toolbar window" then sharing = true end
        if title == "Annotation - Zoom" then
            local pos, size = w:attributeValue("AXPosition"), w:attributeValue("AXSize")
            if pos and size then annotation = hs.geometry.rect(pos.x, pos.y, size.w, size.h) end
        end
    end
    if not sharing then return nil end
    if not annotation then return "screen" end
    for _, screen in ipairs(hs.screen.allScreens()) do
        local f = screen:fullFrame()
        if math.abs(f.x - annotation.x) < 2 and math.abs(f.y - annotation.y) < 2
            and math.abs(f.w - annotation.w) < 2 and math.abs(f.h - annotation.h) < 2 then
            return "screen"
        end
    end
    return "window"
end

-- Only the off → on edge hides; `wasScreenShare` is re-derived from Zoom's
-- live windows every tick. Global so the timer isn't garbage-collected.
-- A window share shows viewers that one window only — hiding the other apps
-- protects nothing, and hid the very app being shared (a Dia window) — so
-- only a screen share hides. A share that changes from window to screen
-- (Zoom's "Share" again) counts as starting.
local wasScreenShare = zoomShare() == "screen"
shareGuard = hs.timer.doEvery(0.5, function()
    local screenShare = zoomShare() == "screen"
    if screenShare and not wasScreenShare then hideForShare() end
    wasScreenShare = screenShare
end)

-- Global so `hs -c` can show what the guard sees right now
function zoomShareKind() return zoomShare() or "none" end

-- URL router. Hammerspoon is the default browser and sends each link opened
-- from another app (Slack, Notion, Zoom, mail, the terminal) to a browser:
-- hosts on the machine-local work list open in Chrome's Work profile, the rest
-- in Dia. The list stays out of this public repo; without it everything goes
-- to Dia. A line with a dot matches that domain and its subdomains, a word
-- without one any host containing it. Re-read per link, so edits apply at once.
local WORK_DOMAINS_FILE = os.getenv("HOME") .. "/.config/url-router/work.local"
-- Chrome's folder for the Work profile ("Default" here: chrome://version shows it)
local CHROME_WORK_PROFILE = "Default"
local CHROME_BINARY = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

local function isWorkHost(host)
    local f = io.open(WORK_DOMAINS_FILE, "r")
    if not f or not host then return false end
    host = host:lower()
    for line in f:lines() do
        local rule = line:gsub("#.*", ""):match("^%s*(.-)%s*$"):lower()
        if rule ~= "" then
            local hit
            if rule:find("%.") then
                hit = host == rule or host:sub(-#rule - 1) == "." .. rule
            else
                hit = host:find(rule, 1, true) ~= nil
            end
            if hit then f:close() return true end
        end
    end
    f:close()
    return false
end

-- Global so `hs -c` can check where a URL would go without opening it
function urlRouterTarget(url)
    return isWorkHost(hs.http.urlParts(url).host) and "Chrome (Work)" or "Dia"
end

local function openInChromeWork(url)
    local profile = "--profile-directory=" .. CHROME_WORK_PROFILE
    if getApp("Google Chrome") then
        -- Running: the binary hands the URL to the open Chrome and exits.
        -- (`open --args` would be ignored by a running app.)
        hs.task.new(CHROME_BINARY, nil, { profile, url }):start()
    else
        hs.task.new("/usr/bin/open", nil, { "-b", BUNDLE_IDS["Google Chrome"], "--args", profile, url }):start()
    end
end

hs.urlevent.httpCallback = function(_, host, _, url)
    if isWorkHost(host) then
        openInChromeWork(url)
    else
        hs.urlevent.openURLWithBundle(url, BUNDLE_IDS["Dia"])
    end
end

-- Black menu bar. macOS 26's menu bar is transparent, so a bright wallpaper
-- shows through it (and frames the MacBook's notch). Instead of an app, draw a
-- black band, exactly the menu bar's height, into a copy of the wallpaper and
-- set that copy — on the built-in display the notch disappears into it. Black
-- there, Catppuccin Crust on other displays (see bandColor).
--   * The original wallpaper is never touched; copies live in a cache folder.
--     Its path is kept in hs.settings so the band can be redrawn for another
--     display or size.
--   * Drawn at the screen's pixel size with "fill" scaling, like macOS's own
--     "Fill Screen", so the result lines up exactly.
--   * Event-driven, no polling: re-checked on load, on display changes
--     (resolution, switching screens), on wake, and when the wallpaper changes —
--     macOS records each choice in its wallpaper store, which is watched. Our
--     own wallpaper change fires that too; the check then finds nothing to do.
local BAND_DIR = os.getenv("HOME") .. "/Library/Caches/dotfiles-menubar-band"
-- Pure black where it hides the notch (the built-in display); Catppuccin Crust
-- elsewhere, the same near-black as the wallpaper's darkest parts and Ghostty
local function bandColor(screen)
    return screen:name():match("^Built%-in") and "000000" or "11111b"
end
local BAND_SOURCE_KEY = "menubarBand.source"

local function bandWallpaper(screen)
    local url = screen:desktopImageURL()
    local current = url and hs.http.urlParts(url).path
    if not current then return end
    -- A path in our cache means the band is already ours, so the original is
    -- the remembered one; anything else is a wallpaper the user picked
    local ours = current:sub(1, #BAND_DIR) == BAND_DIR
    local source = ours and hs.settings.get(BAND_SOURCE_KEY) or current
    if not ours then hs.settings.set(BAND_SOURCE_KEY, source) end
    local full, scale = screen:fullFrame(), screen:currentMode().scale
    -- Wallpapers named <name>-<w>x<h>.<ext> (e.g. from the `wallpaper` script)
    -- may have a sibling rendered for this screen's exact size: prefer it, so
    -- nothing is cropped
    if source then
        local stem, ext = source:match("^(.*)%-%d+x%d+%.(%w+)$")
        local sibling = stem and string.format("%s-%dx%d.%s", stem, math.floor(full.w * scale), math.floor(full.h * scale), ext)
        if sibling and hs.fs.attributes(sibling) then source = sibling end
    end
    local image = source and hs.image.imageFromPath(source)
    if not image then return end

    local band = screen:frame().y - full.y  -- the menu bar's height on this screen
    if band <= 0 then return end            -- menu bar hidden: nothing to cover
    -- Copies are named after the wallpaper *family* — the sibling's size
    -- suffix stripped — so the cleanup below keeps every display's copy of the
    -- current wallpaper. Named after the sibling, drawing the Dell's band
    -- deleted the MacBook's, and macOS fell back to its default (blue) wallpaper.
    local base = source:match("([^/]+)%.%w+$") or "wallpaper"
    local prefix = base:gsub("%-%d+x%d+$", "") .. "-"
    local color = bandColor(screen)
    local name = string.format("%s%dx%d-%d-%s.jpg", prefix,
        math.floor(full.w * scale), math.floor(full.h * scale), math.floor(band * scale), color)
    local target = BAND_DIR .. "/" .. name
    -- Already set — but only if the file is still there; a deleted copy is redrawn
    if current == target and hs.fs.attributes(target) then return end

    if not hs.fs.attributes(target) then
        hs.fs.mkdir(BAND_DIR)
        -- Fill: scale the image to cover the screen, centered, cropping overflow
        local size = image:size()
        local s = math.max(full.w / size.w, full.h / size.h)
        local w, h = size.w * s, size.h * s
        local canvas = hs.canvas.new({ x = 0, y = 0, w = full.w, h = full.h })
        canvas:appendElements(
            { type = "image", image = image, imageScaling = "scaleToFit",
              frame = { x = (full.w - w) / 2, y = (full.h - h) / 2, w = w, h = h } },
            { type = "rectangle", action = "fill", fillColor = { hex = "#" .. color },
              frame = { x = 0, y = 0, w = full.w, h = band } }
        )
        canvas:imageFromCanvas():saveToFile(target, false, "JPEG")
        canvas:delete()
        -- Keep the folder small: drop copies made from an older wallpaper
        for file in hs.fs.dir(BAND_DIR) do
            if file:match("%.jpg$") and file:sub(1, #prefix) ~= prefix then
                os.remove(BAND_DIR .. "/" .. file)
            end
        end
    end
    screen:desktopImageURL("file://" .. target)
end

local function bandAllScreens()
    for _, screen in ipairs(hs.screen.allScreens()) do bandWallpaper(screen) end
end
bandAllScreens()
-- Globals so the watchers and timer aren't garbage-collected
bandScreenWatcher = hs.screen.watcher.new(function() hs.timer.doAfter(1, bandAllScreens) end):start()
bandWakeWatcher = hs.caffeinate.watcher.new(function(event)
    if event == hs.caffeinate.watcher.screensDidWake then hs.timer.doAfter(2, bandAllScreens) end
end):start()
bandWallpaperWatcher = hs.pathwatcher.new(
    os.getenv("HOME") .. "/Library/Application Support/com.apple.wallpaper/Store",
    function() hs.timer.doAfter(1, bandAllScreens) end  -- let the store finish writing
):start()

hs.alert.show("\u{1F528} Hammerspoon loaded")
