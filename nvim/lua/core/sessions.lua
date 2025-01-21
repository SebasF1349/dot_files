local oss = require('utils.os')

vim.o.sessionoptions = 'curdir,winsize'
local sessions_path = oss.joinpath(vim.fn.stdpath('data'), 'sessions')

local function get_session_path()
  if vim.fn.isdirectory(sessions_path) == 0 then
    os.execute('mkdir ' .. sessions_path)
  end
  local session_name =
    vim.uv.cwd():gsub('%s+', ''):gsub(vim.env.HOME, ''):gsub('.:\\', ''):gsub(oss.dir_separator, '__')
  if #session_name == 0 then
    session_name = 'home'
  end
  return oss.joinpath(sessions_path, session_name)
end

local function sessionSave()
  local session_path = get_session_path()
  vim.cmd('mksession! ' .. session_path)
  vim.cmd.qa()
end

local function sessionLoad()
  vim.cmd('silent! %bwipeout!')
  local session_path = get_session_path()
  vim.cmd('source ' .. session_path)
end

local function sessionRemove()
  local session_path = get_session_path()
  vim.fs.rm(session_path, { force = true })
  vim.fs.rm(session_path .. '.json', { force = true })
end

vim.api.nvim_create_user_command('SSave', sessionSave, { desc = 'Save Session And Quit' })
vim.api.nvim_create_user_command('SLoad', sessionLoad, { desc = 'Load Session' })
vim.api.nvim_create_user_command('SRemove', sessionRemove, { desc = 'Remove Session' })

local auSession = vim.api.nvim_create_augroup('Sessions', {})

vim.api.nvim_create_autocmd('VimLeave', {
  group = auSession,
  callback = function()
    local session_path = get_session_path()
    local has_opt = vim.iter(vim.v.argv):any(function(v)
      return v:find('+')
    end)
    if not vim.uv.fs_stat(session_path) or has_opt then
      return
    end
    sessionSave()
  end,
  desc = 'Auto Save Session If Exists',
})

-- using an autocmd on VimEnter to load session opens buffers with empty filetype
if vim.v.vim_did_enter then
  local session_path = get_session_path()
  local has_opt = vim.iter(vim.v.argv):any(function(v)
    return v:find('+')
  end)
  if has_opt then
  elseif vim.uv.fs_stat(session_path) then
    if vim.fn.argc() == 0 then
      sessionLoad()
    end
  elseif vim.fn.argc() == 0 or (vim.fn.argc() == 1 and vim.fn.isdirectory(vim.fn.expand('%')) == 1) then
    vim.schedule(function()
      local dir = vim.fn.argc() == 1 and vim.fn.expand('%') or vim.uv.cwd()
      vim.cmd.Oil(dir)
    end)
  end
end
