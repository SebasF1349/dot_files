local nvim_version = require('utils.nvim-version')

-- Set highlight on search
vim.o.hlsearch = false

-- Make line numbers default
vim.opt.number = true
vim.opt.relativenumber = true

-- Don't show the mode, since it's already in status line
vim.opt.showmode = false

-- Don't show number of lines of characters selected
vim.opt.showcmd = false

-- Disable mouse mode
vim.o.mouse = ''
vim.keymap.set('', '<up>', '<nop>', { noremap = true })
vim.keymap.set('', '<down>', '<nop>', { noremap = true })
vim.keymap.set('i', '<up>', '<nop>', { noremap = true })
vim.keymap.set('i', '<down>', '<nop>', { noremap = true })

-- Enable break indent
vim.o.breakindent = true

-- Save undo history
vim.o.undofile = true

-- Don't store backup while overwriting the file
vim.o.backup = false
vim.o.writebackup = false

-- Case-insensitive searching UNLESS \C or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true

-- Don't show `~` outside of buffer
vim.o.fillchars = 'eob: '

-- Reduce command line messages
vim.opt.shortmess = 'aoOstTWICF'

-- Set completeopt to have a better completion experience
if nvim_version.is_nightly() then
  vim.o.completeopt = 'menu,menuone,fuzzy,popup'
else
  vim.o.completeopt = 'menu,menuone,popup'
end

-- Slight transparency - I like this ones but don't play with catppuccin
-- vim.o.pumblend = 10 -- builtin completion
-- vim.o.winblend = 10 -- floating windows
vim.o.pumheight = 10 -- popup

-- Decreate update time
vim.opt.updatetime = 250
-- Decrease mapped sequence wait time - Displays which-key popup sooner
vim.opt.timeoutlen = 300

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.opt.smartindent = true

vim.opt.wrap = false
vim.opt.linebreak = true
vim.opt.textwidth = 0

vim.opt.incsearch = true
-- Preview substitutions live, as you type!
vim.opt.inccommand = 'split'

vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 20
vim.opt.signcolumn = 'yes'

-- split windows
vim.opt.splitright = true
vim.opt.splitbelow = true

vim.opt.fileencoding = 'utf-8'

vim.opt.iskeyword:append('-')

-- cmdline autocomplete
vim.opt.wildchar = 12 -- <C-l>
vim.opt.wildoptions = 'pum,tagfile,fuzzy'
vim.opt.wildmode = 'longest:full,full'
-- vim.opt.wildignore:append({ '*/.git/*' }) -- git
-- vim.opt.wildignore:append({ '*/node_modules/*' }) -- web
-- vim.opt.wildignore:append({ '*/target/*' }) -- java


vim.opt.smoothscroll = true

-- folds
vim.opt.foldmethod = 'expr'
vim.opt.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
vim.opt.foldtext = ''
vim.opt.foldlevelstart = 99

-- add borders to floating windows
local _border = 'rounded'
vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(vim.lsp.handlers.hover, {
  border = _border,
})
vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(vim.lsp.handlers.signature_help, {
  border = _border,
})

-- Nicer and less noicy signcolumn
vim.wo.signcolumn = 'yes'
vim.opt.statuscolumn = '%s%=%{%v:relnum ? v:relnum : v:lnum %} '

-- Change color to current line number
vim.opt.cursorline = true
vim.opt.cursorlineopt = 'number'

-- Diagnostics
vim.diagnostic.config({
  underline = false,
  float = {
    border = _border,
    scope = 'cursor',
    severity_sort = true,
    source = true,
  },
  jump = { float = true },
  severity_sort = true,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = '',
      [vim.diagnostic.severity.WARN] = '',
      [vim.diagnostic.severity.INFO] = '',
      [vim.diagnostic.severity.HINT] = '',
    },
    numhl = {
      [vim.diagnostic.severity.ERROR] = 'ErrorMsg',
      [vim.diagnostic.severity.WARN] = 'WarningMsg',
      [vim.diagnostic.severity.INFO] = 'InfoMsg',
      [vim.diagnostic.severity.HINT] = 'HintMsg',
    },
  },
})

-- LSP progress messages on cmdline
vim.lsp.handlers['$/progress'] = function(_, progress, ctx)
  local msg = progress.value

  if msg.kind ~= 'end' and msg.kind ~= 'begin' then
    return
  end

  local out = ''

  local client = vim.lsp.get_client_by_id(ctx.client_id)
  if client and client.name then
    out = out .. '[' .. client.name .. ']'
  end

  local title = msg.title or ''
  if title ~= '' then
    out = out .. ' ' .. title
  end

  if msg.kind == 'end' then
    out = out .. ' done'
  elseif msg.kind == 'begin' then
    out = out .. ' starting...'
  end

  vim.notify(out, vim.log.levels.INFO)
end

---@diagnostic disable-next-line: duplicate-set-field
vim.ui.open = function(path)
  vim.validate({
    path = { path, 'string' },
  })
  local is_uri = path:match('%w+:')
  local is_half_url = path:match('%.com$') or path:match('%.com%.')
  local is_repo = vim.bo.filetype == 'lua' and path:match('%w/%w') and vim.fn.count(path, '/') == 1
  local is_dir = path:match('/%w')
  if not is_uri then
    if is_half_url then
      path = ('https://%s'):format(path)
    elseif is_repo then
      path = ('https://github.com/%s'):format(path)
    elseif not is_dir then
      path = ('https://google.com/search?q=%s'):format(vim.uri_encode(path))
    else
      path = vim.fs.normalize(path)
    end
  end

  local cmd --- @type string[]

  if vim.fn.has('mac') == 1 then
    cmd = { 'open', path }
  elseif vim.fn.has('win32') == 1 then
    if vim.fn.executable('rundll32') == 1 then
      cmd = { 'rundll32', 'url.dll,FileProtocolHandler', path }
    else
      return nil, 'vim.ui.open: rundll32 not found'
    end
  elseif vim.fn.executable('wslview') == 1 then
    cmd = { 'wslview', path }
  elseif vim.fn.executable('explorer.exe') == 1 then
    cmd = { 'explorer.exe', path }
  elseif vim.fn.executable('xdg-open') == 1 then
    cmd = { 'xdg-open', path }
  else
    return nil, 'vim.ui.open: no handler found (tried: wslview, explorer.exe, xdg-open)'
  end

  return vim.system(cmd, { text = true, detach = true }), nil
end

local ca_namespace = vim.api.nvim_create_namespace('code_actions')
-- stylua: ignore
local select_opts = { 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', "'",
                      'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '[' }
---@diagnostic disable-next-line: duplicate-set-field
vim.ui.select = function(items, opts, on_choice)
  vim.validate({
    items = { items, 'table', false },
    on_choice = { on_choice, 'function', false },
  })
  opts = opts or {}
  local format_item = opts.format_item or tostring

  local two_letter_mode = #items > #select_opts

  local current_win = vim.api.nvim_get_current_win()
  local height = math.min(vim.o.lines - vim.fn.screenrow() - 2, #items)

  local current_cursor = vim.o.guicursor
  local cursor_hl = 'HiddenCursor'
  local function hide_cursor()
    if vim.fn.hlexists(cursor_hl) == 0 then
      vim.cmd(string.format('highlight %s gui=reverse blend=100', cursor_hl))
    end
    vim.o.guicursor = string.format('a:%s/lCursor', cursor_hl)
  end
  local function restore_cursor()
    vim.o.guicursor = current_cursor
  end

  local select_bufnr = vim.api.nvim_create_buf(false, true)
  local select_win = vim.api.nvim_open_win(select_bufnr, true, {
    relative = 'editor',
    width = vim.o.columns,
    height = height,
    row = vim.o.lines,
    col = 0,
    zindex = 1000,
    style = 'minimal',
    border = 'single',
    title = opts.prompt or 'Select one of:',
    footer = string.format('(%s, %s)', select_opts[1], select_opts[#items] or '-'),
    noautocmd = true,
  })
  hide_cursor()

  local function select_and_close(i)
    local item = i and items[i] or nil
    on_choice(item, i)
    vim.api.nvim_win_close(select_win, true)
    vim.api.nvim_set_current_win(current_win)
    restore_cursor()
  end

  local choices = {}
  local max_length = -1
  for i, item in ipairs(items) do
    local option
    if two_letter_mode then
      local first_letter = math.floor((i - 1) / #select_opts) + 1
      local second_letter = ((i - 1) % #select_opts) + 1
      option = select_opts[first_letter] .. select_opts[second_letter]
    else
      option = select_opts[i]
    end
    table.insert(choices, string.format(' %s: %s ', option or '-', format_item(item)))
    if #choices[i] > max_length then
      max_length = #choices[i]
    end
    if option then
      vim.keymap.set('n', option, function()
        select_and_close(i)
      end, { buffer = select_bufnr })
    end
  end
  local number_columns = math.floor(vim.o.columns / (max_length + 1))
  local number_lines = math.ceil(#choices / number_columns)
  number_columns = math.ceil(#choices / number_lines)
  if number_columns > 1 then
    local whitespace = math.floor((vim.o.columns - (max_length + 1) * number_columns) / (number_columns + 1))
    local text = {}
    for i = 1, number_columns do
      for j = 1, number_lines do
        local pos = j + (i - 1) * number_lines
        if pos > #choices then
          break
        end
        local item_whitespace = (whitespace + max_length) * (i - 1) - #(text[j] or '') + whitespace
        text[j] = (text[j] or '') .. (' '):rep(item_whitespace) .. choices[pos]
      end
    end
    choices = text
    vim.api.nvim_win_set_height(select_win, #text)
  end
  vim.api.nvim_buf_set_lines(select_bufnr, 0, #choices, false, choices)
  for i, _ in ipairs(items) do
    vim.highlight.range(select_bufnr, ca_namespace, 'CursorLineNr', { i, 0 }, { i, 2 })
  end

  vim.api.nvim_set_option_value('filetype', 'uiselect', { buf = select_bufnr })
  vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = select_bufnr })
  vim.api.nvim_set_option_value('modifiable', false, { buf = select_bufnr })

  vim.keymap.set('n', 'q', function()
    select_and_close(nil)
  end, { buffer = select_bufnr })
  vim.keymap.set({ 'n', 'i' }, '<C-c>', function()
    select_and_close(nil)
  end, { buffer = select_bufnr })

  local select_augroup = vim.api.nvim_create_augroup('ui.select', { clear = true })
  vim.api.nvim_create_autocmd('BufLeave', {
    callback = function()
      select_and_close(nil)
    end,
    buffer = select_bufnr,
    once = true,
    group = select_augroup,
    desc = 'Close select',
  })
end

---@diagnostic disable-next-line: duplicate-set-field
vim.ui.input = function(opts, on_confirm)
  vim.validate({
    opts = { opts, 'table', true },
    on_confirm = { on_confirm, 'function', false },
  })

  opts = (opts and not vim.tbl_isempty(opts)) and opts or vim.empty_dict()

  local current_win = vim.api.nvim_get_current_win()

  local input_bufnr = vim.api.nvim_create_buf(false, true)
  local input_win = vim.api.nvim_open_win(input_bufnr, true, {
    relative = 'editor',
    width = vim.o.columns,
    height = 1,
    row = vim.o.lines,
    col = 0,
    zindex = 1000,
    style = 'minimal',
    border = 'single',
    noautocmd = true,
    title = opts.prompt,
  })
  vim.api.nvim_buf_set_lines(input_bufnr, 0, #opts.default, false, { opts.default })
  vim.api.nvim_win_set_cursor(input_win, { 1, #opts.default + 1 })
  vim.api.nvim_set_option_value('filetype', 'uiinput', { buf = input_bufnr })
  vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = input_bufnr })

  local function select_and_close(input)
    on_confirm(input)
    vim.api.nvim_win_close(input_win, true)
    vim.api.nvim_set_current_win(current_win)
  end

  vim.keymap.set({ 'n', 'i', 'x' }, '<CR>', function()
    vim.api.nvim_input('<ESC>')
    local line = vim.api.nvim_buf_get_lines(input_bufnr, 0, 1, false)[1]
    select_and_close(line)
  end, { buffer = input_bufnr })
  vim.keymap.set('n', 'q', function()
    select_and_close(nil)
  end, { buffer = input_bufnr })
  vim.keymap.set({ 'n', 'i' }, '<C-c>', function()
    vim.api.nvim_input('<ESC>')
    select_and_close(nil)
  end, { buffer = input_bufnr })

  local input_augroup = vim.api.nvim_create_augroup('ui.input', { clear = true })
  vim.api.nvim_create_autocmd('BufLeave', {
    callback = function()
      select_and_close(nil)
    end,
    buffer = input_bufnr,
    once = true,
    group = input_augroup,
    desc = 'Close input',
  })
end

-- Disable health checks for these providers.
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_node_provider = 0
