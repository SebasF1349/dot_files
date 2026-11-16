local api, fn, fs, cmd = vim.api, vim.fn, vim.fs, vim.cmd

vim.o.sessionoptions = 'curdir,winsize'
local sessions_path = vim.fs.joinpath(fn.stdpath('data'), 'sessions')
fs.mkdir(sessions_path, { parents = true })

local function get_session_path()
  local cwd = vim.uv.cwd()
  local session_name = cwd and vim.fs.slug(cwd) or 'home'
  -- local branch = vim.g.gitsigns_head
  local branch = vim.system({ 'git', 'rev-parse', '--abbrev-ref', 'HEAD' }, { text = true }):wait(500)
  if branch.code == 0 then
    local branch_name = vim.trim(branch.stdout)
    session_name = session_name .. '@@' .. branch_name:gsub('[\\/:]', '_')
  end
  return vim.fs.joinpath(sessions_path, session_name)
end

--- Whether nvim was started with a `+cmd` argument
---@return boolean
local function has_cmd_arg()
  return vim.iter(vim.v.argv):any(
    ---@param v string
    function(v)
      return vim.startswith(v, '+')
    end
  )
end

local function sessionSave()
  cmd('mksession! ' .. fn.fnameescape(get_session_path()))
end

local function sessionLoad()
  cmd('silent! %bwipeout!')
  local session_path = get_session_path()
  if not vim.uv.fs_stat(session_path) then
    session_path = session_path:gsub('@@.*$', '')
  end
  if vim.uv.fs_stat(session_path) then
    cmd('source ' .. fn.fnameescape(session_path))
  end
end

local function sessionRemove()
  fs.rm(get_session_path(), { force = true })
end

api.nvim_create_user_command('SSave', function()
  sessionSave()
  cmd.qa()
end, { desc = 'Save Session And Quit' })
api.nvim_create_user_command('SLoad', sessionLoad, { desc = 'Load Session' })
api.nvim_create_user_command('SRemove', sessionRemove, { desc = 'Remove Session' })

local auSession = api.nvim_create_augroup('Sessions', {})

api.nvim_create_autocmd('VimLeavePre', {
  group = auSession,
  callback = function()
    local has_code_bufs = vim.iter(api.nvim_list_wins()):any(
      ---@param win integer
      function(win)
        local bufnr = api.nvim_win_get_buf(win)
        return vim.bo[bufnr].buftype == ''
      end
    )
    if not vim.uv.fs_stat(get_session_path()) or has_cmd_arg() or not has_code_bufs then
      return
    end
    sessionSave()
  end,
  desc = 'Auto Save Session If Exists',
})

-- using an autocmd on VimEnter to load session opens buffers with empty filetype
if not has_cmd_arg() then
  if vim.uv.fs_stat(get_session_path()) and fn.argc() == 0 then
    sessionLoad()
  elseif fn.argc() == 0 or (fn.argc() == 1 and fn.isdirectory(fn.expand('%')) == 1) then
    local dir = fn.argc() == 1 and fn.expand('%:p') or vim.uv.cwd()
    cmd.edit(dir)
  end
end
