local api, fn, cmd, ui = vim.api, vim.fn, vim.cmd, vim.ui

local M = {}

--------------------------------------------------
-- Utils
--------------------------------------------------

---Get normalized filename
---@param buf string
---@return string?
local function normalizeCompleteBufName(buf)
  return fn.fnamemodify(buf, ':p:~:.')
end

---Get normalized filename
---@param bufnr? integer
---@return string?
function M.getBufName(bufnr)
  bufnr = bufnr or 0
  local buf = api.nvim_buf_get_name(bufnr)
  return normalizeCompleteBufName(buf)
end

function M.getArgs()
  local args = fn.argv() --[[@as string[] ]]
  for i, arg in ipairs(args) do
    args[i] = normalizeCompleteBufName(arg)
  end
  return args
end

--------------------------------------------------
-- Arglist Management
--------------------------------------------------

---@param argnr number?
function M.move(argnr)
  local argc = fn.argc()
  if argc == 0 then
    return
  end

  cmd('silent! write')
  argnr = (argnr - 1) % argc + 1

  cmd({ cmd = 'argument', count = argnr, bang = true, mods = { silent = true } })
end

function M.select()
  local args = M.getArgs()
  if #args == 0 then
    vim.notify('Arglist empty', vim.log.levels.WARN)
    return
  end

  local current = fn.argidx()
  ui.select(args, {
    prompt = 'Select buffer:',
    format_item = function(item)
      return item == args[current + 1] and ('[' .. item .. ']') or item
    end,
  }, function(_, selected)
    if selected then
      M.move(selected)
    end
  end)
end

function M.cycle_next()
  M.move(fn.argidx() + 1 + vim.v.count1)
end

function M.cycle_prev()
  local bufname = M.getBufName(0)
  local moves = fn.argidx() + 1 - vim.v.count1
  if not vim.list_contains(M.getArgs(), bufname) then
    moves = moves + 1
  end
  M.move(moves)
end

---@param bufnr? integer
function M.insert(bufnr)
  local buf = M.getBufName(bufnr)
  cmd('silent! argedit ' .. buf .. ' | argdedupe')
end

---@param argnr? integer
function M.remove(argnr)
  local arg = argnr and fn.argv(argnr) or '%'
  cmd('silent! argdelete ' .. arg)
  if fn.winnr('$') > 1 then
    api.nvim_win_close(0, false)
  elseif fn.argc() ~= 0 then
    M.move()
  end
end

function M.remove_select()
  if fn.argc() == 0 then
    vim.notify('No args', vim.log.levels.WARN)
    return
  end
  ui.select(M.getArgs(), { prompt = 'Select buffer to delete:' }, function(_, selected)
    if selected then
      M.remove(selected)
    end
  end)
end

function M.only()
  local buf = M.getBufName(0)
  cmd('silent! args ' .. buf)
end

return M
