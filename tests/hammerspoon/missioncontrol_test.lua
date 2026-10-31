-- The focused-window border hidden during Mission Control: the real init.lua
-- under the fake hs in mock.lua, with a fake Dock, its accessibility
-- notifications and the window server's list.
-- Run from the repo root: lua tests/hammerspoon/run.lua

local hs = require("mock")
local test = require("runner").test

local CONFIG = os.getenv("HS_CONFIG") or "config/hammerspoon/init.lua"
local DOCK = "com.apple.dock"
local DOCK_PID = 500
local NOTIFICATION = "AXSelectedChildrenChanged"
-- The full-screen window the Dock shows only while Mission Control is open
local MISSION_CONTROL = { kCGWindowOwnerPID = DOCK_PID, kCGWindowOwnerName = "Dock", kCGWindowLayer = 20 }

local dock
local function setup()
    hs.reset()
    hs.screen("Built-in Retina Display", 1512, 982)
    dock = hs.app("Dock", DOCK, DOCK_PID)
    hs.load(CONFIG)
end

local function wait(seconds)
    _G.hs.timer.doAfter(seconds, function() end)
    hs.flush(seconds)
end

-- What borders was told, in order: "hide" or "restore"
local function borderCalls()
    local out = {}
    for _, t in ipairs(hs.tasks) do
        if t.path:match("/borders$") and t.args[1] == "active_color=0x00000000" then
            table.insert(out, "hide")
        elseif t.path == "/bin/bash" and (t.args[1] or ""):match("/%.config/borders/bordersrc$") then
            assert(t.env and t.env.PATH:find("/opt/homebrew/bin", 1, true), "bordersrc without Homebrew on PATH")
            table.insert(out, "restore")
        end
    end
    return table.concat(out, ",")
end

-- Mission Control opens: the notification first, its window ~0.1 s later
local function openMissionControl()
    hs.axNotify(DOCK_PID, NOTIFICATION)
    wait(0.08)
    hs.windowList = { MISSION_CONTROL }
    wait(1)
end

local function closeMissionControl(notify)
    if notify ~= false then hs.axNotify(DOCK_PID, NOTIFICATION) end
    wait(0.08)
    hs.windowList = {}
    wait(1)
end

test("Mission Control: border hidden on open, restored on close, once each", function()
    setup()
    openMissionControl()
    assert(borderCalls() == "hide", "after open: " .. borderCalls())
    closeMissionControl()
    assert(borderCalls() == "hide,restore", "after close: " .. borderCalls())
end)

test("Mission Control: border comes back without the closing notification", function()
    setup()
    openMissionControl()
    closeMissionControl(false)
    assert(borderCalls() == "hide,restore", "calls: " .. borderCalls())
end)

test("Mission Control: a Dock notification without it changes nothing", function()
    setup()
    hs.axNotify(DOCK_PID, NOTIFICATION)
    wait(1)
    assert(borderCalls() == "", "calls: " .. borderCalls())
end)

test("Mission Control: another app's layer-20 window isn't taken for it", function()
    setup()
    hs.windowList = { { kCGWindowOwnerPID = 900, kCGWindowLayer = 20 } }
    hs.axNotify(DOCK_PID, NOTIFICATION)
    wait(1)
    assert(borderCalls() == "", "calls: " .. borderCalls())
end)

test("Mission Control: still watched after the Dock restarts", function()
    setup()
    local newPid = DOCK_PID + 1
    dock = hs.app("Dock", DOCK, newPid)
    hs.appEvent("launched", dock)
    hs.axNotify(newPid, NOTIFICATION)
    wait(0.08)
    hs.windowList = { { kCGWindowOwnerPID = newPid, kCGWindowLayer = 20 } }
    wait(1)
    assert(borderCalls() == "hide", "calls: " .. borderCalls())
end)
