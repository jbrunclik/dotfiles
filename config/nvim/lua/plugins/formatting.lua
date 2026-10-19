return {
  -- Formatter: conform runs ruff (organize imports, then format) for Python,
  -- prettier for the web/config types and shfmt for shell scripts, on save.
  -- Other filetypes fall back to the language server's formatting, if it has
  -- one (taplo for TOML).
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
        sh = { "shfmt" },
      },
      -- shfmt takes its indent from 'shiftwidth'; -ci keeps case branches
      -- indented, as the repo's scripts write them
      formatters = {
        shfmt = { prepend_args = { "-ci" } },
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
