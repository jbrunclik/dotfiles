-- Audio setups: the real init.lua under the fake hs in mock.lua, with fake
-- audio devices plugged in and out, and Hyper+Y pressed.
-- Run from the repo root: lua tests/hammerspoon/run.lua

local hs = require("mock")
local test = require("runner").test

local CONFIG = os.getenv("HS_CONFIG") or "config/hammerspoon/init.lua"

-- Device names as macOS shows them
local HEADSET = "OpenComm2 by Shokz_II"
local DONGLE = "Loop120 by Shokz"
local DELL = "DELL U3223QE"
local CAMERA = "Insta360 Link 2C"
local PODMIC = "RODE PodMic USB"

local function plugDock()
    hs.audio(DELL, "DisplayPort", "out")
    hs.audio(DONGLE, "USB")
    hs.audio(CAMERA, "USB", "in")
end

-- A fresh world: the MacBook's own devices, plus `extra` plugged in before
-- the config loads (what it finds at load is the baseline, not a change)
local function setup(extra)
    hs.reset()
    hs.screen("Built-in Retina Display", 1512, 982)
    hs.audio("MacBook Pro Speakers", "Built-in", "out")
    hs.audio("MacBook Pro Microphone", "Built-in", "in")
    hs.audio("ZoomAudioDevice", "Virtual")
    if extra then extra() end
    hs.load(CONFIG)
end

-- Fire the device-list event and let the 2 s settle pass run
local function changed()
    hs.audioEvent("dev#")
    hs.flush()
end

local function assertAudio(output, input, label)
    local have = string.format("%s / %s", hs.defaultAudio("output"), hs.defaultAudio("input"))
    local want = string.format("%s / %s", output, input)
    assert(have == want, (label or "audio") .. ": " .. have .. ", expected " .. want)
    assert(hs.defaultAudio("effect") == output, "sound effects stayed on " .. tostring(hs.defaultAudio("effect")))
end

test("Audio: docked, the headset turning on switches to it, through the dongle", function()
    setup(plugDock)
    hs.audio(HEADSET, "Bluetooth")
    changed()
    assertAudio(DONGLE, DONGLE)
    assert(hs.alerts[#hs.alerts]:find("Headset"), "no Headset alert")
end)

test("Audio: the headset connecting unmutes it at full volume", function()
    setup(plugDock)
    hs.audio(HEADSET, "Bluetooth")
    changed()
    local out = _G.hs.audiodevice.defaultOutputDevice()
    assert(out:outputMuted() == false, "still muted")
    assert(out:outputVolume() == 100, "volume " .. tostring(out:outputVolume()))
end)

test("Audio: Hyper+Y and docking leave the volume alone", function()
    setup(function() plugDock() hs.audio(HEADSET, "Bluetooth") end)
    hs.press("y")
    local out = _G.hs.audiodevice.defaultOutputDevice()
    assert(out:name() == DONGLE and out:outputMuted() == true and out:outputVolume() == 0,
        "Hyper+Y changed the volume")

    setup(function() hs.audio(HEADSET, "Bluetooth") end)
    plugDock()
    changed()
    out = _G.hs.audiodevice.defaultOutputDevice()
    assert(out:name() == DONGLE and out:outputVolume() == 0, "docking changed the volume")
end)

test("Audio: docked, the headset turning off switches to External", function()
    setup(function() plugDock() hs.audio(HEADSET, "Bluetooth") end)
    hs.unplug(HEADSET)
    changed()
    assertAudio(DELL, CAMERA)
end)

test("Audio: External takes the PodMic over the camera's mic", function()
    setup(function() plugDock() hs.audio(PODMIC, "USB", "in") hs.audio(HEADSET, "Bluetooth") end)
    hs.unplug(HEADSET)
    changed()
    assertAudio(DELL, PODMIC)
end)

test("Audio: undocked, the headset turning on switches to it over Bluetooth", function()
    setup()
    hs.audio(HEADSET, "Bluetooth")
    changed()
    assertAudio(HEADSET, HEADSET)
end)

test("Audio: undocked, the headset turning off goes back to Built-in", function()
    setup(function() hs.audio(HEADSET, "Bluetooth") end)
    hs.unplug(HEADSET)
    changed()
    assertAudio("MacBook Pro Speakers", "MacBook Pro Microphone")
end)

test("Audio: docking picks Headset with the headset on, External without", function()
    setup(function() hs.audio(HEADSET, "Bluetooth") end)
    plugDock()
    changed()
    assertAudio(DONGLE, DONGLE, "headset on")

    setup()
    plugDock()
    changed()
    assertAudio(DELL, CAMERA, "headset off")
end)

test("Audio: devices arriving over a few seconds switch once, after the last", function()
    setup()
    -- Docking: the Dell first, the camera 3 s later. Acting on the first
    -- event alone would switch before the camera's mic exists.
    hs.audio(DELL, "DisplayPort", "out") hs.audioEvent("dev#")
    _G.hs.timer.doAfter(1.5, function() hs.audio(DONGLE, "USB") hs.audioEvent("dev#") end)
    _G.hs.timer.doAfter(3, function() hs.audio(CAMERA, "USB", "in") hs.audioEvent("dev#") end)
    hs.flush()
    assert(#hs.alerts == 2, "expected the load alert and one switch, got " .. #hs.alerts)
    assertAudio(DELL, CAMERA)
end)

test("Audio: other device changes leave a hand-picked setup alone", function()
    setup(function() plugDock() hs.audio(HEADSET, "Bluetooth") end)
    hs.press("y")  -- Headset
    hs.press("y")  -- External
    assertAudio(DELL, CAMERA, "picked")
    hs.unplug(DONGLE) changed()
    hs.audio(DONGLE, "USB") changed()
    assertAudio(DELL, CAMERA, "after the dongle came back")
end)

test("Audio: Hyper+Y toggles Headset and External when docked, skipping Built-in", function()
    setup(function() plugDock() hs.audio(HEADSET, "Bluetooth") end)
    hs.press("y") assertAudio(DONGLE, DONGLE, "first press")
    hs.press("y") assertAudio(DELL, CAMERA, "second press")
    hs.press("y") assertAudio(DONGLE, DONGLE, "third press")
end)

test("Audio: Hyper+Y with one setup available says so and changes nothing", function()
    setup(plugDock)
    hs.press("y") assertAudio(DELL, CAMERA, "first press")
    hs.press("y") assertAudio(DELL, CAMERA, "second press")
    assert(hs.alerts[#hs.alerts]:find("only setup"), "alert: " .. hs.alerts[#hs.alerts])
end)
