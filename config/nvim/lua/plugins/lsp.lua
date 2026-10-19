local servers = { "basedpyright", "ruff", "ts_ls", "yamlls", "lua_ls" }

return {
  -- Mason: auto-install LSP servers. Neither loads at startup: they come in
  -- with nvim-lspconfig when the first file opens (Mason's setup puts the
  -- servers on PATH before they're started), or with :Mason. Loading them
  -- eagerly pulled in lspconfig and blink.cmp before there was any file.
  {
    "mason-org/mason.nvim",
    cmd = "Mason",
    opts = {},
  },
  {
    "mason-org/mason-lspconfig.nvim",
    lazy = true,
    dependencies = { "mason-org/mason.nvim" },
    opts = {
      ensure_installed = servers,
      -- Enabled below, once, with the shared capabilities
      automatic_enable = false,
    },
  },

  -- LSP config
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "mason-org/mason.nvim",
      "mason-org/mason-lspconfig.nvim",
      "saghen/blink.cmp",
    },
    config = function()
      -- Pass blink.cmp capabilities to all servers
      vim.lsp.config("*", {
        capabilities = require("blink.cmp").get_lsp_capabilities(),
      })

      -- Enable servers (configs come from nvim-lspconfig + the lsp/ directory)
      vim.lsp.enable(servers)

      -- Neovim maps the rest itself: K, grn grr gri gra grt gO, <C-s>.
      -- Mapping gr or gi here shadowed those (gi is also "insert where you
      -- left off"), so only definition, which has no default, is added.
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(ev)
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = ev.buf, desc = "Go to definition" })
        end,
      })
    end,
  },

  -- Autocompletion: with lspconfig for files, on InsertEnter for a buffer
  -- with no file (bare `nvim`)
  {
    "saghen/blink.cmp",
    version = "1.*",
    event = "InsertEnter",
    dependencies = { "rafamadriz/friendly-snippets" },
    opts = {
      keymap = {
        preset = "default",
        ["<CR>"] = { "accept", "fallback" },
      },
      appearance = {
        nerd_font_variant = "mono",
      },
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
      },
      completion = {
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 200,
        },
      },
      signature = { enabled = true },
    },
  },
}
