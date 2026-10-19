require("config.options")
require("config.keymaps")
require("config.autocmds")

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- lazy-lock.json is tracked, so updates are deliberate (:Lazy update, then
-- commit the lock) and a bad one rolls back with :Lazy restore. No update
-- checker: with notify off it fetched every plugin on each start and told no one.
require("lazy").setup("plugins", {
  install = { colorscheme = { "catppuccin" } },
  checker = { enabled = false },
})
