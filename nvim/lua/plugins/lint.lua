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
    -- exclude phpdocs lint
    local original_parse_phpcs = lint.linters.phpcs.parser
    lint.linters.phpcs = {
      name = 'phpcs',
      cmd = 'phpcs',
      stdin = true,
      args = {
        '-q',
        '--exclude=PEAR.Commenting.FunctionComment,'
          .. 'Generic.Files.LineLength,'
          .. 'Generic.PHP.DisallowShortOpenTag,'
          .. 'Squiz.Commenting.FunctionComment,'
          .. 'Squiz.Commenting.LongConditionClosingComment,'
          .. 'PEAR.Commenting.FileComment,'
          .. 'PEAR.Commenting.ClassComment',
        -- otherwise it shows error codes on every error/warnings
        '--runtime-set',
        'ignore_errors_on_exit',
        '1',
        -- '--config-set',
        '--runtime-set',
        'php_version',
        '70033',
        '--report=json',
        '-',
      },
      parser = function(output, bufnr, linter_cwd)
        local diagnostics = original_parse_phpcs(output, bufnr, linter_cwd)
        for _, d in ipairs(diagnostics) do
          if d.code == 'PEAR.WhiteSpace.ScopeIndent.IncorrectExact' then
            d.severity = vim.diagnostic.severity.INFO
          end
        end
        return diagnostics
      end,
    }

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
