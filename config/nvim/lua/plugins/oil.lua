-- File explorer as a buffer: a directory is a list of names you edit like
-- text — rename a line to rename the file, dd to delete, yank/paste to copy or
-- move — and :w applies it (after a confirmation listing every change).
-- Loaded at startup so `nvim .` opens it instead of netrw.
return {
  "stevearc/oil.nvim",
  lazy = false,
  dependencies = { "nvim-tree/nvim-web-devicons" },
  keys = {
    { "-", "<cmd>Oil<cr>", desc = "Open parent directory (Oil)" },
  },
  opts = {
    default_file_explorer = true,
    -- Dotfiles are most of what gets edited here
    view_options = { show_hidden = true },
    -- Deleted files go to the macOS Trash, not straight to nowhere
    delete_to_trash = true,
  },
}
