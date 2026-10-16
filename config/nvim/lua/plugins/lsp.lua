local servers = { "basedpyright", "ruff", "ts_ls", "yamlls", "lua_ls" }

return {
  -- Mason: auto-install LSP servers
  {
    "mason-org/mason.nvim",
    opts = {},
  },
  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = {
      "mason-org/mason.nvim",
      "neovim/nvim-lspconfig",
    },
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
    dependencies = { "saghen/blink.cmp" },
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

  -- Autocompletion
  {
    "saghen/blink.cmp",
    version = "1.*",
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
