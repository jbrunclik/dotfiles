-- Hammerspoon config
-- Hyper key (Cmd+Option+Ctrl+Shift) via:
--   MacBook:    CapsLock (remapped by Karabiner-Elements)
--   Keyboardio: Any key (configured in Chrysalis firmware)

local hyper = { "cmd", "alt", "ctrl", "shift" }

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
hs.hotkey.bind(hyper, "z", function() tilePair("Ghostty", "Dia") end)
hs.hotkey.bind(hyper, "x", function() tilePair("zoom.us", "Notion") end)
hs.hotkey.bind(hyper, "c", function() tilePair("zoom.us", "Slack") end)
hs.hotkey.bind(hyper, "v", function() tilePair("zoom.us", "Dia") end)

-- Hyper+Tab = toggle focus between left and right windows
hs.hotkey.bind(hyper, "tab", function()
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
hs.hotkey.bind(hyper, "left", function()
    local wins = hs.fnutils.filter(hs.window.orderedWindows(), function(w)
        return w:frame().x < hs.screen.mainScreen():frame().w / 2
    end)
    if wins[1] then wins[1]:focus() end
end)

hs.hotkey.bind(hyper, "right", function()
    local wins = hs.fnutils.filter(hs.window.orderedWindows(), function(w)
        return w:frame().x >= hs.screen.mainScreen():frame().w / 2
    end)
    if wins[1] then wins[1]:focus() end
end)

-- Hyper+F = toggle native fullscreen
hs.hotkey.bind(hyper, "f", function()
    local win = hs.window.focusedWindow()
    if win then win:toggleFullScreen() end
end)

-- Hyper+ASD = tile left / maximize / tile right
hs.hotkey.bind(hyper, "a", function()
    local win = hs.window.focusedWindow()
    if win then win:move(left) end
end)

hs.hotkey.bind(hyper, "d", function()
    local win = hs.window.focusedWindow()
    if win then win:move(right) end
end)

hs.hotkey.bind(hyper, "s", function()
    local win = hs.window.focusedWindow()
    if win then win:maximize() end
end)

-- Hyper+1-6 = focus app (repeat to maximize)
local appKeys = {
    { "1", "Ghostty" },
    { "2", "Dia" },
    { "3", "Google Chrome" },
    { "4", "Slack" },
    { "5", "Notion" },
    { "6", "zoom.us" },
}
for _, binding in ipairs(appKeys) do
    hs.hotkey.bind(hyper, binding[1], function()
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
hs.hotkey.bind(hyper, "m", function()
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
hs.hotkey.bind(hyper, "r", function()
    hs.reload()
end)
hs.alert.show("\u{1F528} Hammerspoon loaded")
