local map = vim.keymap.set

-- Physical line navigation (matches your old vimrc)
map("n", "j", "gj", { silent = true, desc = "Down (visual line)" })
map("n", "k", "gk", { silent = true, desc = "Up (visual line)" })

-- Clear search highlight
map("n", "<Esc>", "<cmd>nohlsearch<cr>")

-- Better window navigation
map("n", "<C-h>", "<C-w>h", { desc = "Window left" })
map("n", "<C-j>", "<C-w>j", { desc = "Window down" })
map("n", "<C-k>", "<C-w>k", { desc = "Window up" })
map("n", "<C-l>", "<C-w>l", { desc = "Window right" })

-- Resize splits
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Grow split height" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Shrink split height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Shrink split width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Grow split width" })

-- Move lines up/down in visual mode
map("v", "J", ":m '>+1<cr>gv=gv", { silent = true, desc = "Move lines down" })
map("v", "K", ":m '<-2<cr>gv=gv", { silent = true, desc = "Move lines up" })

-- Keep cursor centered when scrolling
map("n", "<C-d>", "<C-d>zz", { desc = "Scroll down (centered)" })
map("n", "<C-u>", "<C-u>zz", { desc = "Scroll up (centered)" })

-- Diagnostic navigation
map("n", "[d", function() vim.diagnostic.jump({ count = -1 }) end, { desc = "Prev diagnostic" })
map("n", "]d", function() vim.diagnostic.jump({ count = 1 }) end, { desc = "Next diagnostic" })
map("n", "<leader>e", vim.diagnostic.open_float, { desc = "Diagnostic float" })

-- Buffer navigation
map("n", "<leader>bn", "<cmd>bnext<cr>", { desc = "Next buffer" })
map("n", "<leader>bp", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
map("n", "<leader>bd", "<cmd>bdelete<cr>", { desc = "Delete buffer" })
