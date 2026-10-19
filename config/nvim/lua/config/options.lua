vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- No plugin uses the Python, Node, Ruby or Perl hosts; skipping them saves
-- the lookups and the :checkhealth warnings
vim.g.loaded_python3_provider = 0
vim.g.loaded_node_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0

local opt = vim.opt

-- Appearance
opt.termguicolors = true
opt.background = "dark"
opt.cursorline = true
opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes"
opt.colorcolumn = "88" -- matches ruff's default and VS Code's ruler
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

-- Floats (hover, signature help, diagnostics) get an edge; with Catppuccin
-- they otherwise blend into the buffer
opt.winborder = "rounded"

-- Diagnostics: 0.11 turned inline messages off by default, leaving only the
-- sign column. Show the message at the end of the cursor's line only, so the
-- rest of the buffer stays readable; errors sort ahead of warnings.
vim.diagnostic.config({
  virtual_text = { current_line = true },
  severity_sort = true,
})
