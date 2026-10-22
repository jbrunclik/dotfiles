-- A minimal test runner: each *_test.lua registers tests with test(), and
-- run.lua runs them all, printing ok / FAIL per test.

local M = { tests = {} }

function M.test(name, fn)
    table.insert(M.tests, { name = name, fn = fn, file = debug.getinfo(2, "S").short_src })
end

function M.run()
    local failed = 0
    for _, t in ipairs(M.tests) do
        local ok, err = pcall(t.fn)
        if ok then
            print("ok    " .. t.name)
        else
            failed = failed + 1
            print("FAIL  " .. t.name .. "\n      " .. tostring(err))
        end
    end
    print(string.format("\n%d tests, %d failed", #M.tests, failed))
    return failed == 0
end

return M
