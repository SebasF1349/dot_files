local api, fn, fs, cmd = vim.api, vim.fn, vim.fs, vim.cmd
local oss = require('utils.os')

vim.o.sessionoptions = 'curdir,winsize'
local sessions_path = oss.joinpath(fn.stdpath('data'), 'sessions')

local function get_session_path()
  if fn.isdirectory(sessions_path) == 0 then
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
  cmd('mksession! ' .. session_path)
  cmd.qa()
end

local function sessionLoad()
  cmd('silent! %bwipeout!')
  local session_path = get_session_path()
  cmd('source ' .. session_path)
end

local function sessionRemove()
  local session_path = get_session_path()
  fs.rm(session_path, { force = true })
  fs.rm(session_path .. '.json', { force = true })
end

api.nvim_create_user_command('SSave', sessionSave, { desc = 'Save Session And Quit' })
api.nvim_create_user_command('SLoad', sessionLoad, { desc = 'Load Session' })
api.nvim_create_user_command('SRemove', sessionRemove, { desc = 'Remove Session' })

local auSession = api.nvim_create_augroup('Sessions', {})

api.nvim_create_autocmd('VimLeavePre', {
  group = auSession,
  callback = function()
    local session_path = get_session_path()
    local has_opt = vim.iter(vim.v.argv):any(function(v)
      return v:find('+')
    end)
    local has_code_bufs = vim.iter(api.nvim_list_wins()):any(function(win)
      local bufnr = api.nvim_win_get_buf(win)
      return vim.bo[bufnr].buftype == ''
    end)
    if not vim.uv.fs_stat(session_path) or has_opt or not has_code_bufs then
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
  elseif vim.uv.fs_stat(session_path) and fn.argc() == 0 then
    sessionLoad()
  elseif fn.argc() == 0 or (fn.argc() == 1 and fn.isdirectory(fn.expand('%')) == 1) then
    local dir = fn.argc() == 1 and fn.expand('%:p') or vim.uv.cwd()
    cmd.Oil(dir)
  end
end
