-- A fake `hs` for loading config/hammerspoon/init.lua outside Hammerspoon.
--
-- Windows, screens, apps, hotkeys, geometry and timers are modelled; every
-- other module is a permissive stub (any field, any call, returns another
-- stub), so the config loads without a real Mac behind it. Nothing touches
-- the real machine: HOME points nowhere and os.remove is a no-op.
--
-- Time is fake too: timers queue, and M.flush() runs them in order,
-- advancing the clock, so whenWindows' polling and settling pass run
-- deterministically within one test.

local M = {}

-- Stubs ---------------------------------------------------------------------

local stub
local stubMeta = {
    __index = function(t, k)
        -- Integer keys are absent, so ipairs() over a stub ends at once
        if type(k) == "number" then return nil end
        local s = stub()
        rawset(t, k, s)
        return s
    end,
    __call = function() return stub() end,
    __concat = function() return "" end,
    __tostring = function() return "<stub>" end,
    __len = function() return 0 end,
}
function stub() return setmetatable({}, stubMeta) end

-- Geometry ------------------------------------------------------------------

local rectMeta = {}
rectMeta.__index = function(r, k)
    if k == "center" then return { x = r.x + r.w / 2, y = r.y + r.h / 2 } end
    if k == "area" then return r.w * r.h end
    return rectMeta[k]
end
local function rect(x, y, w, h)
    if type(x) == "table" then x, y, w, h = x.x, x.y, x.w, x.h end
    return setmetatable({ x = x, y = y, w = w, h = h }, rectMeta)
end
function rectMeta.intersect(a, b)
    local x1, y1 = math.max(a.x, b.x), math.max(a.y, b.y)
    local x2, y2 = math.min(a.x + a.w, b.x + b.w), math.min(a.y + a.h, b.y + b.h)
    if x2 <= x1 or y2 <= y1 then return rect(x1, y1, 0, 0) end
    return rect(x1, y1, x2 - x1, y2 - y1)
end
M.rect = rect

-- Timers --------------------------------------------------------------------

local now, queue, seq = 0, {}, 0
local function schedule(at, fn)
    seq = seq + 1
    local t = { at = at, fn = fn, seq = seq, live = true }
    table.insert(queue, t)
    return {
        stop = function(self) t.live = false return self end,
        start = function(self) return self end,
        running = function() return t.live end,
    }
end

-- Run every queued timer, earliest first, up to `limit` seconds of fake time
function M.flush(limit)
    local deadline = now + (limit or 30)
    while true do
        table.sort(queue, function(a, b)
            if a.at ~= b.at then return a.at < b.at end
            return a.seq < b.seq
        end)
        local t = table.remove(queue, 1)
        if not t or t.at > deadline then
            if t then table.insert(queue, t) end
            return
        end
        if t.live then
            now = math.max(now, t.at)
            t.fn()
        end
    end
end

-- JSON ----------------------------------------------------------------------

-- Enough of a decoder for karabiner.json: objects, arrays, strings (with
-- \uXXXX), numbers, true/false/null (null decodes to nil)
local function decodeJSON(text)
    local pos = 1
    local function ws() pos = text:find("[^ \t\r\n]", pos) or #text + 1 end
    local function fail(what) error(string.format("JSON: %s at byte %d", what, pos)) end
    local value
    local function str()
        local out = {}
        pos = pos + 1
        while true do
            local c = text:sub(pos, pos)
            if c == "" then fail("unterminated string") end
            if c == '"' then pos = pos + 1 break end
            if c == "\\" then
                local e = text:sub(pos + 1, pos + 1)
                local simple = { b = "\b", f = "\f", n = "\n", r = "\r", t = "\t" }
                if e == "u" then
                    table.insert(out, utf8.char(tonumber(text:sub(pos + 2, pos + 5), 16)))
                    pos = pos + 6
                else
                    table.insert(out, simple[e] or e)
                    pos = pos + 2
                end
            else
                table.insert(out, c)
                pos = pos + 1
            end
        end
        return table.concat(out)
    end
    function value()
        ws()
        local c = text:sub(pos, pos)
        if c == "{" then
            local obj = {}
            pos = pos + 1
            ws()
            if text:sub(pos, pos) == "}" then pos = pos + 1 return obj end
            while true do
                ws()
                if text:sub(pos, pos) ~= '"' then fail("expected a key") end
                local k = str()
                ws()
                if text:sub(pos, pos) ~= ":" then fail("expected ':'") end
                pos = pos + 1
                obj[k] = value()
                ws()
                local d = text:sub(pos, pos)
                pos = pos + 1
                if d == "}" then return obj end
                if d ~= "," then fail("expected ',' or '}'") end
            end
        elseif c == "[" then
            local arr = {}
            pos = pos + 1
            ws()
            if text:sub(pos, pos) == "]" then pos = pos + 1 return arr end
            while true do
                table.insert(arr, value())
                ws()
                local d = text:sub(pos, pos)
                pos = pos + 1
                if d == "]" then return arr end
                if d ~= "," then fail("expected ',' or ']'") end
            end
        elseif c == '"' then
            return str()
        elseif text:find("^true", pos) then pos = pos + 4 return true
        elseif text:find("^false", pos) then pos = pos + 5 return false
        elseif text:find("^null", pos) then pos = pos + 4 return nil
        else
            local num = text:match("^-?%d+%.?%d*[eE]?[-+]?%d*", pos)
            if not num or num == "" then fail("unexpected character") end
            pos = pos + #num
            return tonumber(num)
        end
    end
    local result = value()
    ws()
    if pos <= #text then fail("trailing data") end
    return result
end
M.decodeJSON = decodeJSON

-- What hs.json.write was given, by path; nothing reaches the disk
M.written = {}

-- The world: screens, apps, windows -----------------------------------------

local screens, apps, windows, zorder = {}, {}, {}, {}
local hotkeys = {}
-- Every hs.hotkey.bind, in order: { mods = "cmd+alt+ctrl+shift", key = "a" },
-- the key by name even where init.lua bound it by key code
M.bindings = {}
M.alerts = {}

local Screen = {}
Screen.__index = Screen
function Screen:frame() return rect(self.f) end
function Screen:fullFrame() return rect(self.f.x, 0, self.f.w, self.f.y + self.f.h) end
function Screen:name() return self.n end
function Screen:currentMode() return { w = self.f.w, h = self.f.h, scale = 2 } end
function Screen:desktopImageURL() return nil end

local App = {}
App.__index = App
function App:name() return self.n end
function App:bundleID() return self.bid end
function App:pid() return self.p end
function App:isHidden() return self.hidden end
function App:hide() self.hidden = true end
function App:unhide() self.hidden = false end
function App:isFrontmost()
    local f = M.focused()
    return f ~= nil and f.app == self
end
function App:allWindows()
    local out = {}
    for _, w in ipairs(windows) do if w.app == self then table.insert(out, w) end end
    return out
end
function App:mainWindow()
    for _, w in ipairs(zorder) do if w.app == self then return w end end
    return self:allWindows()[1]
end
function App:getWindow(title)
    for _, w in ipairs(self:allWindows()) do if w.t == title then return w end end
end
function App:selectMenuItem() end

local Window = {}
Window.__index = Window
local function visible(w) return not w.minimized and not w.app.hidden end
function Window:frame() return rect(self.f) end
function Window:size() return { w = self.f.w, h = self.f.h } end
function Window:setFrame(f) self.f = rect(f) end
function Window:move(u)
    local s = self.scr.f
    self.f = rect(s.x + u.x * s.w, s.y + u.y * s.h, u.w * s.w, u.h * s.h)
end
function Window:screen() return self.scr end
function Window:application() return self.app end
function Window:id() return self.i end
function Window:title() return self.t end
function Window:isStandard() return self.standard end
function Window:isVisible() return visible(self) end
function Window:isMinimized() return self.minimized end
function Window:unminimize() self.minimized = false end
function Window:toggleFullScreen() end
-- Focusing raises: the window goes to the top of the z-order
function Window:focus()
    for i, w in ipairs(zorder) do
        if w == self then table.remove(zorder, i) break end
    end
    table.insert(zorder, 1, self)
    self.app.hidden = false
    return self
end
function Window:raise() return self:focus() end

-- Audio devices, defaults and the watcher callback (see hs.audiodevice)
local audioDevices, audioDefaults, audioCallback = {}, {}, nil
-- HTTP requests made, and the function that answers them (see hs.http)
local httpReply
-- Application watcher callbacks (see hs.application.watcher)
local appWatchers = {}

-- Reset the world between tests
function M.reset()
    screens, apps, windows, zorder, queue = {}, {}, {}, {}, {}
    hotkeys, M.bindings, M.written, M.alerts = {}, {}, {}, {}
    audioDevices, audioDefaults, audioCallback = {}, {}, nil
    M.requests, M.files, httpReply = {}, {}, function() return 200, "{}" end
    appWatchers, M.urls, M.axPressed = {}, {}, {}
end

-- A screen; `name` "Built-in Retina Display" makes it the MacBook's
function M.screen(name, w, h)
    local s = setmetatable({ n = name, f = rect(0, 25, w, h - 25) }, Screen)
    table.insert(screens, s)
    return s
end

-- A window of app `appName` (bundle ID `bid`) at `frame` (a rect, in points).
-- New windows open on top, so declare them bottom-most first.
function M.window(appName, bid, frame, opts)
    opts = opts or {}
    local app = apps[bid]
    if not app then
        app = setmetatable({ n = appName, bid = bid, p = #windows + 100, hidden = false }, App)
        apps[bid] = app
    end
    local w = setmetatable({
        i = #windows + 1, app = app, f = rect(frame), t = opts.title or appName,
        scr = opts.screen or screens[1], standard = opts.standard ~= false,
        minimized = false,
    }, Window)
    table.insert(windows, w)
    table.insert(zorder, 1, w)
    return w
end

function M.focused()
    for _, w in ipairs(zorder) do if visible(w) then return w end end
end

-- Press a Hyper chord: key is the name bindHyper used ("a", "tab", "`"),
-- looked up through the same physical key codes
local ANSI = {
    a = 0, s = 1, d = 2, f = 3, h = 4, g = 5, z = 6, x = 7, c = 8, v = 9,
    b = 11, q = 12, w = 13, e = 14, r = 15, y = 16, t = 17, o = 31, u = 32,
    i = 34, p = 35, l = 37, j = 38, k = 40, n = 45, m = 46,
    ["1"] = 18, ["2"] = 19, ["3"] = 20, ["4"] = 21, ["5"] = 23, ["6"] = 22,
    ["7"] = 26, ["8"] = 28, ["9"] = 25, ["0"] = 29, [","] = 43, ["`"] = 50, [";"] = 41,
}
local ANSI_NAMES = {}
for name, code in pairs(ANSI) do ANSI_NAMES[code] = name end
local HYPER = "alt+cmd+ctrl+shift"
local function modsKey(mods)
    local sorted = {}
    for _, m in ipairs(mods) do table.insert(sorted, m) end
    table.sort(sorted)
    return table.concat(sorted, "+")
end
M.HYPER = HYPER

-- A chord with other modifiers than Hyper: M.pressWith({ "cmd", "alt" }, "f13")
function M.pressWith(mods, key)
    local fn = hotkeys[modsKey(mods) .. " " .. key]
    assert(fn, "no binding for " .. modsKey(mods) .. " " .. key)
    fn()
    M.flush()
end

function M.press(key)
    local fn = hotkeys[HYPER .. " " .. (ANSI_NAMES[ANSI[key]] or key)]
    assert(fn, "no Hyper binding for " .. key)
    fn()
    M.flush()
end

-- The hs global -------------------------------------------------------------

local function find(t, pred)
    for _, v in ipairs(t) do if pred(v) then return v end end
end
local function filter(t, pred)
    local out = {}
    for _, v in ipairs(t) do if pred(v) then table.insert(out, v) end end
    return out
end

local hs = stub()
hs.geometry = { rect = rect }
hs.fnutils = setmetatable({
    find = find,
    filter = filter,
    map = function(t, fn)
        local out = {}
        for i, v in ipairs(t) do out[i] = fn(v) end
        return out
    end,
    each = function(t, fn) for _, v in ipairs(t) do fn(v) end end,
    contains = function(t, x) return find(t, function(v) return v == x end) ~= nil end,
}, stubMeta)
hs.hotkey = setmetatable({
    bind = function(mods, key, fn)
        local name = ANSI_NAMES[key] or key
        table.insert(M.bindings, { mods = modsKey(mods), key = name })
        hotkeys[modsKey(mods) .. " " .. name] = fn
        return stub()
    end,
}, stubMeta)
hs.timer = setmetatable({
    secondsSinceEpoch = function() return now end,
    doAfter = function(sec, fn) return schedule(now + sec, fn) end,
    waitUntil = function(pred, fn, interval)
        interval = interval or 1
        local handle
        local function step()
            if pred() then fn() else handle = schedule(now + interval, step) end
        end
        handle = schedule(now + interval, step)
        return { stop = function() handle:stop() end, running = function() return true end }
    end,
    -- Repeating timers (Zoom share guard) never fire: nothing a test presses
    -- depends on them, and they would keep flush() busy forever
    doEvery = function() return stub() end,
    new = function() return stub() end,
}, stubMeta)
hs.window = setmetatable({
    focusedWindow = function() return M.focused() end,
    orderedWindows = function() return filter(zorder, visible) end,
    allWindows = function() return windows end,
    get = function(id) return find(windows, function(w) return w.i == id end) end,
}, stubMeta)
hs.screen = setmetatable({
    mainScreen = function() return screens[1] end,
    allScreens = function() return screens end,
}, stubMeta)
hs.application = setmetatable({
    applicationsForBundleID = function(bid)
        return apps[bid] and { apps[bid] } or {}
    end,
    get = function(name)
        for _, a in pairs(apps) do if a.n == name then return a end end
    end,
    frontmostApplication = function()
        local f = M.focused()
        return f and f.app
    end,
    launchOrFocusByBundleID = function(bid)
        local a = apps[bid]
        if a and a:mainWindow() then a:mainWindow():focus() end
    end,
    launchOrFocus = function() end,
}, stubMeta)
hs.alert = setmetatable({
    show = function(msg) table.insert(M.alerts, msg) end,
}, stubMeta)
-- Audio devices: M.audio(name, transport, kinds) adds one ("in", "out" or
-- "inout"), M.unplug(name) removes it, M.audioEvent() fires the watcher
local AudioDevice = {}
AudioDevice.__index = AudioDevice
function AudioDevice:name() return self.n end
function AudioDevice:uid() return self.n .. ":" .. self.kind end
function AudioDevice:transportType() return self.transport end
function AudioDevice:setDefaultOutputDevice() audioDefaults.output = self return true end
function AudioDevice:setDefaultEffectDevice() audioDefaults.effect = self return true end
function AudioDevice:setDefaultInputDevice() audioDefaults.input = self return true end
function AudioDevice:outputVolume() return self.volume end
function AudioDevice:outputMuted() return self.muted end
function AudioDevice:setOutputVolume(v) self.volume = v return true end
function AudioDevice:setOutputMuted(m) self.muted = m return true end
function M.audio(name, transport, kinds)
    for kind in (kinds or "inout"):gmatch("[io][nu]t?") do
        -- Volume 0 and muted, as the Shokz dongle comes up
        table.insert(audioDevices, setmetatable({ n = name, transport = transport, kind = kind,
                                                  volume = 0, muted = true }, AudioDevice))
    end
end
function M.unplug(name)
    audioDevices = filter(audioDevices, function(d) return d.n ~= name end)
end
function M.audioEvent(event) if audioCallback then audioCallback(event or "dev#") end end
function M.defaultAudio(kind) return audioDefaults[kind] and audioDefaults[kind].n end
local function ofKind(kind) return filter(audioDevices, function(d) return d.kind == kind end) end
hs.audiodevice = setmetatable({
    allInputDevices = function() return ofKind("in") end,
    allOutputDevices = function() return ofKind("out") end,
    defaultOutputDevice = function() return audioDefaults.output end,
    defaultInputDevice = function() return audioDefaults.input end,
    watcher = {
        setCallback = function(fn) audioCallback = fn end,
        start = function() end,
    },
}, stubMeta)
hs.fs = setmetatable({
    dir = function() return function() return nil end end,
    attributes = function() return nil end,
}, stubMeta)
hs.settings = setmetatable({ get = function() return nil end }, stubMeta)
hs.json = setmetatable({
    read = function(path)
        local f = io.open(path, "r")
        if not f then return nil end
        local text = f:read("a")
        f:close()
        return decodeJSON(text)
    end,
    write = function(data, path)
        M.written[path] = data
        return true
    end,
}, stubMeta)
hs.execute = function() return "", true end
-- HTTP: every URL asked for lands in M.requests; M.httpReply(fn) sets what
-- answers, fn(url) → status, body (default 200, "{}"). Answered at once.
M.requests = {}
function M.httpReply(fn) httpReply = fn end
hs.http = setmetatable({
    asyncGet = function(url, _, callback)
        table.insert(M.requests, url)
        callback(httpReply(url))
    end,
}, stubMeta)
hs.json.decode = decodeJSON

-- Application watcher: M.appEvent("activated" | "deactivated", app) calls
-- every watcher started, as Hammerspoon would
hs.application.watcher = {
    activated = 5, deactivated = 6,
    new = function(fn)
        local w = { start = function(self) table.insert(appWatchers, fn) return self end, stop = function() end }
        return w
    end,
}
function M.appEvent(event, app)
    for _, fn in ipairs(appWatchers) do fn(app:name(), hs.application.watcher[event], app) end
end

-- URLs opened through hs.urlevent land in M.urls
M.urls = {}
hs.urlevent = setmetatable({
    openURL = function(url) table.insert(M.urls, url) return true end,
}, stubMeta)

-- Accessibility: an element is a table of attributes plus `children`;
-- M.axTree(app, windows) sets the app's AXWindows. An element with `press`
-- set records the press in M.axPressed (the value of `press`).
M.axPressed = {}
local AXElement = {}
AXElement.__index = AXElement
function AXElement:attributeValue(name)
    if name == "AXChildren" then return self.children end
    return self.attrs[name]
end
function AXElement:setAttributeValue(name, value) self.attrs[name] = value return self end
function AXElement:performAction(action)
    if action == "AXPress" and self.press then table.insert(M.axPressed, self.press) return self end
    return nil
end
function M.ax(attrs, children, press)
    return setmetatable({ attrs = attrs or {}, children = children or {}, press = press }, AXElement)
end
function M.axTree(app, windows) app.axWindows = windows end
hs.axuielement = setmetatable({
    applicationElement = function(app)
        return M.ax({ AXWindows = app.axWindows or {} })
    end,
}, stubMeta)

_G.hs = hs
package.preload["hs.ipc"] = function() return stub() end

-- Keep the real machine out of reach
local realGetenv = os.getenv
os.getenv = function(name)
    if name == "HOME" then return "/nonexistent-hammerspoon-test-home" end
    return realGetenv(name)
end
os.remove = function() return true end

-- Files under the fake HOME come from M.files (path relative to HOME →
-- contents); any other path under it doesn't exist. Appending ("a") creates
-- or extends the entry.
M.files = {}
local realOpen = io.open
local FAKE_HOME = "/nonexistent-hammerspoon-test-home/"
io.open = function(path, mode)
    if path:sub(1, #FAKE_HOME) ~= FAKE_HOME then return realOpen(path, mode) end
    local rel = path:sub(#FAKE_HOME + 1)
    if mode == "a" then
        return {
            write = function(_, ...) M.files[rel] = (M.files[rel] or "") .. table.concat({ ... }) end,
            close = function() end,
        }
    end
    local text = M.files[rel]
    if not text then return nil end
    return {
        lines = function() return text:gmatch("[^\n]+") end,
        read = function() return text end,
        close = function() end,
    }
end

function M.load(path)
    dofile(path)
    M.flush()
end

return M
