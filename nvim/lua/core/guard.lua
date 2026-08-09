vim.pack.add({
  { src = 'https://github.com/nvimdev/guard.nvim' },
})

--------------------------------------------------
-- Linting & Formatting
--------------------------------------------------

vim.g.guard_config = {
  fmt_on_save = false,
  lsp_as_default_formatter = false,
  save_on_fmt = false,
  auto_lint = true,
  lint_interval = 500,
  refresh_diagnostic = true,
  always_save = false,
}

local ft = require('guard.filetype')
local lint = require('guard.lint')

ft('lua'):fmt({
  cmd = 'stylua',
  args = { '-' },
  stdin = true,
})
ft('json'):fmt({
  cmd = 'jq',
  stdin = true,
})
ft('rust'):fmt({
  cmd = 'rustfmt',
  args = { '--edition', '2021', '--emit', 'stdout' },
  stdin = true,
})
ft('sh'):fmt({
  cmd = 'shfmt',
  stdin = true,
}):lint({
  cmd = 'shellcheck',
  args = { '--format', 'json1', '--external-sources' },
  parse = lint.from_json({
    get_diagnostics = function(...)
      return vim.json.decode(...).comments
    end,
    attributes = {
      severity = 'level',
    },
    source = 'shellcheck',
  }),
})
ft('typescript,javascript,svelte'):lint({
  cmd = 'npx',
  args = { 'eslint', '--format', 'json', '--stdin', '--stdin-filename' },
  stdin = true,
  fname = true,
  find = {
    '.eslintrc.js',
    '.eslintrc.cjs',
    '.eslintrc.yaml',
    '.eslintrc.yml',
    '.eslintrc.json',
    'eslint.config.js',
    'eslint.config.cjs',
    'eslint.config.mjs',
    'eslint.config.ts',
    'eslint.config.cts',
    'eslint.config.mts',
  },
  parse = lint.from_json({
    get_diagnostics = function(...)
      return vim.json.decode(...)[1].messages
    end,
    attributes = {
      lnum = 'line',
      end_lnum = 'endLine',
      col = 'column',
      end_col = 'endColumn',
      message = 'message',
      code = 'ruleId',
    },
    severities = {
      lint.severities.warning,
      lint.severities.error,
    },
    source = 'eslint',
  }),
})
ft('typescript,javascript,svelte,html,css,json'):fmt({
  cmd = 'npx',
  args = { 'prettier', '--stdin-filepath', '--print-width', '120', '--tab-width', '4' },
  fname = true,
  stdin = true,
})
ft('markdown'):fmt({
  cmd = 'npx',
  args = { 'prettier', '--stdin-filepath', '--print-width', '120', '--tab-width', '4' },
  fname = true,
  stdin = true,
}):append({
  cmd = 'markdown-toc',
  stdin = true,
})
ft('sql'):fmt({
  cmd = 'sqlfluff',
  args = { 'fix', '-' },
  stdin = true,
}):lint({
  cmd = 'sqlfluff',
  args = { 'lint', '-f', 'github-annotation' },
  stdin = true,
  parse = lint.from_json({
    attributes = {
      row = 'line',
      col = 'start_column',
      end_col = 'end_column',
      severity = 'annotation_level',
      message = 'message',
    },
    severities = {
      notice = lint.severities.info,
      warning = lint.severities.warning,
      error = lint.severities.error,
    },
    source = 'sqlfluff',
  }),
})
ft('go'):fmt({
  cmd = 'gofmt',
  stdin = true,
})

local phpstan_args = {
  'analyze',
  '--memory-limit=256M',
  '--error-format=json',
  '--no-progress',
}
local phpstanDir = vim.fs.root(0, 'phpstan.neon')
if phpstanDir then
  table.insert(phpstan_args, '-c')
  table.insert(phpstan_args, phpstanDir .. '/phpstan.neon')
end
ft('php'):fmt({
  cmd = 'php-cs-fixer',
  args = {
    'fix',
    '--quiet',
    '--no-interaction',
  },
  fname = true,
  stdin = false,
}):lint({
  cmd = 'phpstan',
  args = phpstan_args,
  fname = true,
  ignore_exitcode = true,
  parse = lint.from_json({
    attributes = {
      lnum = 'line',
      col = 0,
      message = 'message',
      code = 'identifier',
      severity = 'type',
    },
    severities = {
      warning = lint.severities.warning,
    },
    source = 'phpstan',
    lines = false,
    get_diagnostics = function(output)
      local status, decoded = pcall(vim.json.decode, output)
      if not status or not decoded or not decoded.files then
        return {}
      end

      local _, file_data = next(decoded.files)

      if file_data and file_data.messages then
        for _, msg in ipairs(file_data.messages) do
          msg.type = 'warning'
        end
        return file_data.messages
      end

      return {}
    end,
  }),
})

vim.keymap.set({ 'n', 'x' }, '<leader>cf', '<cmd>Guard fmt<CR>', { desc = '[C]ode [F]ormat current file' })
