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

-- Layout helper: launch apps and tile them side by side
-- Waits for windows to appear rather than using a fixed delay
local function layout(apps)
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
            local screen = hs.screen.mainScreen()
            for _, app in ipairs(apps) do
                local win = bestWindow(app.name)
                if win then win:move(app.rect, screen) end
            end
        end
    end)
end

local left  = hs.geometry.rect(0, 0, 0.5, 1)
local right = hs.geometry.rect(0.5, 0, 0.5, 1)

-- Layouts (bottom row: Z, X, V, B, ...)
hs.hotkey.bind(hyper, "z", function()
    layout({
        { name = "Ghostty", rect = left },
        { name = "Dia",     rect = right },
    })
end)

hs.hotkey.bind(hyper, "x", function()
    layout({
        { name = "zoom.us", rect = left },
        { name = "Notion",  rect = right },
    })
end)

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

-- Hyper+1-5 = focus app
local appKeys = {
    { "1", "Ghostty" },
    { "2", "Dia" },
    { "3", "Google Chrome" },
    { "4", "Slack" },
    { "5", "Notion" },
}
for _, binding in ipairs(appKeys) do
    hs.hotkey.bind(hyper, binding[1], function()
        hs.application.launchOrFocus(binding[2])
    end)
end

-- Reload config
hs.hotkey.bind(hyper, "r", function()
    hs.reload()
end)
hs.alert.show("Hammerspoon loaded")
