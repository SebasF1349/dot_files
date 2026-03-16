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

vim.api.nvim_create_user_command('PUpdate', function()
  vim.pack.update()
end, {})

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
      Pmenu = { bg = colors.base, fg = colors.overlay2 },

      NormalFloat = { bg = colors.base, fg = colors.text },
      FloatBorder = { bg = colors.base, fg = colors.text },

      TerminalNormal = { bg = colors.base, fg = colors.text },
    }
  end,
})
vim.cmd.colorscheme('catppuccin-nvim')

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
  php = { 'phpstan' },
  sql = { 'sqlfluff' },
  mysql = { 'sqlfluff' },
}

local phpstanDir = vim.fs.root(0, 'phpstan.neon')
if phpstanDir then
  lint.linters.phpstan.args = {
    'analyse',
    '--error-format=json',
    '--no-progress',
    '-c',
    phpstanDir .. '/phpstan.neon',
    '--memory-limit=256M',
  }
end

lint.linters.shellcheck.args = { '-x' }
lint.linters.sqlfluff.args = {
  'lint',
  '--format=json',
  '--dialect=mariadb',
  '-',
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
    prettier = {
      append_args = { '--print-width', '120', '--tab-width', '4' },
    },
    sqlfluff = {
      args = { 'format', '--dialect=mariadb', '-' },
      require_cwd = false,
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
    sql = { 'sqlfluff' },
    mysql = { 'sqlfluff' },
  },
  notify_on_error = false,
})

vim.o.formatexpr = "v:lua.require'conform'.formatexpr()" -- makes gq use conform
vim.keymap.set({ 'n', 'x' }, '<leader>cf', function()
  require('conform').format({ bufnr = 0, async = true, lsp_format = 'never' })
end, { desc = '[C]ode [F]ormat current file' })
vim.keymap.set('n', 'gqp', 'mfgqap`f', { desc = 'Format Paragraph' })

--------------------------------------------------
-- Debug
--------------------------------------------------

local function debug_run()
  if package.loaded['dap'] then
    return require('dap')
  end

  local dap = require('dap')
  local widgets = require('dap.ui.widgets')
  local dapview = require('dap-view')
  require('nvim-dap-virtual-text').setup({})

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
      name = 'Launch file',
      type = 'codelldb',
      request = 'launch',
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

vim.keymap.set('n', '<leader>db', function()
  debug_run().toggle_breakpoint()
end, { desc = '[D]ebug: Toggle [B]reakpoint' })
vim.keymap.set('n', '<leader>dB', function()
  debug_run().set_breakpoint(vim.fn.input('Breakpoint condition: '))
end, { desc = '[D]ebug: [B]reakpoint Condition' })
vim.keymap.set('n', '<leader>dc', function()
  debug_run().continue()
end, { desc = '[D]ebug: [C]ontinue' })

--------------------------------------------------
-- Git
--------------------------------------------------

local function diffModeMap(key, cmd, desc)
  vim.keymap.set({ 'n', 'x' }, key, function()
    return not vim.wo.diff and 'normal! ' .. key
      or (vim.api.nvim_get_mode().mode == 'n' and '?<<<<<<<<CR>V/>>>>>>><CR>' .. cmd or cmd)
  end, { desc = desc, silent = true, expr = true })
end
diffModeMap('gh', ':diffget //2 <CR>', '[G]it: get lhs of diff')
diffModeMap('gl', ':diffget //3 <CR>', '[G]it: get rhs of diff')

vim.keymap.set('n', '<leader>gg', '<cmd>tab Git<CR>]]', { desc = '[G]it: toggle', remap = true })
vim.keymap.set('n', '<leader>gd', ':Gvdiffsplit ', { desc = '[G]it: [D]iff Current File' })
vim.keymap.set('n', '<leader>gb', '<cmd>Git blame<cr>', { desc = '[G]it: [B]lame' })

local function log_cmd(args)
  args = args or ''
  return ('<cmd>tab Git log -50 --graph --decorate --pretty=pf %s<cr>'):format(args)
end
vim.keymap.set('n', '<leader>gl', log_cmd(), { desc = '[G]it: [L]og' })
vim.keymap.set('x', '<leader>gl', ":<C-u>execute 'Git log -L ' . line(\"'<\") . ',' . line(\"'>\") . ':%'<CR>", { desc = '[G]it: [L]og' })
vim.keymap.set('n', '<leader>gL', log_cmd('%'), { desc = '[G]it: [L]og File' })
vim.keymap.set('n', '<leader>gr', log_cmd('--numstat'), { desc = '[G]it: [R]eview Log' })
vim.keymap.set('n', '<leader>gc', '<cmd>tab Git log -50 --oneline --patch<cr>', { desc = '[G]it: [C]hanges Log' })

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
  on_attach = function(bufnr)
    local gitsigns = require('gitsigns')

    vim.keymap.set({ 'n', 'x' }, ']h', function()
      if vim.wo.diff then
        vim.cmd.normal({ ']c', bang = true })
      else
        gitsigns.nav_hunk('next')
      end
    end, { desc = 'Jump to next Hunk', buffer = bufnr })
    vim.keymap.set({ 'n', 'x' }, '[h', function()
      if vim.wo.diff then
        vim.cmd.normal({ '[c', bang = true })
      else
        gitsigns.nav_hunk('prev')
      end
    end, { desc = 'Jump to previous Hunk', buffer = bufnr })

    vim.keymap.set('x', '<leader>hs', function()
      gitsigns.stage_hunk({ vim.fn.line('.'), vim.fn.line('v') })
    end, { desc = '[H]unk [S]tage', buffer = bufnr })
    vim.keymap.set('x', '<leader>hr', function()
      gitsigns.reset_hunk({ vim.fn.line('.'), vim.fn.line('v') })
    end, { desc = '[H]unk [R]eset', buffer = bufnr })

    vim.keymap.set({ 'o', 'x' }, 'ih', gitsigns.select_hunk, { desc = '[I]nside [H]unk TextObject', buffer = bufnr })

    vim.keymap.set('n', '<leader>hs', gitsigns.stage_hunk, { desc = '[H]unk [S]tage', buffer = bufnr })
    vim.keymap.set('n', '<leader>hr', gitsigns.reset_hunk, { desc = '[H]unk [R]eset', buffer = bufnr })
    vim.keymap.set('n', '<leader>hp', gitsigns.preview_hunk_inline, { desc = '[H]unk [P]review', buffer = bufnr })

    vim.keymap.set('n', '<leader>bs', gitsigns.stage_buffer, { desc = '[B]uffer [S]tage', buffer = bufnr })
    vim.keymap.set('n', '<leader>br', gitsigns.reset_buffer, { desc = '[B]uffer [R]eset', buffer = bufnr })
  end,
})

--------------------------------------------------
-- Mason
--------------------------------------------------

require('mason').setup()

local servers = require('core.lsp').servers
local ensure_installed = {}
-- install rust-analyzer with `rustup component add rust-analyzer`
for server, _ in pairs(servers) do
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
  'sqlfluff', -- linter & formatter
  -- work
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
        '%f[%a]%l+%d*',
        '%f[%w]%d+',
        '%f[%u]%u%f[%A]%d*',
        '%f[%u]%u%l+%d*',
        '%f[%u]%u%u+%d*',
      },
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

local around_subword = function(reg)
  reg = vim.deepcopy(reg)
  local SEP = '[_%-]+'
  local line = vim.fn.getline(reg.from.line)
  local left = line:sub(1, reg.from.col - 1):find(SEP .. '$')
  local _, right = line:find('^' .. SEP, reg.to.col + 1)
  if left then
    reg.from.col = left
  elseif right then
    reg.to.col = right
  end
  return reg
end
vim.keymap.set({ 'x', 'o' }, 'as', function()
  local reg = MiniAi.find_textobject('i', 's')
  if reg then
    ---@diagnostic disable-next-line: inject-field
    MiniAi.config.custom_textobjects._Virt = around_subword(reg)
    MiniAi.select_textobject('i', '_Virt')
  end
end)

local function refactoring_run()
  if package.loaded['refactoring'] then
    return require('refactoring')
  end
  local refactoring = require('refactoring')
  refactoring.setup({
    show_success_message = true,
    print_var_statements = {
      php = {
        "echo '<pre>%s ->' . %s; var_export(%s); echo '<pre>'; exit;",
      },
    },
  })
  return refactoring
end
vim.keymap.set({ 'n', 'x' }, '<leader>rr', function()
  refactoring_run().select_refactor({ prefer_ex_cmd = true })
end)
vim.keymap.set('n', '<leader>rp', function()
  refactoring_run().debug.printf()
end, { desc = '[R]efactoring: Debug [P]rint' })
vim.keymap.set({ 'n', 'x' }, '<leader>rv', function()
  refactoring_run().debug.print_var()
end, { desc = '[R]efactoring: Debug Print [V]ariable' })
vim.keymap.set({ 'n', 'x' }, '<leader>rV', function()
  refactoring_run().debug.print_var({ below = false })
end, { desc = '[R]efactoring: Debug Print [V]ariable Above' })
vim.keymap.set('n', '<leader>rc', function()
  refactoring_run().debug.cleanup()
end, { desc = '[R]efactoring: [C]lear Debug' })

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

vim.keymap.set('n', '-', function()
  oil_run().open()
end, { desc = 'Open parent directory' })
vim.keymap.set('n', '_', function()
  oil_run().open(vim.uv.cwd())
end, { desc = 'Open cwd' })
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

vim.treesitter.language.register('sql', { 'mysql' })

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
    local lang = vim.treesitter.language.get_lang(args.match)
    if lang and vim.treesitter.language.add(lang) then
      vim.treesitter.start(args.buf)
      vim.api.nvim_buf_call(args.buf, function()
        vim.wo[0][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
        vim.wo[0][0].foldmethod = 'expr'
        vim.cmd.normal('zx')
      end)
    end
  end,
})

vim.api.nvim_create_user_command('TSInstallAll', function()
  require('nvim-treesitter').install(parsers)
end, {})

-- more robust option (do I want the if/else behaviour?) : https://vimways.org/2018/transactions-pending/
vim.keymap.set('x', 'iz', ':<C-U>silent! normal! [zV]zkoj<CR>', { desc = 'Fold Text-Object', silent = true })
vim.keymap.set('o', 'iz', '<cmd>normal Viz<CR>', { desc = 'Fold Text-Object', remap = false })
vim.keymap.set('x', 'az', ':<C-U>silent! normal! [zV]z<CR>', { desc = 'Fold Text-Object', silent = true })
vim.keymap.set('o', 'az', '<cmd>normal Vaz<CR>', { desc = 'Fold Text-Object', remap = false })

vim.api.nvim_create_autocmd('PackChanged', {
  callback = function(ev)
    if ev.data.kind == 'install' then
      if ev.data.spec.name == 'nvim-treesitter' then
        require('nvim-treesitter').install(parsers)
      end
    else
      if ev.data.spec.name == 'nvim-treesitter' then
        require('nvim-treesitter').update()
      end
    end
  end,
})

--------------------------------------------------
-- DB
--------------------------------------------------

local secrets_path = vim.fn.expand('~/secrets/nvim.lua')
local db_status, db_secrets = pcall(dofile, secrets_path)

if db_status and db_secrets and db_secrets.databases then
  vim.pack.add({
    { src = 'https://github.com/tpope/vim-dadbod' },
    { src = 'https://github.com/kristijanhusak/vim-dadbod-ui' },
    { src = 'https://github.com/kristijanhusak/vim-dadbod-completion' },
  })

  local data_path = vim.fn.stdpath('data')
  vim.g.db_ui_save_location = data_path .. '/dadbod_ui'
  vim.g.db_ui_execute_on_save = false
  vim.g.db_ui_auto_execute_table_helpers = 1
  vim.g.db_ui_use_nvim_notify = true
  vim.g.db_ui_show_database_icon = true
  vim.g.db_ui_use_nerd_fonts = true
  vim.g.db_ui_disable_mappings_sql = false

  local DBFactory = require('modules.db_types')
  local databases_connections = DBFactory.generate(db_secrets.databases)

  local ssh_connections = {}
  if db_secrets.ssh then
    local SSHFactory = require('modules.ssh_types')
    ssh_connections = SSHFactory.generate(db_secrets.ssh)
  end

  local sql_helpers = {
    {
      name = 'Columns',
      query = [[
SELECT
    COLUMN_NAME AS 'Field',
    COLUMN_TYPE AS 'Type',
    IS_NULLABLE AS 'Null',
    COLUMN_DEFAULT AS 'Default',
    COLUMN_KEY AS 'Key',
    EXTRA AS 'Extra',
    COLLATION_NAME AS 'Collation',
    COLUMN_COMMENT AS 'Comment'
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = '%s'
    AND TABLE_SCHEMA = '%s'
ORDER BY ORDINAL_POSITION;
      ]],
    },
    {
      name = 'Indexes',
      query = [[
SELECT
    TABLE_NAME AS 'Table',
    NON_UNIQUE AS 'Non Unique',
    INDEX_NAME AS 'Index Name',
    SEQ_IN_INDEX AS 'Sequence in Index',
    COLUMN_NAME AS 'Column',
    INDEX_TYPE AS 'Type',
    COLLATION AS 'Order',
    CARDINALITY AS 'Cardinality',
    NULLABLE AS 'Nullable',
    COMMENT AS 'Column Comment',
    INDEX_COMMENT AS 'Index Comment'
FROM INFORMATION_SCHEMA.STATISTICS
WHERE TABLE_NAME = '%s'
    AND TABLE_SCHEMA = '%s';
      ]],
    },
    {
      name = 'Keys',
      query = [[
SELECT
    CONSTRAINT_NAME AS 'Constraint Name',
    COLUMN_NAME AS 'Column',
    ORDINAL_POSITION AS 'Ordinal',
    REFERENCED_TABLE_NAME AS 'Referenced Table',
    REFERENCED_COLUMN_NAME AS 'Referenced Column'
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE TABLE_NAME = '%s'
    AND TABLE_SCHEMA = '%s'
ORDER BY CONSTRAINT_NAME;
      ]],
    },
    {
      name = 'References',
      query = [[
SELECT
    TABLE_SCHEMA AS 'Referencing Database',
    TABLE_NAME AS 'Referencing Table',
    COLUMN_NAME AS 'Referencing Column',
    CONSTRAINT_NAME AS 'Foreign Key Name',
    REFERENCED_COLUMN_NAME AS 'Referenced Column'
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE REFERENCED_TABLE_NAME = '%s'
    AND REFERENCED_TABLE_SCHEMA = '%s'
ORDER BY TABLE_NAME;
      ]],
    },
    {
      name = 'Table Data',
      query = [[
SELECT 
    ENGINE,
    TABLE_ROWS,
    AUTO_INCREMENT,
    ROUND(DATA_LENGTH / 1024 / 1024, 2) AS 'Data_Size_MB',
    ROUND(INDEX_LENGTH / 1024 / 1024, 2) AS 'Index_Size_MB',
    ROUND(DATA_FREE / 1024 / 1024, 2) AS 'Free_Space_MB',
    CREATE_TIME,
    UPDATE_TIME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_NAME = '%s' 
    AND TABLE_SCHEMA = '%s';
      ]],
    },
    {
      name = 'Triggers',
      query = [[
SELECT 
    TRIGGER_NAME, 
    ACTION_TIMING, 
    EVENT_MANIPULATION AS 'EVENT', 
    ACTION_STATEMENT AS 'LOGIC'
FROM INFORMATION_SCHEMA.TRIGGERS
WHERE EVENT_OBJECT_TABLE = '%s' 
    AND TRIGGER_SCHEMA = '%s';
      ]],
    },
  }

  vim.g.db_ui_table_helpers = {
    mysql = {
      List = [[SELECT *
    FROM {optional_schema}`{table}`
    LIMIT 10;]],
      Columns = '',
      ['Primary Keys'] = '',
      Indexes = '',
      ['Foreign Keys'] = '',
    },
  }

  local db_tab

  local function get_db_tab()
    if db_tab and vim.api.nvim_tabpage_is_valid(db_tab) then
      return db_tab
    end
  end

  local function open_db_tab()
    db_tab = get_db_tab()
    local curr_tab = vim.api.nvim_get_current_tabpage()
    if not db_tab then
      vim.cmd('tab DBUI')
    elseif curr_tab ~= db_tab then
      vim.api.nvim_set_current_tabpage(db_tab)
    end
    vim.schedule(function()
      vim.api.nvim_win_set_cursor(0, { 1, 0 })
      vim.fn.feedkeys(vim.api.nvim_replace_termcodes('<Plug>(DBUI_Redraw)', true, false, true), 'm')
    end)
  end

  local function toggle_db_tab()
    db_tab = get_db_tab()
    local curr_tab = vim.api.nvim_get_current_tabpage()
    if curr_tab == db_tab then
      local tab_nr = vim.api.nvim_tabpage_get_number(db_tab)
      vim.cmd('wa | ' .. tab_nr .. 'tabclose')
      db_tab = nil
      return
    else
      open_db_tab()
    end
  end

  local active_tunnels = {}

  local function connect_db(name)
    local db = databases_connections[name]
    if not db then
      vim.notify('DB "' .. name .. '" not found', vim.log.levels.ERROR)
      return
    end

    local dbs = vim.g.dbs or {}
    if dbs[name] then
      open_db_tab()
      return
    end

    if not db.db_host then
      local ssh = ssh_connections[name]
      if not ssh then
        vim.notify('Missing credentials to open tunnel to ' .. name, vim.log.levels.ERROR)
        return
      end
      local pid = ssh:create_tunnel(active_tunnels, name, db.db_port)
      active_tunnels[name] = pid
    end

    dbs[name] = db:get_connection_cmd()

    vim.g.dbs = dbs

    open_db_tab()
  end

  local function disconnect_db(name)
    local dbs = vim.g.dbs or {}
    if not dbs[name] then
      vim.notify('DB "' .. name .. '" is not active', vim.log.levels.WARN)
      return
    end

    dbs[name] = nil
    vim.g.dbs = dbs
    vim.fn.feedkeys(vim.api.nvim_replace_termcodes('<Plug>(DBUI_Redraw)', true, false, true), 'm')

    local pid = active_tunnels[name]
    if not pid then
      return
    end

    vim.system({ 'kill', tostring(pid) }, {}, function(obj)
      if obj.code == 0 then
        vim.schedule(function()
          vim.notify('Successfully killed tunnel ' .. name, vim.log.levels.INFO)
          active_tunnels[name] = nil
        end)
      else
        vim.schedule(function()
          vim.notify('Failed to kill tunnel: ' .. obj.stderr, vim.log.levels.ERROR)
        end)
      end
    end)
  end

  local function db_completion(arg_lead, list)
    local items = {}
    for name, _ in pairs(list) do
      if name:find('^' .. arg_lead) then
        table.insert(items, name)
      end
    end
    return items
  end

  local function all_db_complete(arg_lead)
    return db_completion(arg_lead, databases_connections)
  end

  local function active_db_complete(arg_lead)
    return db_completion(arg_lead, vim.g.dbs)
  end

  vim.api.nvim_create_user_command('ConnectDB', function(opts)
    connect_db(opts.args)
  end, { nargs = 1, complete = all_db_complete })

  vim.api.nvim_create_user_command('DisconnectDB', function(opts)
    disconnect_db(opts.args)
  end, { nargs = 1, complete = active_db_complete })

  vim.keymap.set('n', '<leader>dd', toggle_db_tab, { desc = '[D]B: Toggle' })
  vim.keymap.set('n', '<leader>dn', ':ConnectDB ', { desc = '[D]B: [N]ew Connection' })
  vim.keymap.set('n', '<leader>ds', ':DisconnectDB ', { desc = '[D]B: [S]top Connection' })

  vim.api.nvim_create_autocmd('VimLeavePre', {
    callback = function()
      local pids = vim.tbl_values(active_tunnels)
      if #pids > 0 then
        local cmd = { 'kill', '-9' }
        for _, pid in ipairs(pids) do
          table.insert(cmd, tostring(pid))
        end
        vim.system(cmd):wait()
      end
    end,
  })

  vim.api.nvim_create_autocmd('User', {
    pattern = 'DBUIOpened',
    callback = function()
      vim.schedule(function()
        db_tab = vim.api.nvim_get_current_tabpage()
      end)
    end,
  })

  local function get_statement()
    local curr_line = vim.api.nvim_win_get_cursor(0)
    local non_blank = vim.api.nvim_get_current_line():find('%S') or 0
    local bufnr = vim.api.nvim_win_get_buf(0)
    vim.treesitter.get_parser(bufnr):parse()
    local curr_node = vim.treesitter.get_node({ pos = { curr_line[1] - 1, non_blank } })
    while curr_node do
      if curr_node:type() == 'statement' then
        return vim.treesitter.get_node_range(curr_node)
      end
      curr_node = curr_node:parent()
    end
  end

  vim.api.nvim_create_autocmd('FileType', {
    pattern = { 'mysql', 'sql' },
    callback = function()
      vim.bo[0].omnifunc = 'vim_dadbod_completion#omni'
      vim.bo[0].complete = 'o'
      vim.bo[0].autocomplete = true

      vim.keymap.set('n', '<leader>h', function()
        vim.ui.select(sql_helpers, {
          prompt = 'Query: ',
          format_item = function(item)
            return item.name
          end,
        }, function(choice)
          if not choice then
            return
          end
          local query = choice.query:format(vim.b.dbui_table_name, vim.b.dbui_schema_name)
          local output = vim.split(query, '\n')
          local cursor = vim.api.nvim_win_get_cursor(0)
          vim.api.nvim_buf_set_lines(0, cursor[1] - 1, cursor[1] - 1, false, output)
        end)
      end, { desc = 'DB: [H]elpers', buffer = 0 })

      vim.keymap.set('x', '<CR>', '<Plug>(DBUI_ExecuteQuery)', { desc = 'DB: Execute', buffer = 0 })
      vim.keymap.set('n', '<CR>', 'vaq<Plug>(DBUI_ExecuteQuery)', { desc = 'DB: Execute', buffer = 0, remap = true })
      vim.keymap.set('n', 'W', '<Plug>(DBUI_SaveQuery)', { desc = 'DB: [W]rite', buffer = 0 })
      vim.keymap.set('n', 'E', '<Plug>(DBUI_EditBindParameters)', { desc = 'DB: [E]dit Parameters', buffer = 0 })
      vim.keymap.set('n', 'L', '<Plug>(DBUI_ToggleResultLayout)', { desc = 'DB: Change Result [L]ayout' })

      vim.keymap.set({ 'n', 'x' }, '<C-q>', function()
        return vim.fn['db#op_exec']()
      end, { desc = 'DB: Execute Operator', buffer = 0, expr = true })

      vim.keymap.set('x', 'aq', function()
        local start_row, start_col, end_row, end_col = get_statement()
        if not start_row then
          return
        end
        vim.api.nvim_win_set_cursor(0, { start_row + 1, start_col })
        if vim.api.nvim_get_mode().mode:find('v') then
          vim.cmd.normal({ 'o', bang = true })
        else
          vim.cmd.normal({ 'v', bang = true })
        end
        vim.api.nvim_win_set_cursor(0, { end_row + 1, end_col })
      end, { desc = 'DB: Select SQL Query', buffer = 0 })
      vim.keymap.set('o', 'aq', '<cmd>normal vaq<CR>', { desc = 'DB: SQL Query Text-Object', buffer = 0, remap = true })

      if vim.b.dbui_db_key_name then
        local server = vim.b.dbui_db_key_name:match('([^_]+)')
        local db = databases_connections[server]
        local win = vim.api.nvim_get_current_win()
        local hl = db.type == 'prod' and 'Normal:DiffDelete' or ''
        vim.wo[win][0].winhighlight = hl
      end
    end,
  })

  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'dbui',
    callback = function()
      vim.keymap.set('n', '<CR>', function()
        local line = vim.api.nvim_get_current_line()

        vim.cmd([[execute "normal! \<Plug>(DBUI_SelectLine)"]])

        if vim.startswith(vim.trim(line), '▸  ') then
          vim.cmd([[execute "normal! j\<Plug>(DBUI_SelectLine)"]])
        end
      end, { buffer = true })
    end,
  })
end
