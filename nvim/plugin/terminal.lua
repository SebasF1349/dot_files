local api, fn, map, cmd = vim.api, vim.fn, vim.keymap.set, vim.cmd

--------------------------------------------------
-- Globals
--------------------------------------------------

---@class term
---@field bufnr integer
---@field winid integer

---@type term[]
local terms = {}

local RUNNERS = {
  build = { jdtls = 'mvn spring-boot:run' },
  test = { jdtls = 'mvn test' },
}

local terminal_autocmds = api.nvim_create_augroup('Terminal Autocmds', { clear = true })

--------------------------------------------------
-- Options
--------------------------------------------------

vim.o.shell = fn.has('win32') == 1 and 'pwsh' or '/bin/bash'

--------------------------------------------------
-- Keymaps
--------------------------------------------------

map('t', '<ESC><ESC>', '<C-\\><C-n>', { desc = 'Escape Terminal Mode' })

map({ 'n', 't' }, '<leader>tb', function()
  local w1, w2 = terms[1].winid, terms[2].winid
  local target_win = api.nvim_win_is_valid(w1) and w1 or (api.nvim_win_is_valid(w2) and w2 or nil)

  if target_win then
    api.nvim_set_current_win(target_win)
  else
    vim.notify('No active terminal windows', vim.log.levels.WARN)
  end
end, { desc = 'Move to [T]erminal [B]uffer ' })

--------------------------------------------------
-- Togglers
--------------------------------------------------

---@param opts term
local function set_term_opts(opts)
  cmd.startinsert()
  vim.bo[opts.bufnr].filetype = 'terminal'
  vim.bo[opts.bufnr].buflisted = false
  vim.bo[opts.bufnr].scrollback = 1000000
  vim.wo[opts.winid][0].statuscolumn = ''
  vim.wo[opts.winid][0].winfixheight = true
  vim.wo[opts.winid][0].winfixwidth = true
  vim.wo[opts.winid][0].winfixbuf = true
  map('n', 'q', '<cmd>bd!<cr>', { buf = opts.bufnr })
  map('n', 'gf', '<cmd>aboveleft vertical wincmd F<cr>', { buf = opts.bufnr, desc = 'Open file under the cursor' })
  api.nvim_set_option_value('winhighlight', 'Normal:TerminalNormal', { win = opts.winid, scope = 'local' })
end

---@param bufnr integer
---@return term
local function create_term(bufnr)
  local buf = api.nvim_buf_is_valid(bufnr) and bufnr or api.nvim_create_buf(false, true)
  local win = api.nvim_open_win(buf, true, { split = 'right', win = 0, width = 50 })
  local term = { bufnr = buf, winid = win }
  if vim.bo[buf].buftype ~= 'terminal' then
    cmd.terminal()
    set_term_opts(term)
  end
  return term
end

---@param num 1|2
local function toggle_term(num)
  local bufnr, winid = terms[num].bufnr, terms[num].winid
  if not api.nvim_win_is_valid(winid) then
    terms[num] = create_term(bufnr)
  else
    api.nvim_win_hide(winid)
  end
end

local TERMINALS_COUNT = 2

for pos = 1, TERMINALS_COUNT do
  terms[pos] = { bufnr = -1, winid = -1 }
  map({ 'n', 't' }, '<leader>t' .. pos, function()
    toggle_term(pos)
  end, { desc = 'Toggle [T]erminal [' .. pos .. ']' })
end
map({ 'n', 't' }, '<leader>tt', function()
  toggle_term(1)
end, { desc = '[T]oggle [T]erminal 1' })

--------------------------------------------------
-- Runners
--------------------------------------------------

--- Move to end of file
---@param bufnr integer
---@param winid integer
local function scroll_to_end(bufnr, winid)
  api.nvim_buf_call(bufnr, function()
    local target_line = api.nvim_buf_line_count(bufnr)
    api.nvim_win_set_cursor(winid, { target_line, 0 })
  end)
end

---@param command string
local function run_term_command(command)
  cmd('wa')
  if not api.nvim_win_is_valid(terms[1].winid) then
    terms[1] = create_term(terms[1].bufnr)
  end
  scroll_to_end(terms[1].bufnr, terms[1].winid)
  local terminal_job_id = vim.b[terms[1].bufnr].terminal_job_id
  api.nvim_chan_send(terminal_job_id, '\x03\n')
  api.nvim_chan_send(terminal_job_id, command .. '\n')
end

-- NOTE: improve keymaps checking this plugin code: https://github.com/samharju/yeet.nvim/blob/master/lua/yeet/buffer.lua
local function execute_runner(type)
  for _, client in ipairs(vim.lsp.get_clients()) do
    local cmd_str = RUNNERS[type][client.name]
    if cmd_str then
      run_term_command(cmd_str)
      return
    end
  end
  vim.notify('No ' .. type .. ' command for attached lsps', vim.log.levels.INFO)
end

map('n', '<leader>cb', function()
  execute_runner('build')
end, { desc = '[C]ode [B]uild' })
map('n', '<leader>ct', function()
  execute_runner('test')
end, { desc = '[C]ode [T]est' })

--------------------------------------------------
-- Autocmds
--------------------------------------------------

api.nvim_create_autocmd('WinEnter', {
  callback = function()
    if vim.bo.filetype == 'terminal' and fn.winnr('$') == 1 then
      cmd('quit')
    end
  end,
  group = terminal_autocmds,
  desc = 'Close Neovim if the last window is a terminal window',
})

api.nvim_create_autocmd('ExitPre', {
  callback = function()
    for _, buf in ipairs(api.nvim_list_bufs()) do
      if vim.bo[buf].buftype == 'terminal' then
        api.nvim_buf_delete(buf, { force = true })
      end
    end
  end,
  group = terminal_autocmds,
  desc = 'Force closing terminal if is open',
})
