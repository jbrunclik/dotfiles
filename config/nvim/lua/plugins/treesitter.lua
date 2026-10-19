-- nvim-treesitter `main` branch.
--
-- The `main` rewrite dropped the old declarative API: setup() honours only
-- `install_dir`, so passing `ensure_installed`/`auto_install` there is silently
-- ignored and parsers never install. Highlighting is no longer switched on by
-- the plugin either ("These are not automatically enabled" per its README) —
-- it's core Neovim's `vim.treesitter.start()`, called per buffer.
--
-- So: install parsers explicitly, then start the highlighter on FileType.
local parsers = {
  "python", "typescript", "tsx", "javascript",
  "yaml", "json", "html", "css",
  "lua", "vim", "vimdoc",
  "markdown", "markdown_inline",
  "bash", "toml", "regex",
  "diff", "gitcommit", "git_rebase", "dockerfile", "luadoc", "query",
}

-- Treesitter indent only where it's reliable; it's still experimental for
-- Python and YAML, which keep Vim's own indent scripts
local ts_indent = { lua = true, javascript = true, typescript = true, tsx = true, json = true, html = true, css = true, bash = true }

return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  build = ":TSUpdate",
  lazy = false,
  config = function()
    require("nvim-treesitter").setup()

    -- install() is async and a no-op for parsers already present
    local ts = require("nvim-treesitter")
    local installed = ts.get_installed()
    local missing = vim.tbl_filter(function(p)
      return not vim.tbl_contains(installed, p)
    end, parsers)
    if #missing > 0 then
      ts.install(missing)
    end

    -- Enable highlighting, plus treesitter indent for the languages above.
    -- pcall'd because a FileType can fire before its parser has finished
    -- installing on first launch.
    vim.api.nvim_create_autocmd("FileType", {
      callback = function(ev)
        local lang = vim.treesitter.language.get_lang(ev.match)
        if not lang or not pcall(vim.treesitter.start, ev.buf, lang) then
          return
        end
        if ts_indent[lang] then
          vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end,
    })
  end,
}
