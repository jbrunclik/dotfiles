vim.g.mapleader = " "
vim.g.maplocalleader = " "

local opt = vim.opt

-- Appearance
opt.termguicolors = true
opt.background = "dark"
opt.cursorline = true
opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes"
opt.colorcolumn = "80"
opt.showmode = false -- lualine shows the mode

-- Indentation
opt.expandtab = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.smartindent = true

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true

-- Behavior
opt.splitbelow = true
opt.splitright = true
opt.mouse = "a"
opt.clipboard = "unnamedplus"
opt.undofile = true
opt.backup = false
opt.swapfile = false
opt.updatetime = 100
opt.scrolloff = 8

-- Whitespace display
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
