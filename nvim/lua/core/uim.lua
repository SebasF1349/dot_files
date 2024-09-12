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

---@type 'bottom' | 'right' | 'center' | 'cursor'
local select_position = 'center'
---@type 'cmdline' | 'bottom' | 'right' | 'center' | 'cursor'
local input_position = 'cmdline'
local border = 'none'

---@class WinOpts
---@field bufnr number
---@field height number
---@field width number
---@field border string
---@field row number
---@field col number
---@field title? string
---@field footer? string
---@field relative? string

---@param winOpts WinOpts
---@return integer
local function create_win(winOpts)
  return vim.api.nvim_open_win(winOpts.bufnr, true, {
    relative = winOpts.relative or 'editor',
    width = winOpts.width,
    height = winOpts.height,
    row = winOpts.row,
    col = winOpts.col,
    zindex = 1000,
    style = 'minimal',
    border = winOpts.border,
    title = winOpts.title,
    footer = winOpts.footer,
    noautocmd = true,
  })
end

local autocmd_id
---@param bufnr number
---@param on_close function
local function close_mappings(bufnr, on_close)
  vim.keymap.set('n', 'q', function()
    on_close(nil)
  end, { buffer = bufnr })
  vim.keymap.set({ 'n', 'i' }, '<C-c>', function()
    vim.api.nvim_input('<ESC>')
    on_close(nil)
  end, { buffer = bufnr })

  local augroup = vim.api.nvim_create_augroup('ui', { clear = true })
  autocmd_id = vim.api.nvim_create_autocmd('BufLeave', {
    callback = function()
      on_close(nil)
    end,
    buffer = bufnr,
    once = true,
    group = augroup,
    desc = 'Close select',
  })
end

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
  local title = opts.prompt or 'Select one of:'

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
  hide_cursor()

  ---@class Choice
  ---@field option string
  ---@field item string

  ---@type Choice[]
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
    option = option or '-'
    item = format_item(item)
    table.insert(choices, { option = option, item = item })
    local charnr = vim.fn.strchars(option) + vim.fn.strchars(item) + 5 -- 5 because of the spaces I will add later
    if charnr > max_length then
      max_length = charnr
    end
  end

  local whitespace = 3
  local footer = string.format('(%s, %s)', choices[1].option, choices[#choices].option)
  local win_opts = {
    bufnr = select_bufnr,
    border = border,
    title = title,
    footer = footer,
  }
  local number_columns = 0
  local number_lines = 0

  if select_position == 'bottom' then
    number_columns = math.floor(vim.o.columns / (max_length + whitespace))
    number_lines = math.ceil(#choices / number_columns)
    win_opts.height =
      math.max(math.min(vim.o.lines - vim.fn.screenrow() - 2, border == 'none' and number_lines + 1 or number_lines), 1)
    win_opts.width = vim.o.columns
    win_opts.row = vim.o.lines
      - win_opts.height
      - vim.o.cmdheight
      - (vim.o.laststatus ~= 0 and 1 or 0)
      - (win_opts.border ~= 'none' and 2 or 0)
    win_opts.col = 0
  elseif select_position == 'right' then
    number_columns = 1
    number_lines = #choices
    win_opts.height = border == 'none' and #choices + 1 or #choices
    win_opts.width = max_length + whitespace
    win_opts.row = vim.o.lines
      - win_opts.height
      - vim.o.cmdheight
      - (vim.o.laststatus ~= 0 and 1 or 0)
      - (win_opts.border ~= 'none' and 2 or 0)
    win_opts.col = vim.o.columns - win_opts.width
  elseif select_position == 'center' then
    number_columns = math.floor((vim.o.columns / 2) / (max_length + whitespace))
    number_lines = math.ceil(#choices / number_columns)
    win_opts.height = math.min(border == 'none' and #choices + 1 or #choices, vim.o.columns / 2)
    win_opts.width = max_length * number_columns + whitespace
    win_opts.row = vim.o.lines / 4
    win_opts.col = (vim.o.columns - win_opts.width) / 2
  elseif select_position == 'cursor' then
    number_columns = math.floor((vim.o.columns / 2) / (max_length + whitespace))
    number_lines = math.ceil(#choices / number_columns)
    win_opts.relative = 'cursor'
    win_opts.height = math.min(border == 'none' and #choices + 1 or #choices, vim.o.columns / 2)
    win_opts.width = max_length * number_columns + whitespace
    win_opts.row = 1
    win_opts.col = 0
  end

  local select_win = create_win(win_opts)

  local function select_and_close(i)
    vim.api.nvim_del_autocmd(autocmd_id)
    local item = i and items[i] or nil
    if select_win and vim.api.nvim_win_is_valid(select_win) then
      vim.api.nvim_win_close(select_win, true)
    end
    vim.api.nvim_set_current_win(current_win)
    restore_cursor()
    on_choice(item, i)
  end

  local hl = {}
  local text = {}
  for i = 1, number_columns do
    local col_start = (whitespace + max_length) * (i - 1) + whitespace
    for j = 1, number_lines do
      if not hl[j] then
        table.insert(hl, {})
      end
      local pos = j + (i - 1) * number_lines
      if pos > #choices then
        break
      end
      local item_whitespace = col_start - vim.fn.strchars(text[j] or '')
      local col = #(text[j] or '') + item_whitespace + 1
      table.insert(hl[j], { col, col + 1 + #choices[pos].option })
      text[j] =
        string.format('%s%s %s: %s ', text[j] or '', (' '):rep(item_whitespace), choices[pos].option, choices[pos].item)
      if choices[pos].option ~= '-' then
        vim.keymap.set('n', choices[pos].option, function()
          select_and_close(i)
        end, { buffer = select_bufnr })
      end
    end
  end
  if border == 'none' then
    text = vim.list_extend({ title .. ' ' .. footer }, text)
    hl = vim.list_extend({ { { #title + 1, #title + 1 + #footer } } }, hl)
  end
  vim.api.nvim_buf_set_lines(select_bufnr, 0, #text, false, text)
  for line, cols in ipairs(hl) do
    for _, col in ipairs(cols) do
      vim.highlight.range(select_bufnr, select_ns, 'DiagnosticInfo', { line - 1, col[1] }, { line - 1, col[2] })
    end
  end

  vim.api.nvim_set_option_value('filetype', 'uiselect', { buf = select_bufnr })
  vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = select_bufnr })
  vim.api.nvim_set_option_value('modifiable', false, { buf = select_bufnr })

  close_mappings(select_bufnr, select_and_close)
end

---@diagnostic disable-next-line: duplicate-set-field
vim.ui.input = function(opts, on_confirm)
  vim.validate({
    opts = { opts, 'table', true },
    on_confirm = { on_confirm, 'function', false },
  })

  opts = (opts and not vim.tbl_isempty(opts)) and opts or vim.empty_dict()

  local current_win = vim.api.nvim_get_current_win()

  local column = 0
  local row = vim.o.lines - 1 - vim.o.cmdheight - (vim.o.laststatus ~= 0 and 1 or 0)
  local title_win

  local input_bufnr = vim.api.nvim_create_buf(false, true)
  ---@type WinOpts
  local win_opts = {
    bufnr = input_bufnr,
    height = 1,
    width = vim.o.columns - column,
    border = border,
    title = opts.prompt,
    row = row,
    col = column,
  }
  if input_position == 'cmdline' then
    local title_bufnr = vim.api.nvim_create_buf(false, true)
    title_win = create_win({
      bufnr = title_bufnr,
      height = 1,
      width = #opts.prompt,
      border = 'none',
      row = vim.o.lines,
      col = 0,
    })
    vim.api.nvim_buf_set_lines(title_bufnr, 0, 1, false, { opts.prompt .. ' ' })
    vim.api.nvim_set_option_value('filetype', 'uiinputtitle', { buf = title_bufnr })
    vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = title_bufnr })
    vim.api.nvim_set_option_value('winhighlight', 'NormalFloat:Normal', { win = title_win })
    vim.api.nvim_set_option_value('winblend', 0, { win = title_win })
    win_opts.col = #opts.prompt
    win_opts.row = vim.o.lines
    win_opts.height = 1
    win_opts.width = vim.o.columns - win_opts.col
    win_opts.border = 'none'
  end

  local input_win = create_win(win_opts)

  vim.api.nvim_buf_set_lines(input_bufnr, 0, #opts.default, false, { opts.default })
  vim.api.nvim_win_set_cursor(input_win, { 1, #opts.default + 1 })
  vim.api.nvim_set_option_value('filetype', 'uiinput', { buf = input_bufnr })
  vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = input_bufnr })
  if border == 'none' then
    vim.api.nvim_set_option_value('winhighlight', 'NormalFloat:Normal', { win = input_win })
    vim.api.nvim_set_option_value('winblend', 0, { win = input_win })
  end

  local function select_and_close(input)
    vim.api.nvim_del_autocmd(autocmd_id)
    vim.api.nvim_win_close(input_win, true)
    if title_win and vim.api.nvim_win_is_valid(title_win) then
      vim.api.nvim_win_close(title_win, true)
    end
    vim.api.nvim_set_current_win(current_win)
    on_confirm(input)
  end

  vim.keymap.set({ 'n', 'i', 'x' }, '<CR>', function()
    vim.api.nvim_input('<ESC>')
    local line = vim.api.nvim_buf_get_lines(input_bufnr, 0, 1, false)[1]
    select_and_close(line)
  end, { buffer = input_bufnr })

  close_mappings(input_bufnr, select_and_close)
end
