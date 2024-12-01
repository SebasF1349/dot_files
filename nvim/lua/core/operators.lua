local function opfunc(func_name)
  return function()
    vim.o.operatorfunc = 'v:lua.' .. func_name
    return 'g@'
  end
end

--------------------------------------------------
-- Evaluate
--------------------------------------------------

-- shameless stealing from mini.operators: https://github.com/echasnovski/mini.nvim/blob/main/lua/mini/operators.lua#L323
local function inspect_objects(...)
  local objects = {}
  -- Not using `{...}` because it removes `nil` input
  for i = 1, select('#', ...) do
    local v = select(i, ...)
    table.insert(objects, vim.inspect(v))
  end

  return vim.split(table.concat(objects, '\n'), '\n')
end

local function eval_lua_lines(lines)
  -- Copy to not modify input
  local lines_copy, n = vim.deepcopy(lines), #lines
  lines_copy[n] = (lines_copy[n]:find('^%s*return%s+') == nil and 'return ' or '') .. lines_copy[n]

  local str_to_eval = table.concat(lines_copy, '\n')

  -- Allow returning tuple with any value(s) being `nil`
  return inspect_objects(assert(loadstring(str_to_eval))())
end

function _G.Evaluate(mode)
  local starting = vim.api.nvim_buf_get_mark(0, '[')
  local ending = vim.api.nvim_buf_get_mark(0, ']')
  local lines = {}
  if mode == 'char' then
    lines = vim.api.nvim_buf_get_text(0, starting[1] - 1, starting[2], ending[1] - 1, ending[2] + 1, {})
  elseif mode == 'line' then
    local len_last_line = #vim.fn.getline(ending[1])
    lines = vim.api.nvim_buf_get_text(0, starting[1] - 1, 0, ending[1] - 1, len_last_line, {})
  elseif mode == 'block' then
    for i = starting[1] - 1, ending[1] - 1 do
      table.insert(lines, vim.api.nvim_buf_get_text(0, i, starting[2], i, ending[2] + 1, {})[1])
    end
  end
  local text_to_replace = eval_lua_lines(lines)
  if mode == 'char' then
    vim.api.nvim_buf_set_text(0, starting[1] - 1, starting[2], ending[1] - 1, ending[2] + 1, text_to_replace)
  elseif mode == 'line' then
    vim.api.nvim_buf_set_lines(0, starting[1] - 1, ending[1], true, text_to_replace)
  elseif mode == 'block' then
    for i = starting[1] - 1, ending[1] - 1 do
      vim.api.nvim_buf_set_text(0, i, starting[2], i, ending[2] + 1, text_to_replace)
    end
  end
end

vim.keymap.set({ 'n', 'v' }, 'g=', opfunc('_G.Evaluate'), { desc = 'Evaluate Expression', silent = true, expr = true })

--------------------------------------------------
-- Surround
--------------------------------------------------

-- with inspiration from https://github.com/Wansmer/nvim-config/blob/main/lua/modules/surround.lua

local surround = {
  { '(', ')' },
  { '[', ']' },
  { '{', '}' },
  { "'", "'" },
  { '"', '"' },
  { '`', '`' },
  { '<', '>' },
  { '*', '*' },
  { '_', '_' },
}

local function get_pair()
  local char = vim.fn.getcharstr()
  return vim
    .iter(surround)
    :filter(function(item)
      return item[1] == char or item[2] == char
    end)
    :flatten()
    :totable()
end

-- plaggio di plaggio: https://github.com/Wansmer/nvim-config/blob/fe7a8243656807f13b13e9f129aec107735c2613/lua/utils.lua#L110
local function get_whitespace(line, side)
  side = side or 'both'
  local is_left = side == 'both' and true or side == 'left'
  local is_right = side == 'both' and true or side == 'right'
  local pad_left, pad_right = '', ''

  if is_left then
    local start, end_ = line:find('^%s+')
    if start then
      pad_left = line:sub(start, end_)
      line = line:sub(end_ + 1)
    end
  end

  if is_right then
    local start, end_ = line:find('%s+$')
    if start then
      pad_right = line:sub(start, end_)
      line = line:sub(1, -(#pad_right + 1))
    end
  end

  return pad_left, line, pad_right
end

local function add_surround(pair, start_row, start_col, end_row, end_col)
  local text = vim.api.nvim_buf_get_text(0, start_row, start_col, end_row, end_col, {})
  local left_pad, first_line = get_whitespace(text[1], 'left')
  text[1] = left_pad .. pair[1] .. first_line
  local _, last_line, right_pad = get_whitespace(text[#text], 'right')
  text[#text] = last_line .. pair[2] .. right_pad
  vim.api.nvim_buf_set_text(0, start_row, start_col, end_row, end_col, text)
end

---@param mode "char"|"line"|"block"
function _G.Surround(mode)
  local pair = get_pair()
  if #pair == 0 then
    return
  end
  local starting = vim.api.nvim_buf_get_mark(0, '[')
  local ending = vim.api.nvim_buf_get_mark(0, ']')
  if mode == 'char' then
    add_surround(pair, starting[1] - 1, starting[2], ending[1] - 1, ending[2] + 1)
  elseif mode == 'line' then
    local len_last_line = #vim.fn.getline(ending[1])
    add_surround(pair, starting[1] - 1, 0, ending[1] - 1, len_last_line)
  elseif mode == 'block' then
    for i = starting[1] - 1, ending[1] - 1 do
      add_surround(pair, i, starting[2], i, ending[2] + 1)
    end
  end
end

vim.keymap.set('n', 'ys', opfunc('_G.Surround'), { desc = '[Y]ou [S]urround', silent = true, expr = true })
vim.keymap.set('x', 's', opfunc('_G.Surround'), { desc = '[S]urround', silent = true, expr = true })

vim.keymap.set('n', 'ds', function()
  local pair = get_pair()
  if #pair > 0 then
    return '"sci' .. pair[1] .. '<BS><Del><C-r>s'
  end
end, { desc = '[D]elete [S]urround', expr = true })

vim.keymap.set('n', 'cs', function()
  local pair, replace = get_pair(), get_pair()
  if #pair > 0 and #replace > 0 then
    return '"sci' .. pair[1] .. '<BS><Del>' .. replace[1] .. '<C-r>s' .. replace[2]
  end
end, { desc = '[C]hange [S]urround', expr = true })

--------------------------------------------------
-- Substitute
--------------------------------------------------

-- based on https://www.reddit.com/r/neovim/comments/xrwo05/comment/ja7oyqy/
---@param mode "char"|"line"|"block"
function _G.Substitute(mode)
  local reg = vim.fn.getreg()
  local text = vim.split(reg, '\n')
  if text[text] == '' then
    table.remove(text)
  end
  local starting = vim.api.nvim_buf_get_mark(0, '[')
  local ending = vim.api.nvim_buf_get_mark(0, ']')
  if mode == 'char' then
    vim.api.nvim_buf_set_text(0, starting[1] - 1, starting[2], ending[1] - 1, ending[2] + 1, text)
  elseif mode == 'line' then
    vim.api.nvim_buf_set_lines(0, starting[1] - 1, ending[1], true, text)
  elseif mode == 'block' then
    for i = starting[1] - 1, ending[1] - 1 do
      vim.api.nvim_buf_set_text(0, i, starting[2], i, ending[2] + 1, text)
    end
  end
end

vim.keymap.set({ 'n', 'v' }, 'S', opfunc('_G.Substitute'), { desc = '[S]ubstitute', silent = true, expr = true })

--------------------------------------------------
-- MakeLists
--------------------------------------------------

function _G.MakeList()
  local starting = vim.api.nvim_buf_get_mark(0, '[')
  local ending = vim.api.nvim_buf_get_mark(0, ']')
  local line_start = starting[1]
  local line_end = ending[1]
  vim.cmd(line_start .. ',' .. line_end .. [[s/\v^(\s*)[^a-zA-Z]*(.*)/\1- \2]])
end

vim.keymap.set({ 'n', 'v' }, 'gl', opfunc('_G.MakeList'), { desc = 'Make Markdown [L]ist', silent = true, expr = true })
