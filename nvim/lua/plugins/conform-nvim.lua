return {
  'stevearc/conform.nvim',
  event = { 'BufWritePre' },
  cmd = { 'ConformInfo' },
  -- stylua: ignore
  keys = {
    { "<leader>cf", function() require("conform").format({ bufnr = 0, async = true, lsp_format = "fallback" }) end, desc = "[C]ode [F]ormat current file", }
  },
  config = function()
    local conform = require('conform')

    local slow_format_filetypes = {}
    local opts = {
      formatters_by_ft = {
        lua = { 'stylua' },
        svelte = { { 'prettierd', 'prettier' } },
        javascript = { { 'prettierd', 'prettier' } },
        typescript = { { 'prettierd', 'prettier' } },
        javascriptreact = { { 'prettierd', 'prettier' } },
        typescriptreact = { { 'prettierd', 'prettier' } },
        css = { { 'prettierd', 'prettier' } },
        json = { { 'prettierd', 'prettier' } },
        markdown = { { 'prettierd', 'prettier' }, 'markdownlint', 'markdown-toc' },
        html = { { 'prettierd', 'prettier' } },
        sh = { 'shfmt' },
        rust = { 'rustfmt' },
        yaml = { 'yamlfmt' },
        toml = { 'taplo' },
        java = { 'google-java-format' },
      },
      format_on_save = function(bufnr)
        if slow_format_filetypes[vim.bo[bufnr].filetype] then
          return
        end
        local function on_format(err)
          if err and err:match('timeout$') then
            slow_format_filetypes[vim.bo[bufnr].filetype] = true
          end
        end

        return { timeout_ms = 200, lsp_format = 'fallback' }, on_format
      end,

      format_after_save = function(bufnr)
        if not slow_format_filetypes[vim.bo[bufnr].filetype] then
          return
        end
        return { lsp_format = 'fallback' }
      end,
      notify_on_error = false,
    }

    conform.setup(opts)

    vim.o.formatexpr = "v:lua.require'conform'.formatexpr()" -- makes gq use conform
  end,
}
