-- The Hyper layer as a whole: Hammerspoon's bindHyper keys and Karabiner's
-- Hyper rules don't collide, macOS's reserved chords stay with Karabiner,
-- every Karabiner rule is written so the cheatsheet lists it, and GUIDE.md
-- has a row for every key. The cheatsheet overlay, the printed sheet and the
-- Model 100's Hyper layer are generated from the same data, so a key that
-- fails here is missing or wrong on all three.

local hs = require("mock")
local test = require("runner").test

local CONFIG = os.getenv("HS_CONFIG") or "config/hammerspoon/init.lua"
local KARABINER = os.getenv("HS_KARABINER") or "config/karabiner/karabiner.json"
local GUIDE = os.getenv("HS_GUIDE") or "GUIDE.md"

local function read(path)
    local f = assert(io.open(path, "r"))
    local text = f:read("a")
    f:close()
    return text
end

-- Load the config once; these tests only read what it registered
hs.reset()
hs.screen("DELL U2723QE", 2560, 1440)
hs.load(CONFIG)
local bindings = hs.bindings

-- Hammerspoon's Hyper keys, by name ("a", "tab", "`")
local hyperKeys = {}
for _, b in ipairs(bindings) do
    if b.mods == hs.HYPER then table.insert(hyperKeys, b.key) end
end

-- Karabiner -----------------------------------------------------------------

local function selectedRules()
    local config = hs.decodeJSON(read(KARABINER))
    local profile = config.profiles[1]
    for _, p in ipairs(config.profiles) do
        if p.selected then profile = p end
    end
    return profile.complex_modifications.rules
end

-- Karabiner's key_code names in Hammerspoon's
local KARABINER_KEYS = {
    comma = ",", period = ".", slash = "/", semicolon = ";",
    grave_accent_and_tilde = "`", tab = "tab", return_or_enter = "return",
    spacebar = "space", left_arrow = "left", right_arrow = "right",
    up_arrow = "up", down_arrow = "down", delete_or_backspace = "delete",
}
local function karabinerKey(code) return KARABINER_KEYS[code] or code end

-- A manipulator's chord: "hyper" for exactly Cmd+Option+Ctrl+Shift (either
-- side), "hyper+" for Hyper plus more (Hyper+right Shift), nil otherwise
local function chord(from)
    local mods = from.modifiers and from.modifiers.mandatory or {}
    local seen = {}
    for _, m in ipairs(mods) do seen[(m:gsub("^left_", ""):gsub("^right_", ""))] = true end
    if not (seen.command and seen.option and seen.control and seen.shift) then return nil end
    return #mods == 4 and "hyper" or "hyper+"
end

-- Every manipulator of the selected profile with its rule and chord
local function karabinerChords()
    local out = {}
    for _, rule in ipairs(selectedRules()) do
        for _, m in ipairs(rule.manipulators or {}) do
            local c = m.from and chord(m.from)
            if c then
                local swallowed = m.to and #m.to == 1 and m.to[1].key_code == "vk_none"
                table.insert(out, {
                    rule = rule, chord = c, key = karabinerKey(m.from.key_code), swallowed = swallowed,
                })
            end
        end
    end
    return out
end

-- Collisions ------------------------------------------------------------------

test("No two Hammerspoon hotkeys on the same chord", function()
    local seen = {}
    for _, b in ipairs(bindings) do
        local id = b.mods .. " " .. b.key
        assert(not seen[id], "bound twice: " .. id)
        seen[id] = true
    end
end)

test("Hammerspoon binds none of the chords macOS reserves (Hyper+, . /)", function()
    for _, key in ipairs(hyperKeys) do
        assert(key ~= "," and key ~= "." and key ~= "/",
            "Hyper+" .. key .. " is swallowed by macOS (sysdiagnose); only Karabiner can use it")
    end
end)

test("No Hyper key bound by both Hammerspoon and Karabiner", function()
    local karabiner = {}
    for _, c in ipairs(karabinerChords()) do
        if c.chord == "hyper" then karabiner[c.key] = c.rule.description end
    end
    for _, key in ipairs(hyperKeys) do
        assert(not karabiner[key], string.format(
            "Hyper+%s is in Hammerspoon and in Karabiner (%q); Karabiner runs first, so Hammerspoon's never fires",
            key, karabiner[key] or ""))
    end
end)

test("No Hyper key bound twice in Karabiner", function()
    local seen = {}
    for _, c in ipairs(karabinerChords()) do
        local id = c.chord .. " " .. c.key
        assert(not seen[id] or seen[id] == c.rule,
            string.format("%s in two rules: %q and %q", id, seen[id] and seen[id].description or "", c.rule.description))
        seen[id] = c.rule
    end
end)

-- The cheatsheet ----------------------------------------------------------------

-- The same patterns init.lua's karabinerEntries reads
local function cheatsheetForm(description)
    return description:match("^(.-)Hyper%+(%S+) → (.+)$") ~= nil
end

test("Every Karabiner Hyper rule is described as [App: ]Hyper+<keys> → <action>", function()
    local checked = {}
    for _, c in ipairs(karabinerChords()) do
        local d = c.rule.description or ""
        if not checked[c.rule] then
            assert(cheatsheetForm(d), string.format(
                "%q isn't in the cheatsheet form, so the overlay, the printout and the Model 100 layer leave it out", d))
            checked[c.rule] = true
        end
    end
end)

test("The cheatsheet export lists every Hyper binding and Karabiner rule", function()
    hyperCheatsheetExport("cheatsheet.json")
    local data = hs.written["cheatsheet.json"]
    assert(data and data.sections, "nothing exported")
    assert(data.caps and data.caps:match("^CapsLock"), "the CapsLock rule's description is missing")
    local entries, karabiner = 0, 0
    for _, section in ipairs(data.sections) do
        if section.name == "Karabiner" then karabiner = #section.entries else entries = entries + #section.entries end
    end
    local rules = {}
    for _, c in ipairs(karabinerChords()) do rules[c.rule] = true end
    local ruleCount = 0
    for _ in pairs(rules) do ruleCount = ruleCount + 1 end
    -- bindHyper and bindPlain entries; bindHyperKey (an extra key for the
    -- same action, Hyper+;) is deliberately left off
    local registered = #bindings
    assert(entries > 0 and entries <= registered, string.format("%d entries for %d hotkeys", entries, registered))
    assert(karabiner == ruleCount, string.format("%d Karabiner entries for %d Hyper rules", karabiner, ruleCount))
end)

-- GUIDE.md ----------------------------------------------------------------------

-- Every key GUIDE.md documents, lowercased: named in a "| Hyper + <keys> |"
-- table row ("U / I", "Left/Right", "` (or ;)"), or in the prose of its own
-- section as `Hyper+<key>` (the launcher's `Hyper+Space`)
local function guideKeys()
    local keys, text = {}, read(GUIDE)
    for row in text:gmatch("\n| Hyper %+ (.-) |") do
        local cell = row:gsub("%(or", "/"):gsub("[()]", "")
        for token in cell:gmatch("[^/]+") do
            keys[token:match("^%s*(.-)%s*$"):lower()] = true
        end
    end
    for key in text:gmatch("`Hyper%+([^`%s]+)") do keys[key:lower()] = true end
    return keys
end
local GUIDE_NAMES = { delete = "backspace" }

test("GUIDE.md has a row for every Hammerspoon Hyper key", function()
    local keys = guideKeys()
    for _, key in ipairs(hyperKeys) do
        assert(keys[key], "GUIDE.md has no \"| Hyper + " .. key:upper() .. " |\" row or `Hyper+" .. key .. "` mention")
    end
end)

test("GUIDE.md has a row for every Karabiner Hyper key", function()
    local keys = guideKeys()
    for _, c in ipairs(karabinerChords()) do
        local name = GUIDE_NAMES[c.key] or c.key
        if c.chord == "hyper" and not c.swallowed then
            assert(keys[name], "no \"| Hyper + " .. name:upper() .. " |\" row in GUIDE.md for " .. c.rule.description)
        end
    end
end)
