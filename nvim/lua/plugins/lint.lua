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
      php = { 'phpstan' },
      -- php = { 'phpcs' },
      -- ['yaml.ansible'] = { 'ansible-lint', },
    }

    lint.linters.phpstan.args = {
      'analyze',
      '--error-format=json',
      '--no-progress',
      '--memory-limit=256M',
    }

    local phpcs_info = {
      'Generic.Functions.FunctionCallArgumentSpacing.NoSpaceAfterComma',
      'Generic.Commenting.DocComment.Empty',
      'Generic.Commenting.DocComment.SpacingBeforeTags',
      'Generic.Commenting.DocComment.MissingShort',
      'Generic.PHP.LowerCaseConstant.Found',
      'Squiz.Commenting.DocCommentAlignment.SpaceBeforeStar',
      'PEAR.WhiteSpace.ScopeIndent.Incorrect',
      'PEAR.WhiteSpace.ScopeIndent.IncorrectExact',
      'PEAR.WhiteSpace.ObjectOperatorIndent.Incorrect',
      'PEAR.WhiteSpace.ScopeClosingBrace.Line',
      'PEAR.WhiteSpace.ScopeClosingBrace.Indent',
      'PEAR.ControlStructures.ControlSignature.Found',
      'PEAR.ControlStructures.MultiLineCondition.SpaceBeforeOpenBrace',
      'PEAR.ControlStructures.MultiLineCondition.NewlineBeforeOpenBrace',
      'PEAR.Functions.FunctionCallSignature.CloseBracketLine',
      'PEAR.Functions.FunctionCallSignature.ContentAfterOpenBracket',
      'PEAR.Functions.FunctionDeclaration.BraceOnSameLine',
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
          if vim.list_contains(phpcs_info, d.code) then
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
