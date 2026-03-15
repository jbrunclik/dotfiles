return {
  -- Surround operations (add/delete/change quotes, brackets, tags)
  { "echasnovski/mini.surround", version = false, opts = {} },

  -- Auto pairs
  { "echasnovski/mini.pairs", version = false, opts = {} },

  -- Copilot (loaded eagerly — lazy loading causes activation issues)
  {
    "github/copilot.vim",
    lazy = false,
    init = function()
      vim.g.copilot_settings = {}
      vim.g.copilot_no_tab_map = true
      vim.g.copilot_assume_mapped = true
    end,
    config = function()
      vim.keymap.set("i", "<Tab>", 'copilot#Accept("\\<Tab>")', { expr = true, replace_keycodes = false, silent = true })
    end,
  },
}
