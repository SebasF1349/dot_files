local pinbufs = require('core.buffers')
local oss = require('utils.os')

vim.o.sessionoptions = 'buffers,curdir,help,tabpages,winsize,terminal'
local sessions_path = oss.joinpath(vim.fn.stdpath('data'), 'sessions')

local function get_session_path()
  if vim.fn.isdirectory(sessions_path) == 0 then
    os.execute('mkdir -p ' .. sessions_path)
  end
  local session_name =
    vim.uv.cwd():gsub('%s+', ''):gsub(vim.env.HOME, ''):gsub('.:\\', ''):gsub(oss.dir_separator, '__')
  return oss.joinpath(sessions_path, session_name)
end

local function sessionSave()
  local session_path = get_session_path()
  vim.cmd('mksession! ' .. session_path)
  vim.cmd.wa()
  local pinbufs_files = pinbufs.get_pinbufs_files()
  vim.fn.writefile(pinbufs_files, session_path .. '.json')
  vim.cmd.qa()
end

local function sessionLoad()
  vim.cmd('silent! %bwipeout!')
  local session_path = get_session_path()
  local pinbufs_files = vim.fn.readfile(session_path .. '.json')
  vim.print(pinbufs_files)
  vim.cmd('source ' .. session_path)
  pinbufs.set_pinbufs_files(pinbufs_files)
end

vim.api.nvim_create_user_command('SSave', sessionSave, { desc = 'Save Session And Quit' })
vim.api.nvim_create_user_command('SLoad', sessionLoad, { desc = 'Load Session' })

vim.keymap.set('n', '<leader>ss', sessionSave, { desc = '[S]ession [S]ave' })
vim.keymap.set('n', '<leader>sl', sessionLoad, { desc = '[S]ession [L]oad' })

local auSession = vim.api.nvim_create_augroup('Sessions', {})

vim.api.nvim_create_autocmd('VimLeave', {
  group = auSession,
  callback = function()
    local session_path = get_session_path()
    if not vim.uv.fs_stat(session_path) then
      return
    end
    sessionSave()
  end,
  desc = 'Auto Save Session If Exists',
})

-- using an autocmd on VimEnter to load session opens buffers with empty filetype
if vim.v.vim_did_enter then
  local session_path = get_session_path()
  if vim.uv.fs_stat(session_path) then
    if vim.fn.argc() == 0 then
      sessionLoad()
    end
  elseif vim.fn.argc() == 0 or (vim.fn.argc() == 1 and vim.fn.isdirectory(vim.fn.expand('%')) == 1) then
    vim.schedule(function()
      local dir = vim.fn.argc() == 1 and vim.fn.expand('%') or vim.uv.cwd()
      vim.cmd.Oil(dir)
    end)
  else
    local args = vim.fn.argv()
    if type(args) == 'string' then
      args = { args }
    end
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
      local fname = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ':p:.')
      if vim.list_contains(args, fname) then
        pinbufs.add_pinbuf(bufnr)
      end
    end
  end
end
