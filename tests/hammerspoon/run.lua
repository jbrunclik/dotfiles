-- Run every tests/hammerspoon/*_test.lua. From the repo root:
--   lua tests/hammerspoon/run.lua
-- The files under test are config/hammerspoon/init.lua,
-- config/karabiner/karabiner.json and GUIDE.md, or HS_CONFIG, HS_KARABINER
-- and HS_GUIDE (to check a test fails against a broken copy). init.lua reads
-- karabiner.json from ../karabiner next to itself.

package.path = "tests/hammerspoon/?.lua;" .. package.path
local runner = require("runner")

local list = io.popen("ls tests/hammerspoon/*_test.lua")
for path in list:lines() do dofile(path) end
list:close()

os.exit(runner.run() and 0 or 1)
