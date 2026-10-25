-- The usage log hyper-stats reads: the real init.lua under the fake hs in
-- mock.lua, keys pressed and the lines appended checked.
-- Run from the repo root: lua tests/hammerspoon/run.lua

local hs = require("mock")
local test = require("runner").test

local CONFIG = os.getenv("HS_CONFIG") or "config/hammerspoon/init.lua"
local LOG = ".local/state/hammerspoon/usage.tsv"

local function setup()
    hs.reset()
    hs.screen("Built-in Retina Display", 1512, 982)
    hs.load(CONFIG)
end

-- The log's lines, each split into { time, key, desc }
local function lines()
    local out = {}
    for line in (hs.files[LOG] or ""):gmatch("[^\n]+") do
        local time, key, desc = line:match("^([^\t]+)\t([^\t]+)\t([^\t]*)$")
        assert(time, "malformed line: " .. line)
        assert(time:match("^%d%d%d%d%-%d%d%-%d%dT%d%d:%d%d:%d%d$"), "bad time: " .. time)
        table.insert(out, { time = time, key = key, desc = desc })
    end
    return out
end

test("Usage: a Hyper key logs its key and cheatsheet description", function()
    setup()
    assert(#lines() == 0, "logged something at load")
    hs.press("`")
    local l = lines()
    assert(#l == 1, "expected 1 line, got " .. #l)
    assert(l[1].key == "Hyper+`", "key " .. l[1].key)
    assert(l[1].desc == "Cycle windows stacked on this half", "desc " .. l[1].desc)
end)

test("Usage: the uncheatsheeted alias and plain keys log too", function()
    setup()
    hs.press(";")
    hs.pressWith({}, "f19")
    local l = lines()
    assert(#l == 2, "expected 2 lines, got " .. #l)
    assert(l[1].key == "Hyper+;" and l[1].desc == "Cycle windows stacked on this half", "alias: " .. l[1].key)
    assert(l[2].key == "f19" and l[2].desc:match("^Show / hide Messages"), "plain: " .. l[2].key)
end)
