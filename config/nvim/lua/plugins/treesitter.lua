return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  event = { "BufReadPost", "BufNewFile" },
  opts = {
    ensure_installed = {
      "python", "typescript", "tsx", "javascript",
      "yaml", "json", "html", "css",
      "lua", "vim", "vimdoc",
      "markdown", "markdown_inline",
      "bash", "toml", "regex",
    },
    auto_install = true,
  },
  config = function(_, opts)
    require("nvim-treesitter").setup(opts)
  end,
}
