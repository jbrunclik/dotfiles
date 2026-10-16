return {
  -- Formatter: conform runs ruff (organize imports, then format) for Python
  -- and prettier for the web/config types, on save. Other filetypes fall back
  -- to the language server's formatting, if it has one.
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    keys = {
      { "<leader>cf", function() require("conform").format({ async = true }) end, desc = "Format buffer" },
    },
    opts = {
      formatters_by_ft = {
        python = { "ruff_organize_imports", "ruff_format" },
        typescript = { "prettier" },
        typescriptreact = { "prettier" },
        javascript = { "prettier" },
        javascriptreact = { "prettier" },
        yaml = { "prettier" },
        json = { "prettier" },
        markdown = { "prettier" },
      },
      format_on_save = {
        timeout_ms = 3000,
        lsp_format = "fallback",
      },
    },
  },

  -- Linter
  -- Python: ruff LSP provides diagnostics natively (no nvim-lint needed)
  -- TypeScript: eslint_d via nvim-lint
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local lint = require("lint")
      lint.linters_by_ft = {
        typescript = { "eslint_d" },
        typescriptreact = { "eslint_d" },
        javascript = { "eslint_d" },
        javascriptreact = { "eslint_d" },
      }
      vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost" }, {
        callback = function()
          lint.try_lint()
        end,
      })
    end,
  },
}
