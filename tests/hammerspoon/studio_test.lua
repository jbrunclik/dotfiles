-- The Studio layer's keys: the real init.lua under the fake hs in mock.lua,
-- the chords the Model 100 sends pressed, and the Shelly requests checked.
-- Run from the repo root: lua tests/hammerspoon/run.lua

local hs = require("mock")
local test = require("runner").test

local CONFIG = os.getenv("HS_CONFIG") or "config/hammerspoon/init.lua"
local MODS = { "cmd", "alt", "ctrl" }
local DEVICES = [[
# a comment, then the four roles
living-light  living-light.test
living-cover  living-cover.test   # trailing comment
kitchen-light kitchen-light.test
kitchen-cover kitchen-cover.test
]]

-- A fresh world with the device file in place (unless `noFile`), and the
-- covers reporting `state` to Cover.GetStatus
local function setup(state, noFile)
    hs.reset()
    hs.screen("Built-in Retina Display", 1512, 982)
    if not noFile then hs.files[".config/studio/devices.local"] = DEVICES end
    hs.httpReply(function(url)
        if url:find("Cover.GetStatus", 1, true) then return 200, '{"state":"' .. (state or "stopped") .. '"}' end
        return 200, "{}"
    end)
    hs.load(CONFIG)
end

local function press(key)
    hs.requests = {}
    hs.pressWith(MODS, key)
end

-- The last request made, against the one expected
local function sent(want)
    local have = hs.requests[#hs.requests]
    assert(have == want, "sent " .. tostring(have) .. ", expected " .. want)
end

test("Studio: the light keys toggle each room's light", function()
    setup()
    press("f13") sent("http://living-light.test/rpc/Switch.Toggle?id=0")
    press("f17") sent("http://kitchen-light.test/rpc/Switch.Toggle?id=0")
end)

test("Studio: up opens a stopped cover, and stops one already opening", function()
    setup("stopped")
    press("f14") sent("http://living-cover.test/rpc/Cover.Open?id=0")
    assert(hs.requests[1] == "http://living-cover.test/rpc/Cover.GetStatus?id=0", "didn't read the state first")
    setup("opening")
    press("f14") sent("http://living-cover.test/rpc/Cover.Stop?id=0")
end)

test("Studio: up while closing reverses instead of stopping", function()
    setup("closing")
    press("f18") sent("http://kitchen-cover.test/rpc/Cover.Open?id=0")
end)

test("Studio: down closes, and stops a cover already closing", function()
    setup("open")
    press("f16") sent("http://living-cover.test/rpc/Cover.Close?id=0")
    setup("closing")
    press("f20") sent("http://kitchen-cover.test/rpc/Cover.Stop?id=0")
end)

test("Studio: the preset sends the cover to 85 % covered", function()
    setup()
    press("f15") sent("http://living-cover.test/rpc/Cover.GoToPosition?id=0&pos=15")
    press("f19") sent("http://kitchen-cover.test/rpc/Cover.GoToPosition?id=0&pos=15")
end)

test("Studio: the preset stops a cover moving either way", function()
    setup("opening")
    press("f15") sent("http://living-cover.test/rpc/Cover.Stop?id=0")
    setup("closing")
    press("f19") sent("http://kitchen-cover.test/rpc/Cover.Stop?id=0")
end)

test("Studio: without the device file, a key says so and sends nothing", function()
    setup(nil, true)
    press("f13")
    assert(#hs.requests == 0, "sent " .. tostring(hs.requests[1]))
    assert(hs.alerts[#hs.alerts]:find("no living%-light"), "alert: " .. tostring(hs.alerts[#hs.alerts]))
end)

test("Studio: a device that doesn't answer alerts, and a cover isn't moved blind", function()
    setup()
    hs.httpReply(function() return -1, nil end)
    press("f14")
    assert(#hs.requests == 1, "went on after a failed status read: " .. tostring(hs.requests[2]))
    assert(hs.alerts[#hs.alerts]:find("living%-cover didn't answer"), "alert: " .. tostring(hs.alerts[#hs.alerts]))
end)
