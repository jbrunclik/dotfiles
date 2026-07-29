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
}

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

    -- Enable highlighting, plus treesitter indent where a parser exists.
    -- pcall'd because a FileType can fire before its parser has finished
    -- installing on first launch.
    vim.api.nvim_create_autocmd("FileType", {
      callback = function(ev)
        local lang = vim.treesitter.language.get_lang(ev.match)
        if not lang or not pcall(vim.treesitter.start, ev.buf, lang) then
          return
        end
        vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end,
    })
  end,
}
