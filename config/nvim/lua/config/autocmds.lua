local autocmd = vim.api.nvim_create_autocmd

-- Highlight on yank
autocmd("TextYankPost", {
  callback = function()
    vim.hl.on_yank()
  end,
})

-- 2-space indent for YAML, TypeScript, JSON
autocmd("FileType", {
  pattern = { "yaml", "typescript", "typescriptreact", "javascript", "javascriptreact", "json", "lua" },
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
  end,
})

-- Close some filetypes with just <q>
autocmd("FileType", {
  pattern = { "help", "man", "qf", "checkhealth", "lspinfo" },
  callback = function(ev)
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = ev.buf, silent = true })
  end,
})
