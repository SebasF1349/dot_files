local M = {}

local select_ns = vim.api.nvim_create_namespace('select_ui')

---@generic T
---@param items T[] Arbitrary items
---@param opts vim.ui.select.Opts
---@param on_choice fun(item: T|nil, idx: integer|nil)
function M.select(items, opts, on_choice)
  local shared = require('uim.shared')

  vim.validate('items', items, 'table')
  vim.validate('on_choice', on_choice, 'function')

  opts = opts or {}

  local format_item = opts.format_item or tostring

  if #items == 0 then
    vim.notify('No items to select from', vim.log.levels.INFO)
    on_choice(nil, nil)
    return
  end

  local current_win = vim.api.nvim_get_current_win()
  local title = opts.prompt or 'Select one of:'

  local current_cursor = vim.o.guicursor
  local cursor_hl = 'HiddenCursor'
  local function hide_cursor()
    if vim.tbl_isempty(vim.api.nvim_get_hl(0, { name = cursor_hl })) then
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

  local code_action_chars = { 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z' }
  local default_chars = { 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', "'", 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '[' }
  local possible_chars = opts.kind == 'codeaction' and code_action_chars or default_chars
  local keys_method = opts.kind == 'codeaction' and 'intelligent' or 'list'

  local closing_keys = { 'q', '<C-c>', '<ESC>' }
  local ignore_chars = {}
  for _, key in ipairs(closing_keys) do
    if type(key) == 'string' then
      table.insert(ignore_chars, key)
    elseif type(key) == 'table' then
      table.insert(ignore_chars, key[1])
    end
  end

  local posible_chars = vim
    .iter(possible_chars)
    :filter(function(item)
      return not vim.list_contains(ignore_chars, item)
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
      if char:match('%a') and not key:find(char) then
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
    if keys_method == 'intelligent' then
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
  local number_columns = math.max(math.floor(vim.o.columns / (max_length + whitespace)), 1)
  local number_lines = math.ceil(#choices / number_columns)

  local footer = keys_method == 'intelligent' and ''
    or string.format('(%s, %s)', choices[1].option, choices[#choices].option)
  local height = math.max(math.min(vim.o.lines - vim.fn.screenrow() - 1 - vim.o.cmdheight, number_lines + 1), 1)
  local select_win = shared.create_win(select_bufnr, {
    relative = 'laststatus',
    border = 'none',
    title = title,
    title_pos = 'left',
    footer = footer,
    height = height,
    width = vim.o.columns,
    row = 0,
    col = 0,
  })

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
      text[j] = string.format(
        '%s%s %s: %s ',
        text[j] or '',
        (' '):rep(item_whitespace),
        choices[pos].option,
        choices[pos].item
      )
      if choices[pos].option ~= '-' then
        -- TODO: maybe use vim.fn.getcharstr() instead of keymaps?
        vim.keymap.set('n', choices[pos].option, function()
          select_and_close(pos)
        end, { buffer = select_bufnr })
      end
    end
  end
  text = vim.list_extend({ title .. ' ' .. footer }, text)
  hl = vim.list_extend({ { { #title + 1, #title + 1 + #footer } } }, hl)
  vim.api.nvim_buf_set_lines(select_bufnr, 0, #text, false, text)
  for line, cols in ipairs(hl) do
    for _, col in ipairs(cols) do
      vim.highlight.range(select_bufnr, select_ns, 'Title', { line - 1, col[1] }, { line - 1, col[2] })
    end
  end

  vim.api.nvim_set_option_value('filetype', 'uiselect', { buf = select_bufnr })
  vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = select_bufnr })
  vim.api.nvim_set_option_value('modifiable', false, { buf = select_bufnr })

  shared.close_mappings(select_bufnr, select_and_close, closing_keys)
end

return M
