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

-- Move a window using AppleScript (works with apps that resist Hammerspoon's API)
local function moveWindowAS(win, rect)
    local screen = hs.screen.mainScreen():frame()
    local x = math.floor(screen.x + rect.x * screen.w)
    local y = math.floor(screen.y + rect.y * screen.h)
    local w = math.floor(rect.w * screen.w)
    local h = math.floor(rect.h * screen.h)
    local title = win:title()
    local appName = win:application():name()
    hs.osascript.applescript(string.format([[
        tell application "System Events"
            tell process "%s"
                set w to window "%s"
                set position of w to {%d, %d}
                set size of w to {%d, %d}
            end tell
        end tell
    ]], appName, title, x, y, w, h))
end

-- Layout helper: launch apps and tile them side by side
-- Waits for windows to appear rather than using a fixed delay
local function layout(apps)
    -- Launch/focus all apps to ensure they're running and visible
    for _, app in ipairs(apps) do
        hs.application.launchOrFocus(app.name)
    end
    local attempts = 0
    hs.timer.doEvery(0.3, function(timer)
        attempts = attempts + 1
        local allReady = true
        for _, app in ipairs(apps) do
            if not bestWindow(app.name) then allReady = false end
        end
        if allReady or attempts >= 10 then
            timer:stop()
            local function positionAll()
                for _, app in ipairs(apps) do
                    local win = bestWindow(app.name)
                    if win then
                        if win:isFullScreen() then win:toggleFullScreen() end
                        moveWindowAS(win, app.rect)
                    end
                end
            end
            -- Position immediately, then again after a delay
            -- (some apps like Zoom re-maximize when focused)
            positionAll()
            hs.timer.doAfter(0.5, positionAll)
        end
    end)
end

local left  = hs.geometry.rect(0, 0, 0.5, 1)
local right = hs.geometry.rect(0.5, 0, 0.5, 1)

-- Layout helper: tile two apps, then cycle focus on repeat
local function tileLayout(leftApp, leftProcess, rightApp, rightProcess)
    local tiled = false
    return function()
        local screen = hs.screen.mainScreen():frame()
        local halfW = math.floor(screen.w / 2)
        -- If both apps are running and one is focused, just cycle
        local leftRunning = hs.application.get(leftApp)
        local rightRunning = hs.application.get(rightApp)
        if tiled and leftRunning and rightRunning then
            if leftRunning:isFrontmost() then
                hs.application.launchOrFocus(rightApp)
                return
            elseif rightRunning:isFrontmost() then
                hs.application.launchOrFocus(leftApp)
                return
            end
        end
        -- Otherwise, tile and focus the left app
        hs.application.launchOrFocus(rightApp)
        hs.application.launchOrFocus(leftApp)
        hs.osascript.applescript(string.format([[
            tell application "System Events"
                tell process "%s"
                    set w to front window
                    set position of w to {%d, %d}
                    set size of w to {%d, %d}
                end tell
                tell process "%s"
                    set w to front window
                    set position of w to {%d, %d}
                    set size of w to {%d, %d}
                end tell
            end tell
        ]], rightProcess, screen.x + halfW, screen.y, halfW, screen.h,
           leftProcess, screen.x, screen.y, halfW, screen.h))
        tiled = true
    end
end

-- Layouts (bottom row: Z, X, V, B, ...)
hs.hotkey.bind(hyper, "z", tileLayout("Ghostty", "ghostty", "Dia", "Dia"))

hs.hotkey.bind(hyper, "x", function()
    local screen = hs.screen.mainScreen():frame()
    local halfW = math.floor(screen.w / 2)
    -- Cycle focus if both are running and one is focused
    local zoom = hs.application.get("zoom.us")
    local notion = hs.application.get("Notion")
    if zoom and notion then
        if zoom:isFrontmost() then
            hs.application.launchOrFocus("Notion")
            return
        elseif notion:isFrontmost() then
            hs.application.launchOrFocus("zoom.us")
            return
        end
    end
    -- Tile: Zoom left, Notion right
    hs.application.launchOrFocus("Notion")
    hs.application.launchOrFocus("zoom.us")
    -- Pick the meeting window if available, otherwise the dashboard
    local zoomWinTitle = "Zoom Meeting"
    local z = hs.application.get("zoom.us")
    if z and not z:getWindow("Zoom Meeting") then
        zoomWinTitle = "Zoom Workplace"
    end
    hs.osascript.applescript(string.format([[
        tell application "System Events"
            tell process "zoom.us"
                set w to window "%s"
                set size of w to {%d, %d}
                set position of w to {%d, %d}
                perform action "AXRaise" of w
            end tell
            tell process "Notion"
                set w to front window
                set position of w to {%d, %d}
                set size of w to {%d, %d}
            end tell
        end tell
    ]], zoomWinTitle, halfW, screen.h, screen.x, screen.y,
       screen.x + halfW, screen.y, halfW, screen.h))
end)

-- Zoom+right-app layout factory: Zoom meeting left, companion app right, focus cycling
local function zoomLayout(companionApp, companionProcess)
    return function()
        local screen = hs.screen.mainScreen():frame()
        local halfW = math.floor(screen.w / 2)
        -- Cycle focus if both are running and one is focused
        local zoom = hs.application.get("zoom.us")
        local companion = hs.application.get(companionApp)
        if zoom and companion then
            if zoom:isFrontmost() then
                hs.application.launchOrFocus(companionApp)
                return
            elseif companion:isFrontmost() then
                hs.application.launchOrFocus("zoom.us")
                return
            end
        end
        -- Tile: Zoom left, companion right
        hs.application.launchOrFocus(companionApp)
        hs.application.launchOrFocus("zoom.us")
        -- Pick the meeting window if available, otherwise the dashboard
        local zoomWinTitle = "Zoom Meeting"
        local z = hs.application.get("zoom.us")
        if z and not z:getWindow("Zoom Meeting") then
            zoomWinTitle = "Zoom Workplace"
        end
        hs.osascript.applescript(string.format([[
            tell application "System Events"
                tell process "zoom.us"
                    set w to window "%s"
                    set size of w to {%d, %d}
                    set position of w to {%d, %d}
                    perform action "AXRaise" of w
                end tell
                tell process "%s"
                    set w to front window
                    set position of w to {%d, %d}
                    set size of w to {%d, %d}
                end tell
            end tell
        ]], zoomWinTitle, halfW, screen.h, screen.x, screen.y,
           companionProcess, screen.x + halfW, screen.y, halfW, screen.h))
    end
end

hs.hotkey.bind(hyper, "c", zoomLayout("Slack", "Slack"))
hs.hotkey.bind(hyper, "v", zoomLayout("Dia", "Dia"))

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
