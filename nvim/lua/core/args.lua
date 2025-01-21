--------------------------------------------------
-- Arglist Management
--------------------------------------------------

---@param argnr number?
local function move(argnr)
  vim.cmd.write()
  argnr = argnr or vim.fn.argidx() + 1
  if argnr < 1 or argnr > vim.fn.argc() then
    argnr = math.fmod(argnr, vim.fn.argc())
  end
  if argnr <= 0 then
    argnr = argnr + vim.fn.argc()
  end
  vim.cmd({ cmd = 'argument', count = argnr })
end

local function select()
  if vim.fn.argc() == 0 then
    vim.notify('No args', vim.log.levels.WARN)
  end
  vim.ui.select(vim.fn.argv()--[[@as string[] ]], {
    prompt = 'Select buffer:',
    format_item = function(item)
      return item == vim.fn.argv(vim.fn.argidx()) and '[' .. item .. ']' or item
    end,
  }, function(_, selected)
    if selected then
      move(selected)
    end
  end)
end

local function cycle_next()
  if vim.fn.argc() == 0 then
    return
  end
  move(vim.fn.argidx() + vim.v.count1 + 1)
end

local function cycle_prev()
  if vim.fn.argc() == 0 then
    return
  end
  local bufname = vim.api.nvim_buf_get_name(0)
  bufname = vim.fn.fnamemodify(bufname, ':.')
  local moves = vim.fn.argidx() + 1 - vim.v.count1
  if
    not vim.list_contains(vim.fn.argv()--[[@as string[] ]], bufname)
  then
    moves = moves + 1
  end
  move(moves)
end

---@param bufnr? number
local function insert(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local buf = vim.api.nvim_buf_get_name(bufnr)
  buf = vim.fn.fnamemodify(buf, ':.')
  vim.cmd('argedit ' .. buf .. ' | argdedupe')
end

---@param argnr? number
local function remove(argnr)
  local arg = argnr and vim.fn.argv(argnr) or '%'
  vim.cmd('silent! argdelete ' .. arg)
  if #vim.api.nvim_list_wins() > 1 then
    vim.api.nvim_win_close(0, false)
  elseif vim.fn.argc() ~= 0 then
    move()
  end
end

local function remove_select()
  if vim.fn.argc() == 0 then
    vim.notify('No args', vim.log.levels.WARN)
  end
  vim.ui.select(vim.fn.argv()--[[@as string[] ]], { prompt = 'Select buffer to delete:' }, function(_, selected)
    if selected then
      remove(selected)
    end
  end)
end

---@param exclude? boolean don't delete current
local function remove_all(exclude)
  if exclude then
    local bufnr = vim.api.nvim_get_current_buf()
    local buf = vim.api.nvim_buf_get_name(bufnr)
    buf = vim.fn.fnamemodify(buf, ':.')
    vim.cmd('silent! args ' .. buf)
  else
    vim.cmd('silent! %argdelete')
  end
  if #vim.api.nvim_list_wins() > 1 then
    vim.api.nvim_win_close(0, false)
  elseif vim.fn.argc() ~= 0 then
    move()
  end
end

vim.keymap.set('n', ']a', cycle_next, { desc = 'Next [A]rg' })
vim.keymap.set('n', '[a', cycle_prev, { desc = 'Previous [A]rg' })
vim.keymap.set('n', 'gaa', function()
  local count = vim.v.count
  if count ~= 0 and count <= vim.fn.argc() then
    move(count)
  else
    select()
  end
end, { desc = 'Select [A]rg Buffer' })
vim.keymap.set('n', 'gai', insert, { desc = '[A]rg [I]nsert' })
vim.keymap.set('n', 'gad', ':argdo ', { desc = '[A]rg[D]o' })
vim.keymap.set('n', 'gar', remove, { desc = '[A]rg [R]emove' })
vim.keymap.set('n', 'gaR', remove_select, { desc = '[A]rg [R]emove Selected' })
vim.keymap.set('n', 'gao', function()
  remove_all(true)
end, { desc = '[A]rg [O]nly' })
vim.keymap.set('n', 'gac', remove_all, { desc = '[A]arglist [C]lean' })

--------------------------------------------------
-- Opening Buffers
--------------------------------------------------

local edit_buffer = {
  w = { cmd = ':edit ', desc = '[W]indow' },
  s = { cmd = ':split ', desc = '[S]plit' },
  v = { cmd = ':vsplit ', desc = '[V]ertical split' },
}

for key, opts in pairs(edit_buffer) do
  vim.keymap.set('n', '<leader>' .. key:upper(), function()
    return opts.cmd .. vim.fn.expand('%:p:h') .. '/'
  end, { desc = 'Edit Buffer in Current Directory in ' .. opts.desc, expr = true })
  vim.keymap.set('n', '<leader>a' .. key, function()
    local current_path = vim.fn.expand('%:p')
    local alternative_path
    if vim.o.filetype == 'java' then
      if current_path:find('test') then
        alternative_path = current_path:gsub('/test/', '/main/'):gsub('Test', '')
      else
        alternative_path = current_path:gsub('/main/', '/test/'):gsub('%.java', 'Test.java')
      end
    else
      return
    end
    return opts.cmd .. alternative_path
  end, { desc = 'Edit [A]lternative File in ' .. opts.desc, expr = true })
end

local find_buffer = {
  w = { cmd = ':find ', desc = '[W]indow' },
  s = { cmd = ':sfind ', desc = '[S]plit' },
  v = { cmd = ':vsplit | find ', desc = '[V]ertical split' },
}

for key, opts in pairs(find_buffer) do
  vim.keymap.set('n', '<leader>' .. key, opts.cmd, { desc = 'Edit Buffer in ' .. opts.desc })
end

local args_augroup = vim.api.nvim_create_augroup('Arglist', { clear = true })
vim.api.nvim_create_autocmd({ 'BufEnter' }, {
  group = args_augroup,
  callback = function()
    local bufnr = vim.api.nvim_win_get_buf(0)
    local buf = vim.api.nvim_buf_get_name(bufnr)
    buf = vim.fn.fnamemodify(buf, ':.')
    for i, a in
      ipairs(vim.fn.argv()--[[@as string[] ]])
    do
      if a == buf and i ~= vim.fn.argidx() + 1 then
        move(i)
      end
    end
  end,
  desc = 'Update arglist when changing buffers',
})
