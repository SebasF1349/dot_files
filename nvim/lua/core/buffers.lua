local M = {}

--------------------------------------------------
-- Pin Buffers
--------------------------------------------------

---@type number[]
local pinbufs = {}

---@type number
local active_pinbuf = 0

function M.get_pinbufs()
  return pinbufs
end

function M.get_active_pinbuf()
  return active_pinbuf
end

---@param bufnr number
---@return number | nil
local function bufpin_pos(bufnr)
  for i, pinbuf in ipairs(pinbufs) do
    if pinbuf == bufnr then
      return i
    end
  end
end

---@param bufnr? number
local function add_pinbuf(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not bufpin_pos(bufnr) then
    table.insert(pinbufs, bufnr)
    active_pinbuf = #pinbufs
  end
end

---@param pos number
local function remove_pinbuf(pos)
  table.remove(pinbufs, pos)
  if active_pinbuf == pos then
    if #pinbufs == 0 then
      active_pinbuf = 0
    elseif active_pinbuf > #pinbufs then
      active_pinbuf = 1
    else
      active_pinbuf = active_pinbuf + 1
    end
  end
end

local function remove_curr_pinbuf()
  local bufnr = vim.api.nvim_get_current_buf()
  local pos = bufpin_pos(bufnr)
  if not pos then
    return
  end
  remove_pinbuf(pos)
  if #vim.api.nvim_list_wins() > 1 then
    vim.schedule(function()
      vim.api.nvim_win_close(0, false)
    end)
  elseif active_pinbuf ~= 0 then
    vim.schedule(function()
      vim.api.nvim_set_current_buf(pinbufs[active_pinbuf])
    end)
  else
    -- TODO: return to alternate file or old file?
    -- check gh chrisgrieser/.config /lua/funcs/alt-alt
  end
end

---@param pos? number
local function move_to_bufpin(pos)
  pos = pos or active_pinbuf
  vim.api.nvim_set_current_buf(pinbufs[pos])
  active_pinbuf = pos
end

--------------------------------------------------
-- Buffer Management
--------------------------------------------------

vim.opt.jumpoptions = 'stack'

local function select_bufpin()
  if #pinbufs == 0 then
    vim.notify('No pinned bufs', vim.log.levels.WARN)
  end
  local bufpins = vim.iter(pinbufs):map(function(item)
    return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(item), ':.')
  end)
  vim.ui.select(bufpins:totable(), { prompt = 'Select buffer:' }, function(_, selected)
    if selected then
      move_to_bufpin(selected)
    end
  end)
end

local function select_remove_pinbuf()
  if #pinbufs == 0 then
    vim.notify('No pinned bufs', vim.log.levels.WARN)
  end
  local bufpins = {}
  for _, pinbuf in ipairs(pinbufs) do
    table.insert(bufpins, vim.fn.fnamemodify(vim.api.nvim_buf_get_name(pinbuf), ':.'))
  end
  vim.ui.select(bufpins, { prompt = 'Select buffer:' }, function(_, selected)
    if selected then
      remove_pinbuf(selected)
    end
  end)
end

local function remove_other_bufpin()
  if #pinbufs == 0 then
    vim.notify('No pinned bufs', vim.log.levels.WARN)
  end
  local current_bufnr = vim.api.nvim_win_get_buf(0)
  for i = #pinbufs, 1, -1 do
    if current_bufnr ~= pinbufs[i] then
      remove_pinbuf(i)
    end
  end
  local curr_win = vim.api.nvim_get_current_win()
  for _, winid in ipairs(vim.api.nvim_list_wins()) do
    if winid ~= curr_win then
      vim.api.nvim_win_close(winid, true)
    end
  end
end

---@param direction -1|1
local function cycle_bufpin(direction)
  if active_pinbuf == 0 or #pinbufs == 0 then
    return
  end
  local next_pos
  if direction == -1 and vim.api.nvim_get_current_buf() ~= pinbufs[active_pinbuf] then
    next_pos = active_pinbuf
  else
    next_pos = active_pinbuf + direction
    if next_pos < 1 then
      next_pos = #pinbufs
    elseif next_pos > #pinbufs then
      next_pos = 1
    end
  end
  move_to_bufpin(next_pos)
end

---@param direction -1|1
local function move_through_buf_history(direction)
  local current_bufnr = vim.api.nvim_win_get_buf(0)
  local jumplist = vim.fn.getjumplist()
  if not #jumplist[1] then
    return
  end
  local jumplistPos = direction == -1 and jumplist[2] or jumplist[2] + 1
  while true do
    if direction == -1 and jumplistPos == 0 then
      vim.notify('First jump position', vim.log.levels.WARN)
      return
    elseif direction == 1 and jumplistPos > #jumplist[1] then
      vim.notify('Last jump position', vim.log.levels.WARN)
      return
    end
    local new_buf = jumplist[1][jumplistPos].bufnr
    if new_buf ~= current_bufnr and vim.api.nvim_get_option_value('buftype', { buf = new_buf }) == '' then
      local jumps_count = (jumplistPos - jumplist[2] - 1) * direction
      local dir = direction == 1 and '<C-i>' or '<C-o>'
      vim.api.nvim_input(jumps_count .. dir)
      return
    end
    jumplistPos = jumplistPos + direction
  end
end

vim.keymap.set('n', 'gbb', function()
  local count = vim.v.count
  if count ~= 0 and count <= #pinbufs then
    move_to_bufpin(count)
  else
    select_bufpin()
  end
end, { desc = 'Change Pinned [B]uffer' })
vim.keymap.set('n', ']p', function()
  cycle_bufpin(1)
end, { desc = 'Next [P]in Buffer' })
vim.keymap.set('n', '[p', function()
  cycle_bufpin(-1)
end, { desc = 'Previous [P]in Buffer' })
vim.keymap.set('n', ']b', function()
  move_through_buf_history(1)
end, { desc = 'Next [B]uffer in History' })
vim.keymap.set('n', '[b', function()
  move_through_buf_history(-1)
end, { desc = 'Previous [B]uffer in History' })
vim.keymap.set('n', 'gbp', move_to_bufpin, { desc = 'Move to [P]inned Buffer' })
vim.keymap.set('n', 'gba', add_pinbuf, { desc = '[A]dd Pin Buffer' })
vim.keymap.set('n', 'gbd', remove_curr_pinbuf, { desc = '[D]elete Pin Buffer', expr = true })
vim.keymap.set('n', 'gbc', select_remove_pinbuf, { desc = '[C]lean Pin Buffer' })
vim.keymap.set('n', 'gbo', remove_other_bufpin, { desc = 'Make [O]nly Pin Buffer' })

--------------------------------------------------
-- Opening Buffers
--------------------------------------------------

vim.api.nvim_create_user_command('PinBuf', function()
  add_pinbuf()
end, {})

local edit_buffer = {
  w = { cmd = ':edit ', desc = '[W]indow' },
  s = { cmd = ':split ', desc = '[S]plit' },
  v = { cmd = ':vsplit ', desc = '[V]ertical split' },
}

for key, opts in pairs(edit_buffer) do
  vim.keymap.set('n', 'gE' .. key, function()
    return opts.cmd .. vim.fn.expand('%:p:h') .. '/' .. ' | PinBuf' .. ('<left>'):rep(9)
  end, { desc = '[E]dit Buffer in Current Directory in ' .. opts.desc, expr = true })
  vim.keymap.set('n', 'ga' .. key, function()
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
    return opts.cmd .. alternative_path .. ' | PinBuf<CR>'
  end, { desc = 'Edit [A]lternative File in ' .. opts.desc, expr = true })
end

local find_buffer = {
  w = { cmd = ':find ', desc = '[W]indow' },
  s = { cmd = ':sfind ', desc = '[S]plit' },
  v = { cmd = ':vsplit | find ', desc = '[V]ertical split' },
}

for key, opts in pairs(find_buffer) do
  vim.keymap.set('n', 'ge' .. key, function()
    return opts.cmd .. ' | PinBuf' .. ('<left>'):rep(9)
  end, { desc = '[E]dit Buffer in ' .. opts.desc, expr = true })
  vim.keymap.set('n', 'gs' .. key, function()
    return opts.cmd
  end, { desc = 'Open [S]cratch Buffer in ' .. opts.desc, expr = true })
end

local pinbufs_augroup = vim.api.nvim_create_augroup('Pinbufs', { clear = true })
vim.api.nvim_create_autocmd({ 'BufEnter' }, {
  group = pinbufs_augroup,
  callback = function()
    local bufnr = vim.api.nvim_win_get_buf(0)
    local pos = bufpin_pos(bufnr)
    if pos then
      move_to_bufpin(pos)
    end
  end,
  desc = 'Update pinbufs when changing buffers',
})

vim.api.nvim_create_autocmd({ 'VimEnter' }, {
  group = pinbufs_augroup,
  callback = function()
    if vim.fn.argc() == 0 then
      return
    end
    local args = vim.fn.argv()
    if type(args) == 'string' then
      args = { args }
    end
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
      local fname = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ':p:.')
      if vim.list_contains(args, fname) then
        add_pinbuf(bufnr)
      end
    end
  end,
  once = true,
  desc = 'Pin arglist buffers',
})

return M
