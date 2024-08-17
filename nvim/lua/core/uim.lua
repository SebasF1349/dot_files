vim.ui.open = (function(overridden)
  return function(path)
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
        path = ('https://google.com/search?q=%s'):format(path)
      end
    end
    overridden(path)
  end
end)(vim.ui.open)

local select_ns = vim.api.nvim_create_namespace('select_ui')
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
  local height = math.max(math.min(vim.o.lines - vim.fn.screenrow() - 2, #items), 1)

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
    vim.api.nvim_win_close(select_win, true)
    vim.api.nvim_set_current_win(current_win)
    restore_cursor()
    on_choice(item, i)
  end

  local choices = {}
  local max_length = -1
  local option
  for i, item in ipairs(items) do
    if two_letter_mode then
      local first_letter = math.floor((i - 1) / #select_opts) + 1
      local second_letter = ((i - 1) % #select_opts) + 1
      option = select_opts[first_letter] .. select_opts[second_letter]
    else
      option = select_opts[i]
    end
    table.insert(choices, string.format(' %s: %s ', option or '-', format_item(item)))
    local charnr = vim.fn.strchars(choices[i])
    if charnr > max_length then
      max_length = charnr
    end
    if option then
      vim.keymap.set('n', option, function()
        select_and_close(i)
      end, { buffer = select_bufnr })
    end
  end
  if two_letter_mode then
    vim.api.nvim_win_set_config(select_win, { footer = string.format('(%s, %s)', select_opts[1]:rep(2), option) })
  end
  local whitespace = 3
  local number_columns = math.floor(vim.o.columns / (max_length + whitespace))
  local number_lines = math.ceil(#choices / number_columns)
  number_columns = math.ceil(#choices / number_lines)
  local col_start = {}
  local text = {}
  for i = 1, number_columns do
    table.insert(col_start, (whitespace + max_length) * (i - 1) + whitespace)
    for j = 1, number_lines do
      local pos = j + (i - 1) * number_lines
      if pos > #choices then
        break
      end
      local item_whitespace = col_start[i] - vim.fn.strchars(text[j] or '')
      text[j] = (text[j] or '') .. (' '):rep(item_whitespace) .. choices[pos]
    end
  end
  choices = text
  vim.api.nvim_win_set_height(select_win, #text)
  vim.api.nvim_buf_set_lines(select_bufnr, 0, #choices, false, choices)
  for i, _ in ipairs(choices) do
    for _, pos in ipairs(col_start) do
      vim.highlight.range(select_bufnr, select_ns, 'CursorLineNr', { i - 1, pos }, { i - 1, pos + 3 })
    end
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
