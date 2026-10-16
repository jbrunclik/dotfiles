return {
  "catppuccin/nvim",
  name = "catppuccin",
  priority = 1000,
  opts = {
    flavour = "mocha",
    -- Was integrations.native_lsp, which Catppuccin dropped: ignored silently,
    -- so diagnostics were plain underlines
    lsp_styles = {
      underlines = {
        errors = { "undercurl" },
        hints = { "undercurl" },
        warnings = { "undercurl" },
        information = { "undercurl" },
      },
    },
    integrations = {
      blink_cmp = true,
      fzf = true,
      gitsigns = true,
      indent_blankline = { enabled = true },
      mason = true,
      treesitter = true,
      which_key = true,
    },
  },
  config = function(_, opts)
    require("catppuccin").setup(opts)
    vim.cmd.colorscheme("catppuccin")
  end,
}
