local M = {}

local select_ns = vim.api.nvim_create_namespace('select_ui')

function M.select(items, opts, on_choice)
  local config = require('uim.config')
  local shared = require('uim.shared')

  vim.validate({
    items = { items, 'table', false },
    on_choice = { on_choice, 'function', false },
  })
  opts = opts or {}
  local format_item = opts.format_item or tostring

  if #items == 0 then
    vim.notify('No items to select from', vim.log.levels.INFO)
    on_choice(nil, nil)
    return
  end

  local curr_conf = vim.deepcopy(config.opts.select) or {}
  if config.opts.kind and config.opts.kind[opts.kind] then
    curr_conf = vim.tbl_deep_extend('force', {}, curr_conf, config.opts.kind[opts.kind])
  end

  if #items == 1 and curr_conf.autoselect then
    on_choice(nil, nil)
    return
  end

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
  local selected = {}

  if curr_conf.closing_keys then
    for _, key in ipairs(curr_conf.closing_keys) do
      if type(key) == 'string' then
        table.insert(curr_conf.ignore_chars, key)
      elseif type(key) == 'table' then
        table.insert(curr_conf.ignore_chars, key[1])
      end
    end
  end

  local posible_chars = vim
    .iter(curr_conf.possible_chars)
    :filter(function(item)
      return not vim.list_contains(curr_conf.ignore_chars, item)
    end)
    :totable()

  ---@param n number
  local function get_number_chars(n)
    if #items <= math.pow(#posible_chars, n) then
      return n
    end
    return get_number_chars(n + 1)
  end
  local number_chars = get_number_chars(1)
  ---@param o string[]
  ---@return string[]
  local function get_options(o)
    local perm = {}
    for _, p in ipairs(o) do
      for _, c in ipairs(posible_chars) do
        table.insert(perm, p .. c)
      end
    end
    if #perm[1] == number_chars then
      return perm
    end
    return get_options(perm)
  end
  local options = get_options({ '' })
  ---@param item string
  ---@param key string
  local function choose_key(item, key)
    if #key == number_chars then
      if vim.list_contains(options, key) and not vim.list_contains(selected, key) then
        return key
      end
      return
    end
    for char in item:lower():gmatch('.') do
      if not key:find(char) then
        local returned = choose_key(item, key .. char)
        if returned then
          return returned
        end
      end
    end
  end

  for i, item in ipairs(items) do
    item = format_item(item)
    -- TODO: find best way to handle new lines, now I'm just keeping the first one
    local new_line = item:find('\n')
    if new_line then
      item = item:sub(1, new_line - 1)
    end
    local option
    if curr_conf.keys_method == 'intelligent' then
      option = choose_key(item, '')
      table.insert(selected, option)
      if not option then
        for j = #options, 1, -1 do
          if not vim.list_contains(selected, options[j]) then
            option = options[j]
            table.insert(selected, options[j])
            break
          end
        end
      end
    else
      option = options[i]
    end
    option = option or '-'
    table.insert(choices, { option = option, item = item })
    local charnr = vim.fn.strchars(option) + vim.fn.strchars(item) + 5 -- 5 because of the spaces I will add later
    if charnr > max_length then
      max_length = charnr
    end
  end

  local whitespace = 3
  local footer = curr_conf.keys_method == 'intelligent' and ''
    or string.format('(%s, %s)', choices[1].option, choices[#choices].option)
  ---@type WinOpts
  local win_opts = {
    bufnr = select_bufnr,
    border = curr_conf.border,
    title = title,
    title_pos = curr_conf.title_pos,
    footer = curr_conf.footer_labels and footer or nil,
    height = -1,
    width = -1,
    row = -1,
    col = -1,
  }
  local number_columns = 0
  local number_lines = 0

  if curr_conf.position == 'bottom' then
    number_columns = math.max(math.floor(vim.o.columns / (max_length + whitespace)), 1)
    number_lines = math.ceil(#choices / number_columns)
    win_opts.height = math.max(
      math.min(
        vim.o.lines - vim.fn.screenrow() - 1 - vim.o.cmdheight,
        curr_conf.border == 'none' and number_lines + 1 or number_lines
      ),
      1
    )
    win_opts.width = vim.o.columns
    win_opts.row = vim.o.lines
      - win_opts.height
      - vim.o.cmdheight
      - (vim.o.laststatus ~= 0 and 1 or 0)
      - (win_opts.border ~= 'none' and 2 or 0)
    win_opts.col = 0
  elseif curr_conf.position == 'right' then
    number_columns = 1
    number_lines = #choices
    win_opts.height = curr_conf.border == 'none' and #choices + 1 or #choices
    win_opts.width = max_length + whitespace
    win_opts.row = vim.o.lines
      - win_opts.height
      - vim.o.cmdheight
      - (vim.o.laststatus ~= 0 and 1 or 0)
      - (win_opts.border ~= 'none' and 2 or 0)
    win_opts.col = vim.o.columns - win_opts.width
  elseif curr_conf.position == 'center' then
    number_columns = math.max(math.floor((vim.o.columns / 2) / (max_length + whitespace)), 1)
    number_lines = math.ceil(#choices / number_columns)
    win_opts.height = math.min(curr_conf.border == 'none' and number_lines + 1 or number_lines, vim.o.columns / 2)
    win_opts.width = max_length * number_columns + whitespace
    win_opts.row = vim.o.lines / 4
    win_opts.col = (vim.o.columns - win_opts.width) / 2
  elseif curr_conf.position == 'cursor' then
    number_columns = math.max(math.floor((vim.o.columns / 2) / (max_length + whitespace)), 1)
    number_lines = math.ceil(#choices / number_columns)
    win_opts.relative = 'cursor'
    win_opts.height = math.min(curr_conf.border == 'none' and number_lines + 1 or number_lines, vim.o.columns / 2)
    win_opts.width = max_length * number_columns + whitespace
    win_opts.row = 1
    win_opts.col = 0
  end

  local select_win = shared.create_win(win_opts)

  local function select_and_close(i)
    vim.api.nvim_del_autocmd(shared.autocmd_id)
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
          select_and_close(pos)
        end, { buffer = select_bufnr })
      end
    end
  end
  if curr_conf.border == 'none' then
    text = vim.list_extend({ title .. ' ' .. footer }, text)
    hl = vim.list_extend({ { { #title + 1, #title + 1 + #footer } } }, hl)
  end
  vim.api.nvim_buf_set_lines(select_bufnr, 0, #text, false, text)
  for line, cols in ipairs(hl) do
    for _, col in ipairs(cols) do
      vim.highlight.range(select_bufnr, select_ns, 'UimSelectLabels', { line - 1, col[1] }, { line - 1, col[2] })
    end
  end

  vim.api.nvim_set_option_value('filetype', 'uiselect', { buf = select_bufnr })
  vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = select_bufnr })
  vim.api.nvim_set_option_value('modifiable', false, { buf = select_bufnr })

  shared.close_mappings(select_bufnr, select_and_close, curr_conf.closing_keys)
end

return M
