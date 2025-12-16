local api, normalize, fn, cmd, map, ui = vim.api, vim.fs.normalize, vim.fn, vim.cmd, vim.keymap.set, vim.ui

--------------------------------------------------
-- Utils
--------------------------------------------------

--- Get normalized filename
---@param bufnr? integer
---@return string
local function getBufName(bufnr)
  bufnr = bufnr or 0
  local buf = api.nvim_buf_get_name(bufnr)
  return normalize(fn.fnamemodify(buf, ':.'))
end

local function getArgs()
  local args = fn.argv() --[[@as string[] ]]
  for i, arg in ipairs(args) do
    args[i] = normalize(fn.fnamemodify(arg, ':.'))
  end
  return args
end

--------------------------------------------------
-- Arglist Management
--------------------------------------------------

---@param argnr number?
local function move(argnr)
  cmd('silent! write')
  argnr = argnr or fn.argidx() + 1
  if argnr < 1 or argnr > fn.argc() then
    argnr = math.fmod(argnr, fn.argc())
  end
  if argnr <= 0 then
    argnr = argnr + fn.argc()
  end
  cmd({ cmd = 'argument', count = argnr, bang = true, mods = { silent = true } })
end

local function select()
  if fn.argc() == 0 then
    vim.notify('No args', vim.log.levels.WARN)
  end
  ui.select(getArgs(), {
    prompt = 'Select buffer:',
    format_item = function(item)
      return item == fn.argv(fn.argidx()) and '[' .. item .. ']' or item
    end,
  }, function(_, selected)
    if selected then
      move(selected)
    end
  end)
end

local function cycle_next()
  if fn.argc() == 0 then
    return
  end
  move(fn.argidx() + vim.v.count1 + 1)
end

local function cycle_prev()
  if fn.argc() == 0 then
    return
  end
  local bufname = getBufName(0)
  local moves = fn.argidx() + 1 - vim.v.count1
  if not vim.list_contains(getArgs(), bufname) then
    moves = moves + 1
  end
  move(moves)
end

---@param bufnr? integer
local function insert(bufnr)
  local buf = getBufName(bufnr)
  cmd('silent! argedit ' .. buf .. ' | argdedupe')
end

---@param argnr? integer
local function remove(argnr)
  local arg = argnr and fn.argv(argnr) or '%'
  cmd('silent! argdelete ' .. arg)
  if fn.winnr('$') > 1 then
    api.nvim_win_close(0, false)
  elseif fn.argc() ~= 0 then
    move()
  end
end

local function remove_select()
  if fn.argc() == 0 then
    vim.notify('No args', vim.log.levels.WARN)
  end
  ui.select(getArgs(), { prompt = 'Select buffer to delete:' }, function(_, selected)
    if selected then
      remove(selected)
    end
  end)
end

local function only()
  local buf = getBufName(0)
  cmd('silent! args ' .. buf)
end

map('n', ']a', cycle_next, { desc = 'Next [A]rg' })
map('n', '[a', cycle_prev, { desc = 'Previous [A]rg' })
map('n', 'gaa', function()
  local count = vim.v.count
  if count ~= 0 and count <= fn.argc() then
    move(count)
  else
    select()
  end
end, { desc = 'Select [A]rg Buffer' })
map('n', 'gai', insert, { desc = '[A]rg [I]nsert' })
map('n', 'gad', ':argdo ', { desc = '[A]rg[D]o' })
map('n', 'gar', remove, { desc = '[A]rg [R]emove' })
map('n', 'gaR', remove_select, { desc = '[A]rg [R]emove Selected' })
map('n', 'gao', only, { desc = '[A]rg [O]nly' })
map('n', 'gac', '<cmd>%argdelete<CR>', { desc = '[A]arglist [C]lean', silent = true })

--------------------------------------------------
-- Update Arglist
--------------------------------------------------

local args_augroup = api.nvim_create_augroup('Arglist', { clear = true })
api.nvim_create_autocmd({ 'BufEnter' }, {
  group = args_augroup,
  callback = function()
    local buf = getBufName(0)
    for i, a in ipairs(getArgs()) do
      if a == buf and i ~= fn.argidx() + 1 then
        move(i)
      end
    end
  end,
  desc = 'Update arglist when changing buffers',
})
