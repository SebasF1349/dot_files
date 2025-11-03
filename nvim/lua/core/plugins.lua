vim.pack.add({
  { src = 'https://github.com/catppuccin/nvim', name = 'catppuccin' },

  { src = 'https://github.com/nvim-treesitter/nvim-treesitter', version = 'main' },

  { src = 'https://github.com/mfussenegger/nvim-lint' },
  { src = 'https://github.com/stevearc/conform.nvim' },

  { src = 'https://github.com/tpope/vim-fugitive' },
  { src = 'https://github.com/lewis6991/gitsigns.nvim' },

  { src = 'https://github.com/mfussenegger/nvim-dap' },
  { src = 'https://github.com/igorlfs/nvim-dap-view' },
  { src = 'https://github.com/theHamsta/nvim-dap-virtual-text' },

  { src = 'https://github.com/nvim-mini/mini.splitjoin' },
  { src = 'https://github.com/nvim-mini/mini.ai' },
  { src = 'https://github.com/nvim-lua/plenary.nvim' },
  { src = 'https://github.com/ThePrimeagen/refactoring.nvim' },
  { src = 'https://github.com/windwp/nvim-ts-autotag' },
  { src = 'https://github.com/artemave/workspace-diagnostics.nvim' },

  { src = 'https://github.com/stevearc/oil.nvim' },

  { src = 'https://github.com/mason-org/mason.nvim' },
})

vim.api.nvim_create_user_command('PUpdate', function() vim.pack.update() end, {})

--------------------------------------------------
-- Theme
--------------------------------------------------

require('catppuccin').setup({
  flavour = 'mocha',
  transparent_background = true,
  default_integrations = false,
  integrations = {
    cmp = true,
    dap = true,
    gitsigns = true,
    markdown = true,
    mason = true,
    mini = true,
    semantic_tokens = true,
    treesitter = true,
  },
  custom_highlights = function(colors)
    return {
      LspReferenceShow = { bg = colors.surface1 }, -- custom hl

      Pmenu = { bg = colors.base, fg = colors.overlay2 },

      NormalFloat = { bg = colors.base, fg = colors.text },
      FloatBorder = { bg = colors.base, fg = colors.text },

      TerminalNormal = { bg = colors.base, fg = colors.text },

      -- Checkhealth
      ['@health.success'] = { bg = colors.none, fg = colors.teal, style = { 'bold', 'underline' } }, -- healthSuccess
      ['@health.warning'] = { bg = colors.none, fg = colors.yellow, style = { 'bold', 'underline' } }, -- healthWarning
      ['@health.error'] = { bg = colors.none, fg = colors.red, style = { 'bold', 'underline' } }, -- healthError
    }
  end,
})
vim.cmd.colorscheme('catppuccin')

--------------------------------------------------
-- Linting
--------------------------------------------------

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

local phpstanDir = vim.fs.root(0, 'phpstan.neon')
if phpstanDir then
  lint.linters.phpstan.args = {
    'analyse',
    '--error-format=json',
    '--no-progress',
    '-c', phpstanDir .. '/phpstan.neon',
    '--memory-limit=256M',
  }
end

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

--------------------------------------------------
-- Formatting
--------------------------------------------------

require('conform').setup({
  formatters = {
    ['markdown-toc'] = {
      prepend_args = { '--bullets', '-' },
    },
  },
  formatters_by_ft = {
    lua = { 'stylua' },
    svelte = { 'prettier', stop_after_first = true },
    javascript = { 'prettier', stop_after_first = true },
    typescript = { 'prettier', stop_after_first = true },
    javascriptreact = { 'prettier', stop_after_first = true },
    typescriptreact = { 'prettier', stop_after_first = true },
    css = { 'prettier', stop_after_first = true },
    json = { 'prettier', stop_after_first = true },
    markdown = { 'prettier', 'markdownlint', 'markdown-toc' },
    html = { 'prettier', stop_after_first = true },
    sh = { 'shfmt' },
    rust = { 'rustfmt' },
    yaml = { 'yamlfmt' },
    php = { 'php_cs_fixer' },
  },
  notify_on_error = false,
})
vim.o.formatexpr = "v:lua.require'conform'.formatexpr()" -- makes gq use conform
vim.keymap.set('n', '<leader>cf', function() require('conform').format({ bufnr = 0, async = true, lsp_format = 'fallback' }) end, { desc = '[C]ode [F]ormat current file', })
vim.keymap.set('x',  'gqp', 'mfgqap`f', { desc = 'Format Paragraph', })
vim.keymap.set('x',  'gqg', 'mfgqag`f', { desc = 'Format File', remap = true })
vim.keymap.set('x', '=', ':s/\\s\\+$//e<CR>gv=', { desc = 'Indent and Remove Trailing Whitespace' })

--------------------------------------------------
-- Debug
--------------------------------------------------

local function debug_run()
  if package.loaded['dap-view'] then
    return require('dap')
  end

  local dap = require('dap')
  local widgets = require('dap.ui.widgets')
  local dapview = require('dap-view')
  require("nvim-dap-virtual-text").setup({})

  dap.listeners.before.attach['dap-view-config'] = function()
    dapview.open()
  end
  dap.listeners.before.launch['dap-view-config'] = function()
    dapview.open()
  end
  dap.listeners.before.event_terminated['dap-view-config'] = function()
    dapview.close()
  end
  dap.listeners.before.event_exited['dap-view-config'] = function()
    dapview.close()
  end

  local sign = vim.fn.sign_define
  sign('DapBreakpoint', { text = '●', texthl = 'DapBreakpoint', linehl = '', numhl = '' })
  sign('DapBreakpointCondition', { text = '●', texthl = 'DapBreakpointCondition', linehl = '', numhl = '' })
  sign('DapLogPoint', { text = '◆', texthl = 'DapLogPoint', linehl = '', numhl = '' })
  sign('DapStopped', { text = '→', texthl = 'DapStopped', linehl = '', numhl = '' })
  sign('DapBreakpointRejected', { text = '✗', texthl = 'DapBreakpointRejected', linehl = '', numhl = '' })

  vim.keymap.set('n', '<leader>dC', dap.clear_breakpoints, { desc = '[D]ebug: [C]lear Breakpoint' })
  vim.keymap.set('n', '<leader>dt', dap.terminate, { desc = '[D]ebug: [T]erminate' })
  vim.keymap.set('n', '<leader>dr', dap.restart, { desc = '[D]ebug: [R]estart' })
  vim.keymap.set('n', '<leader>dO', dap.step_over, { desc = '[D]ebug: Step [O]ver' })
  vim.keymap.set('n', '<leader>di', dap.step_into, { desc = '[D]ebug: Step [I]nto' })
  vim.keymap.set('n', '<leader>do', dap.step_out, { desc = '[D]ebug: Step [O]ut' })
  vim.keymap.set('n', '<leader>dk', function()
    widgets.hover(nil, { border = 'solid' })
  end, { desc = '[D]ebug: [K]Hover' })

  -- C configurations.
  dap.adapters.codelldb = {
    type = 'server',
    host = 'localhost',
    port = '${port}',
    executable = {
      command = 'codelldb',
      args = { '--port', '${port}' },
    },
  }

  dap.configurations.rust = {
    {
      name = "Launch file",
      type = "codelldb",
      request = "launch",
      program = function()
        return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
      end,
      cwd = '${workspaceFolder}',
      stopOnEntry = false,
    },
  }

  -- NOTE: needs to install Xdebug following these instructions: https://github.com/xdebug/vscode-php-debug?tab=readme-ov-file#installation
  dap.adapters.php = {
    type = 'executable',
    command = 'node',
    args = { vim.fn.stdpath('data') .. '/mason/packages/php-debug-adapter/extension/out/phpDebug.js' },
  }
  dap.configurations.php = {
    {
      type = 'php',
      request = 'launch',
      name = 'Listen for Xdebug',
      port = 9003,
    },
  }

  -- Close terminal on exit (maybe it close on error too?)
  dap.listeners.after.event_initialized['custom.terminal-autoclose'] = function(session)
    session.on_close['custom.terminal-autoclose'] = function()
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        local bufname = vim.api.nvim_buf_get_name(buf)
        if bufname:find('%[dap%-terminal%]') then
          vim.api.nvim_buf_delete(buf, { force = true })
        end
      end
    end
  end

  return dap
end

vim.keymap.set('n', '<leader>db', function() debug_run().toggle_breakpoint() end, { desc = '[D]ebug: Toggle [B]reakpoint' })
vim.keymap.set('n', '<leader>dB', function() debug_run().set_breakpoint(vim.fn.input('Breakpoint condition: ')) end, { desc = '[D]ebug: [B]reakpoint Condition' })
vim.keymap.set('n', '<leader>dc', function() debug_run().continue() end, { desc = '[D]ebug: [C]ontinue' })

--------------------------------------------------
-- Git
--------------------------------------------------

local function diffModeMap(key, cmd, desc)
  vim.keymap.set({ 'n', 'x' }, key, function()
    return not vim.wo.diff and 'normal! ' .. key
    or (vim.api.nvim_get_mode().mode == 'n' and '?<<<<<<<<CR>V/>>>>>>><CR>' .. cmd or cmd)
  end, { desc = desc, silent = true, expr = true })
end
diffModeMap('gh', ':diffget //2 <CR>', 'Git: get lhs of diff')
diffModeMap('gl', ':diffget //3 <CR>', 'Git: get rhs of diff')

vim.keymap.set('n', '<leader>gg', '<cmd>tab Git<CR>]]', { desc = 'Open fu[G]itive in a new tab', remap = true })
vim.keymap.set('n', '<leader>gd', '<cmd>Gvdiffsplit<CR>', { desc = '[D]iff Current File' })
vim.keymap.set('n', '<leader>gb', '<cmd>Git blame<cr>', { desc = 'fu[G]itive [B]lame' })

local log_cmd = 'tab Git log -50 --graph --decorate --pretty=pf'
vim.keymap.set('n', '<leader>gl', '<cmd>' .. log_cmd .. '<cr>', { desc = 'fu[G]itive [L]og' })
vim.keymap.set(
  'x',
  '<leader>gl',
  ":<C-u>execute 'Git log -L ' . line(\"'<\") . ',' . line(\"'>\") . ':%'<CR>",
  { desc = 'fu[G]itive [L]og' }
)
vim.keymap.set('n', '<leader>gL', '<cmd>' .. log_cmd .. ' %<cr>', { desc = 'fu[G]itive [L]og File' })
vim.keymap.set('n', '<leader>gr', '<cmd>' .. log_cmd .. ' --numstat<cr>', { desc = 'fu[G]itive [R]eview Log' })
vim.keymap.set(
  'n',
  '<leader>gR',
  '<cmd>tab Git log -50 --oneline --patch<cr>',
  { desc = 'fu[G]itive Detailed [R]eview Log' }
)

require('gitsigns').setup({
  signs = {
    add = { text = '│' },
    change = { text = '│' },
    delete = { text = '_' },
    topdelete = { text = '‾' },
    changedelete = { text = '└' },
    untracked = { text = '┆' },
  },
  signs_staged = {
    add = { text = '│' },
    change = { text = '│' },
    delete = { text = '_' },
    topdelete = { text = '‾' },
    changedelete = { text = '└' },
    untracked = { text = '┆' },
  },
  preview_config = { border = 'solid' },
  on_attach = function()
    local gitsigns = require('gitsigns')

    -- Navigation
    vim.keymap.set('n', ']h', function()
      if vim.wo.diff then
        vim.cmd.normal({ ']c', bang = true })
      else
        gitsigns.nav_hunk('next')
      end
    end, { desc = 'Jump to next Hunk' })
    vim.keymap.set('n', '[h', function()
      if vim.wo.diff then
        vim.cmd.normal({ '[c', bang = true })
      else
        gitsigns.nav_hunk('prev')
      end
    end, { desc = 'Jump to previous Hunk' })

    -- Visual mode
    vim.keymap.set('x', '<leader>hs', function()
      gitsigns.stage_hunk({ vim.fn.line('.'), vim.fn.line('v') })
    end, { desc = '[H]unk [S]tage' })
    vim.keymap.set('x', '<leader>hr', function()
      gitsigns.reset_hunk({ vim.fn.line('.'), vim.fn.line('v') })
    end, { desc = '[H]unk [R]eset' })

    -- Text object
    vim.keymap.set({ 'o', 'x' }, 'ih', gitsigns.select_hunk, { desc = '[I]nside [H]unk TextObject' })

    -- Normal mode
    vim.keymap.set('n', '<leader>hs', gitsigns.stage_hunk, { desc = '[H]unk [S]tage' })
    vim.keymap.set('n', '<leader>hr', gitsigns.reset_hunk, { desc = '[H]unk [R]eset' })
    vim.keymap.set('n', '<leader>hp', gitsigns.preview_hunk, { desc = '[H]unk [P]review' })

    -- Buffer
    vim.keymap.set('n', '<leader>bs', gitsigns.stage_buffer, { desc = '[B]uffer [S]tage' })
    vim.keymap.set('n', '<leader>br', gitsigns.reset_buffer, { desc = '[B]uffer [R]eset' })
    vim.keymap.set('n', '<leader>bd', gitsigns.diffthis, { desc = '[B]uffer [D]iff' })
  end,
})

--------------------------------------------------
-- Mason
--------------------------------------------------

local servers = require('core.lsp').servers
local ensure_installed = {}
-- install rust-analyzer with `rustup component add rust-analyzer`
for _, server in ipairs(servers) do
  if server ~= 'rust-analyzer' then
    table.insert(ensure_installed, server)
  end
end

vim.list_extend(ensure_installed, {
  -- web
  'eslint_d',
  'prettier',
  -- markdown
  'markdownlint',
  'markdown-toc',
  -- lua
  'stylua', -- formatter
  -- shell
  'shellcheck', -- linter
  'shfmt', -- formatter
  -- "yamllint", -- linter
  'yamlfmt', -- formatter
  -- json
  'jsonlint', -- linter
  -- text
  'vale', -- linter
  -- sql
  -- "sqlfluff", -- linter
  -- work
  'phpcs',
  'phpstan',
  'php-debug-adapter',
  'php-cs-fixer',
})

vim.api.nvim_create_user_command('MasonInstallNew', function()
  if not ensure_installed or #ensure_installed == 0 then
    return
  end
  local mason_registry = require('mason-registry')
  local installed_packages = mason_registry.get_installed_package_names()
  for _, package in ipairs(ensure_installed) do
    if not vim.tbl_contains(installed_packages, package) then
      vim.cmd('MasonInstall ' .. package)
    end
  end
end, {})

vim.api.nvim_create_user_command('MasonUninstallNotEnsured', function()
  local mason_registry = require('mason-registry')
  local installed_packages = mason_registry.get_installed_package_names()
  for _, package in ipairs(installed_packages) do
    if not vim.tbl_contains(ensure_installed, package) then
      vim.cmd('MasonUninstall ' .. package)
    end
  end
end, {})

vim.api.nvim_create_user_command('Mason', function()
  vim.api.nvim_del_user_command('Mason')
  require('mason').setup({
    ui = {
      icons = {
        package_installed = '✓',
        package_pending = '➜',
        package_uninstalled = '✗',
      },
      height = 0.8,
    },
  })
  vim.cmd('Mason')
end, {})

--------------------------------------------------
-- Text Editing
--------------------------------------------------

require('mini.splitjoin').setup({ mappings = { toggle = '<leader>j', split = '', join = '' } })

local ai = require('mini.ai')
ai.setup({
  n_lines = 500,
  mappings = {
    around_next = '',
    inside_next = '',
    goto_left = '[g',
    goto_right = ']g',
  },
  custom_textobjects = {
    t = { '<([%p%w]-)%f[^<%w][^<>]->.-</%1>', '^<.->().*()</[^/]->$' }, -- tags
    d = { '%f[%d%._][%d%._]+' }, -- digits with _ separator
    s = { -- subword (breaks sentence, but I never use it) https://github.com/echasnovski/mini.nvim/discussions/1434
      {
        -- Matches a single uppercase letter followed by 1+ lowercase letters.
        -- This covers:
        -- - PascalCaseWords (or the latter part of camelCaseWords)
        '%u[%l%d]+%f[^%l%d]', -- An uppercase letter, 1+ lowercase letters, to end of lowercase letters

        -- Matches lowercase letters up until not lowercase letter.
        -- This covers:
        -- - start of camelCaseWords (just the `camel`)
        -- - snake_case_words in lowercase
        -- - regular lowercase words
        '%f[^%s%p][%l%d]+%f[^%l%d]', -- after whitespace/punctuation, 1+ lowercase letters, to end of lowercase letters
        '^[%l%d]+%f[^%l%d]', -- after beginning of line, 1+ lowercase letters, to end of lowercase letters

        -- Matches uppercase or lowercase letters up until not letters.
        -- This covers:
        -- - SNAKE_CASE_WORDS in uppercase
        -- - Snake_Case_Words in titlecase
        -- - regular UPPERCASE words
        -- (it must be both uppercase and lowercase otherwise it will
        -- match just the first letter of PascalCaseWords)
        '%f[^%s%p][%a%d]+%f[^%a%d]', -- after whitespace/punctuation, 1+ letters, to end of letters
        '^[%a%d]+%f[^%a%d]', -- after beginning of line, 1+ letters, to end of letters
      },
      '^().*()$',
    },
    u = ai.gen_spec.function_call(), -- u for "Usage"
    U = ai.gen_spec.function_call({ name_pattern = '[%w_]' }), -- without dot in function name
    g = function() -- whole buffer
      local from = { line = 1, col = 1 }
      local to = {
        line = vim.fn.line('$'),
        col = math.max(vim.fn.getline('$'):len(), 1),
      }
      return { from = from, to = to, vis_mode = 'V' }
    end,
    ['-'] = { {
      '\n()%s*().-()\n()',
      '^()%s*().-()\n()',
    } },
    o = { -- chunk (as in from vim-textobj-chunk) ??
      '\n.-%b{}.-\n',
      '\n().-()%{\n.*\n.*%}().-\n()',
    },
    e = function()
      local diagnostics = vim.diagnostic.get(0)
      diagnostics = vim.tbl_map(function(diagnostic)
        local from_line = diagnostic.lnum + 1
        local from_col = diagnostic.col + 1
        local to_line = diagnostic.end_lnum + 1
        local to_col = diagnostic.end_col + 1
        return {
          from = { line = from_line, col = from_col },
          to = { line = to_line, col = to_col },
        }
      end, diagnostics)
      return diagnostics
    end,
  },
})


local function refactoring_run()
  if package.loaded['refactoring'] then
    return require('refactoring')
  end
  local refactoring = require('refactoring')
  refactoring.setup({ show_success_message = true })
  return refactoring
end
vim.keymap.set({ 'n', 'x' }, '<leader>rr', function() refactoring_run().select_refactor({ prefer_ex_cmd = true }) end)
vim.keymap.set('n', '<leader>rp', function() refactoring_run().debug.printf() end, { desc = '[R]efactoring: Debug [P]rint' })
vim.keymap.set({ 'n', 'x' }, '<leader>rv', function() refactoring_run().debug.print_var() end)
vim.keymap.set('n', '<leader>rc', function() refactoring_run().debug.cleanup() end, { desc = '[R]efactoring: [C]lear Debug' })

vim.api.nvim_create_autocmd('FileType', {
    pattern = { 'svelte', 'html', 'markdown', 'php' },
    callback = function()
      require('nvim-ts-autotag').setup({
        opts = {
          enable_close_on_clash = true,
          filetypes = { 'svelte', 'html', 'markdown', 'php' },
        },
      })
    end,
    once = true,
})

--------------------------------------------------
-- File Explorer
--------------------------------------------------

local function oil_run()
  if package.loaded['oil'] then
    return require('oil')
  end

  local oil = require('oil')
  oil.setup({
    default_file_explorer = true,
    keymaps = {
      ['g?'] = 'actions.show_help',
      ['<CR>'] = 'actions.select',
      ['<C-v>'] = { 'actions.select', opts = { vertical = true }, desc = 'Open the entry in a vertical split' },
      ['<C-s>'] = { 'actions.select', opts = { horizontal = true }, desc = 'Open the entry in a horizontal split' },
      ['<C-t>'] = { 'actions.select', opts = { tab = true }, desc = 'Open the entry in new tab' },
      ['L'] = 'actions.select',
      ['H'] = 'actions.parent',
      ['<C-p>'] = 'actions.preview',
      ['<C-c>'] = 'actions.close',
      ['q'] = 'actions.close',
      ['<C-r>'] = 'actions.refresh',
      ['-'] = 'actions.parent',
      ['_'] = 'actions.open_cwd',
      ['`'] = 'actions.cd',
      ['~'] = { 'actions.cd', opts = { scope = 'tab' }, desc = ':tcd to the current oil directory' },
      ['gs'] = 'actions.change_sort',
      ['gx'] = 'actions.open_external',
      ['g.'] = 'actions.toggle_hidden',
      ['g\\'] = 'actions.toggle_trash',
    },
    use_default_keymaps = false,
    delete_to_trash = true,
    skip_confirm_for_simple_edits = true,
    view_options = {
      show_hidden = true,
      is_always_hidden = function(name, _)
        return name == '..' or name == '.git'
      end,
    },
    lsp_file_methods = {
      -- test if this works, looks like lua and java don't
      timeout_ms = 5000,
      autosave_changes = false,
    },
  })
  return oil
end

vim.keymap.set('n', '-', function() oil_run().open() end, { desc = 'Open parent directory' })
vim.keymap.set('n', '_', function() oil_run().open(vim.uv.cwd()) end, { desc = 'Open cwd' })
vim.api.nvim_create_user_command('Oil', function(args)
  vim.api.nvim_del_user_command('Oil')
  oil_run().open(args.args)
end, { nargs = '*' })

--------------------------------------------------
-- Treesitter
--------------------------------------------------

vim.filetype.add({
  extension = { rasi = 'rasi' },
  pattern = {
    ['.*/hypr/.*%.conf'] = 'hyprlang',
    ['%.env%.[%w_.-]+'] = 'sh',
  },
})

local parsers = {
  -- langs
  'c',
  'cpp',
  'go',
  'gomod',
  'gowork',
  'gosum',
  'lua',
  'rust',
  -- web
  'javascript',
  'typescript',
  'css',
  'html',
  'svelte',
  -- config
  'json',
  'jsonc',
  'toml',
  'yaml',
  'markdown',
  'markdown_inline',
  -- specific config
  'bash',
  'hyprlang',
  'git_config',
  'gitcommit',
  'gitignore',
  'rasi',
  'readline',
  'powershell',
  'query',
  'vim',
  'vimdoc',
  -- misc
  'diff',
  -- 'comment',
  'regex',
  'sql',
  -- work
  'php',
  'php_only',
  'phpdoc',
}

vim.api.nvim_create_autocmd('FileType', {
  pattern = { '*' },
  callback = function(args)
    -- if vim.api.nvim_buf_line_count(args.buf) > 40000 then
    --   return
    -- end
    local lang = vim.treesitter.language.get_lang(args.match)
    if lang and vim.treesitter.language.add(lang) then
      vim.treesitter.start(args.buf)
      vim.api.nvim_buf_call(args.buf, function()
        vim.wo[0][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
        vim.wo[0][0].foldmethod = 'expr'
        vim.cmd.normal('zx')
      end)
      -- vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})

vim.api.nvim_create_user_command('TSInstallAll', function()
  require('nvim-treesitter').install(parsers)
end, {})

vim.api.nvim_create_user_command('TSInstallNew', function()
  local already_installed = require('nvim-treesitter').get_installed()
  local isnt_installed = function(parser)
    return not vim.tbl_contains(already_installed, parser)
  end
  local to_install = vim.tbl_filter(isnt_installed, parsers)
  if #to_install > 0 then
    require('nvim-treesitter').install(to_install)
  end
end, {})

-- more robust option (do I want the if/else behaviour?) : https://vimways.org/2018/transactions-pending/
vim.keymap.set('x', 'iz', ':<C-U>silent! normal! [zV]zkoj<CR>', { desc = 'Fold Text-Object', silent = true })
vim.keymap.set('o', 'iz', '<cmd>normal Viz<CR>', { desc = 'Fold Text-Object', remap = false })
vim.keymap.set('x', 'az', ':<C-U>silent! normal! [zV]z<CR>', { desc = 'Fold Text-Object', silent = true })
vim.keymap.set('o', 'az', '<cmd>normal Vaz<CR>', { desc = 'Fold Text-Object', remap = false })

-- vim.api.nvim_set_hl(0, '@lsp.type.comment', {})

vim.api.nvim_create_autocmd('PackChanged', {
  callback = function(ev)
    if ev.data.kind ~= 'update' then return end

    if ev.data.spec.name == 'nvim-treesitter' then
      require('nvim-treesitter').update()
    end
  end
})
