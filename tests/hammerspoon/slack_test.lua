-- Parking Slack on your own DM: the real init.lua under the fake hs in
-- mock.lua, with a fake Slack accessibility tree, app activation events
-- and fake time. Run from the repo root: lua tests/hammerspoon/run.lua

local hs = require("mock")
local test = require("runner").test

local CONFIG = os.getenv("HS_CONFIG") or "config/hammerspoon/init.lua"
local SLACK = "com.tinyspeck.slackmacgap"
local GHOSTTY = "com.mitchellh.ghostty"
local IDS = "# comment\nteam T1\ndm   D1   # trailing\n"
local LEFT, RIGHT = { x = 0, y = 25, w = 756, h = 957 }, { x = 756, y = 25, w = 756, h = 957 }

-- A fresh world: a Slack window and a Ghostty window (focused, so Slack is
-- in the background), the ids file unless `noFile`, and Slack's sidebar
-- with the DM entry unless `noEntry`
local slack, slackWin, ghosttyWin
local function setup(opts)
    opts = opts or {}
    hs.reset()
    hs.screen("Built-in Retina Display", 1512, 982)
    if not opts.noFile then hs.files[".config/slack/self-dm.local"] = IDS end
    slackWin = hs.window("Slack", SLACK, opts.slackFrame or RIGHT)
    ghosttyWin = hs.window("Ghostty", GHOSTTY, opts.ghosttyFrame or LEFT)
    slack = slackWin:application()
    local row = hs.ax({ AXRole = "AXRow", AXDOMIdentifier = "D1" }, { hs.ax({ AXRole = "AXGroup" }, {}, "dm") })
    local other = hs.ax({ AXRole = "AXRow", AXDOMIdentifier = "C9" }, { hs.ax({}, {}, "channel") })
    local sidebar = hs.ax({ AXRole = "AXOutline" }, opts.noEntry and { other } or { other, row })
    hs.axTree(slack, { hs.ax({ AXRole = "AXWindow" }, { sidebar }) })
    hs.load(CONFIG)
    ghosttyWin:focus()
end

-- `seconds` of fake time pass. The clock only moves when a timer fires,
-- so an empty one marks the end.
local function wait(seconds)
    _G.hs.timer.doAfter(seconds, function() end)
    hs.flush(seconds)
end

-- Slack goes to the background, then `seconds` pass
local function leaveSlack(seconds)
    hs.appEvent("deactivated", slack)
    wait(seconds)
end

test("Slack: Hyper+N presses the DM's sidebar entry, focus unchanged", function()
    setup()
    hs.press("n")
    assert(hs.axPressed[1] == "dm" and #hs.axPressed == 1, "pressed: " .. table.concat(hs.axPressed, ","))
    assert(#hs.urls == 0, "opened " .. tostring(hs.urls[1]))
    assert(hs.focused() == ghosttyWin, "focus moved")
end)

test("Slack: Hyper+N falls back to the DM's link when the entry isn't there", function()
    setup({ noEntry = true })
    hs.press("n")
    assert(hs.urls[1] == "slack://channel?team=T1&id=D1", "opened " .. tostring(hs.urls[1]))
end)

test("Slack: Hyper+N without the ids file says so and does nothing", function()
    setup({ noFile = true })
    hs.press("n")
    assert(#hs.axPressed == 0 and #hs.urls == 0, "acted without ids")
    assert(hs.alerts[#hs.alerts]:find("self%-dm.local"), "alert: " .. tostring(hs.alerts[#hs.alerts]))
end)

test("Slack: parks itself 2 min after going to the background, not before", function()
    setup({ ghosttyFrame = { x = 0, y = 25, w = 1512, h = 957 } })  -- Ghostty covers Slack
    leaveSlack(119)
    assert(#hs.axPressed == 0, "parked early")
    wait(2)
    assert(hs.axPressed[1] == "dm", "didn't park")
end)

test("Slack: coming back within the delay cancels the park", function()
    setup({ ghosttyFrame = { x = 0, y = 25, w = 1512, h = 957 } })
    leaveSlack(60)
    hs.appEvent("activated", slack)
    wait(300)
    assert(#hs.axPressed == 0, "parked after coming back")
end)

test("Slack: a hidden Slack parks", function()
    setup()
    slack:hide()
    leaveSlack(121)
    assert(hs.axPressed[1] == "dm", "didn't park")
end)

test("Slack: a Slack window in view is left alone, and parked once covered", function()
    setup()  -- side by side: Slack visible
    leaveSlack(121)
    assert(#hs.axPressed == 0, "parked while visible")
    hs.window("Notion", "notion.id", RIGHT):focus()  -- now covers Slack
    wait(120)
    assert(hs.axPressed[1] == "dm", "didn't park once covered")
end)

test("Slack: a window covering only part of Slack doesn't count as covered", function()
    setup({ ghosttyFrame = { x = 0, y = 25, w = 1100, h = 957 } })  -- Slack's right edge shows
    leaveSlack(121)
    assert(#hs.axPressed == 0, "parked while partly visible")
end)

test("Slack: the automatic park never opens the link", function()
    setup({ noEntry = true, ghosttyFrame = { x = 0, y = 25, w = 1512, h = 957 } })
    leaveSlack(121)
    assert(#hs.urls == 0, "opened " .. tostring(hs.urls[1]) .. " (would pull Slack forward)")
end)
