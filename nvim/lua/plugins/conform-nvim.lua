return {
  'stevearc/conform.nvim',
  -- stylua: ignore
  keys = {
    { '<leader>cf', function() require('conform').format({ bufnr = 0, async = true, lsp_format = 'fallback' }) end, desc = '[C]ode [F]ormat current file', },
    { 'gqp', 'mfgqap`f', desc = 'Format Paragraph', },
    { 'gqg', 'mfgqag`f', desc = 'Format File', remap = true }
  },
  config = function()
    local conform = require('conform')

    local opts = {
      formatters = {
        ['markdown-toc'] = {
          prepend_args = { '--bullets', '-' },
        },
      },
      formatters_by_ft = {
        lua = { 'stylua' },
        svelte = { 'prettierd', 'prettier', stop_after_first = true },
        javascript = { 'prettierd', 'prettier', stop_after_first = true },
        typescript = { 'prettierd', 'prettier', stop_after_first = true },
        javascriptreact = { 'prettierd', 'prettier', stop_after_first = true },
        typescriptreact = { 'prettierd', 'prettier', stop_after_first = true },
        css = { 'prettierd', 'prettier', stop_after_first = true },
        json = { 'prettierd', 'prettier', stop_after_first = true },
        markdown = { 'prettierd', 'prettier', 'markdownlint', 'markdown-toc' },
        html = { 'prettierd', 'prettier', stop_after_first = true },
        sh = { 'shfmt' },
        rust = { 'rustfmt' },
        yaml = { 'yamlfmt' },
        toml = { 'taplo' },
        java = { 'google-java-format' },
      },
      notify_on_error = false,
    }

    conform.setup(opts)

    vim.o.formatexpr = "v:lua.require'conform'.formatexpr()" -- makes gq use conform
  end,
}
