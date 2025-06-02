function _G.opfunc(func_name)
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

vim.keymap.set(
  { 'n', 'v' },
  'g=',
  _G.opfunc('_G.Evaluate'),
  { desc = 'Evaluate Expression', silent = true, expr = true }
)

--------------------------------------------------
-- Surround
--------------------------------------------------

-- TODO: add 'surround with function' with fn.input to input the function name

-- FIX: try to reduce boilerplate
local surround = {
  ['('] = { { '(' }, { ')' } },
  ['b'] = { { '(' }, { ')' } },
  [')'] = { { '(' }, { ')' } },
  ['['] = { { '[' }, { ']' } },
  [']'] = { { '[' }, { ']' } },
  ['{'] = { { '{' }, { '}' } },
  ['}'] = { { '{' }, { '}' } },
  ["'"] = { { "'" }, { "'" } },
  ['"'] = { { '"' }, { '"' } },
  ['`'] = { { '`' }, { '`' } },
  ['<'] = { { '<' }, { '>' } },
  ['>'] = { { '<' }, { '>' } },
  ['*'] = { { '*' }, { '*' } },
  ['_'] = { { '_' }, { '_' } },
}

local function get_pair()
  local char = vim.fn.getcharstr()
  if char == 't' then
    local tag = vim.fn.input('Enter tag: ')
    return { { '<' .. tag .. '>' }, { '</' .. tag .. '>' } }
  end
  if vim.b.surroundPair then
    local _, item = vim.iter(vim.b.surroundPair):find(function(t, _)
      return char == t
    end)
    if item then
      return item
    end
  end
  local _, item = vim.iter(surround):find(function(t, _)
    return char == t
  end)
  return item or { { char }, { char } }
end

-- https://github.com/Wansmer/nvim-config/blob/fe7a8243656807f13b13e9f129aec107735c2613/lua/utils.lua#L110

--- Get whitespace around line (maybe too much for surrounding)
---@param line string
---@param side 'left' | 'right' | 'both'
---@return string, string, string
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

--- Add pair around text
---@param text string[]
---@param pair string[]
---@return string[]
local function add_pair(text, pair)
  local left_pad, first_line = get_whitespace(text[1], 'left')
  local newText = {}
  for i = 1, #pair[1] do
    table.insert(newText, pair[1][i])
  end
  newText[#newText] = left_pad .. newText[#newText] .. first_line
  for i = 2, #text do
    table.insert(newText, text[i])
  end
  newText[#newText] = newText[#newText] .. pair[2][1]
  for i = 2, #pair[2] do
    table.insert(newText, pair[2][i])
  end
  return newText
end

--- Add surround to a block of lines
---@param pair string[]
---@param start_row integer
---@param start_col integer
---@param end_row integer
---@param end_col integer
local function add_surround(pair, start_row, start_col, end_row, end_col)
  local text = vim.api.nvim_buf_get_text(0, start_row, start_col, end_row, end_col, {})
  text = add_pair(text, pair)
  vim.api.nvim_buf_set_text(0, start_row, start_col, end_row, end_col, text)
end

---@param mode "char"|"line"|"block"
function _G.Surround(mode)
  local pair = get_pair()
  if not pair then
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

vim.keymap.set('n', 'ys', _G.opfunc('_G.Surround'), { desc = '[Y]ou [S]urround', silent = true, expr = true })
vim.keymap.set('x', 's', _G.opfunc('_G.Surround'), { desc = '[S]urround', silent = true, expr = true })

vim.keymap.set('n', 'gs', function()
  local char = vim.fn.getcharstr()
  if char then
    return 'ysiw' .. char
  end
end, { desc = 'Easy Word [S]urround', expr = true, remap = true })

-- FIX: doesn't work with multiline pairs
-- only deletes first pairDelete[1] and last pairDelete[2]
--- Remove (or replace) surrounding pairs
---@param pairDelete string[]
---@param pairAdd? string[]
local function operateSurround(pairDelete, pairAdd)
  local curr = vim.api.nvim_win_get_cursor(0)
  local o = vim.fn.search(pairDelete[1][1], 'bW')
  if o == 0 then
    return
  end
  local opening = vim.api.nvim_win_get_cursor(0)
  local e = vim.fn.search(pairDelete[2][#pairDelete[2]], 'eW')
  local ending = vim.api.nvim_win_get_cursor(0)
  if e == 0 or ending[1] < curr[1] or (ending[1] == curr[1] and ending[2] < curr[2]) then
    vim.api.nvim_win_set_cursor(0, curr)
    return
  end

  local lines = vim.api.nvim_buf_get_text(0, opening[1] - 1, opening[2], ending[1] - 1, ending[2] + 1, {})
  vim.print(lines)
  lines[1] = lines[1]:sub(#pairDelete[1][1] + 1, -1)
  if #lines[1] == 0 then
    table.remove(lines, 1)
  end
  lines[#lines] = lines[#lines]:sub(1, -1 * (#pairDelete[2][#pairDelete[2]] + 1))
  if #lines[#lines] == 0 then
    table.remove(lines, #lines)
  end
  if pairAdd then
    lines = add_pair(lines, pairAdd)
  end
  vim.api.nvim_buf_set_text(0, opening[1] - 1, opening[2], ending[1] - 1, ending[2] + 1, lines)
end

vim.keymap.set('n', 'ds', function()
  local pair = get_pair()
  if pair then
    operateSurround(pair)
  end
end, { desc = '[D]elete [S]urround' })

vim.keymap.set('n', 'cs', function()
  local pair, replace = get_pair(), get_pair()
  if pair and replace then
    operateSurround(pair, replace)
  end
end, { desc = '[C]hange [S]urround' })

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

vim.keymap.set({ 'n', 'v' }, 'S', _G.opfunc('_G.Substitute'), { desc = '[S]ubstitute', silent = true, expr = true })
