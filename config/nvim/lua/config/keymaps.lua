local map = vim.keymap.set

-- j/k move by screen line through wrapped text, but a count (5j) moves real
-- lines — the ones relativenumber counts. Plain gj/gk broke `5j` there.
map("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true, desc = "Down (screen line)" })
map("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true, desc = "Up (screen line)" })

-- Clear search highlight
map("n", "<Esc>", "<cmd>nohlsearch<cr>")

-- Better window navigation
map("n", "<C-h>", "<C-w>h", { desc = "Window left" })
map("n", "<C-j>", "<C-w>j", { desc = "Window down" })
map("n", "<C-k>", "<C-w>k", { desc = "Window up" })
map("n", "<C-l>", "<C-w>l", { desc = "Window right" })

-- Move lines up/down in visual mode. "x", not "v": "v" also covers Select
-- mode, where typing J or K over a snippet placeholder must insert the letter
map("x", "J", ":m '>+1<cr>gv=gv", { silent = true, desc = "Move lines down" })
map("x", "K", ":m '<-2<cr>gv=gv", { silent = true, desc = "Move lines up" })

-- Keep cursor centered when scrolling
map("n", "<C-d>", "<C-d>zz", { desc = "Scroll down (centered)" })
map("n", "<C-u>", "<C-u>zz", { desc = "Scroll up (centered)" })

-- Diagnostics and LSP use Neovim's built-in keys (0.11+): [d ]d, <C-w>d,
-- K, grn grr gri gra grt gO, <C-s> in insert mode. Split resizing is
-- <C-w>+ - < > — Ctrl+arrows never arrive, macOS takes them for Spaces.

-- Buffer navigation
map("n", "<leader>bn", "<cmd>bnext<cr>", { desc = "Next buffer" })
map("n", "<leader>bp", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
map("n", "<leader>bd", "<cmd>bdelete<cr>", { desc = "Delete buffer" })
