return {
  'mfussenegger/nvim-lint',
  event = { 'BufReadPre', 'BufNewFile' },
  config = function()
    local lint = require('lint')

    lint.linters_by_ft = {
      javascript = { 'eslint_d' },
      typescript = { 'eslint_d' },
      javascriptreact = { 'eslint_d' },
      typescriptreact = { 'eslint_d' },
      svelte = { 'eslint_d' },
      markdown = { 'markdownlint' },
      sh = { 'shellcheck' },
      json = { 'jsonlint' },
      text = { 'vale' },
      -- work
      php = { 'phpcs' },
      -- ['yaml.ansible'] = { 'ansible-lint', },
    }

    lint.linters.shellcheck.args = { '-x' }

    local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })
    vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
      group = lint_augroup,
      callback = function()
        if vim.o.buftype == '' then
          lint.try_lint()
        end
      end,
    })

    vim.keymap.set('n', '<leader>cl', function()
      lint.try_lint()
    end, { desc = '[C]ode [L]int current file' })
  end,
}
