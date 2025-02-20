--------------------------------------------------
-- Globals
--------------------------------------------------

---@class term
---@field bufnr number
---@field winid number

---@type term[]
local terms = {}

local terminal_autocmds = vim.api.nvim_create_augroup('Terminal Autocmds', { clear = true })

--------------------------------------------------
-- Options
--------------------------------------------------

if require('utils.os').is_win then
  vim.o.shell = 'pwsh'
  vim.o.shellcmdflag =
    '-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command [Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.Encoding]::UTF8;'
  -- vim.o.shellcmdflag =
  --   "-NoLogo -NonInteractive -ExecutionPolicy RemoteSigned -Command [Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.UTF8Encoding]::new();$PSDefaultParameterValues[''Out-File:Encoding'']=''utf8'';$PSStyle.OutputRendering=''plaintext'';Remove-Alias -Force -ErrorAction SilentlyContinue tee;"
  vim.o.shellredir = '2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode'
  vim.o.shellpipe = '2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode'
  vim.o.shellquote = ''
  vim.o.shellxquote = ''
else
  vim.o.shell = '/bin/bash'
end

--------------------------------------------------
-- Keymaps
--------------------------------------------------

vim.keymap.set('t', 'jk', '<C-\\><C-n>', { desc = 'Escape Terminal Mode' })

vim.keymap.set({ 'n', 't' }, '<leader>tb', function()
  local win = vim.api.nvim_win_is_valid(terms[1].winid) and terms[1].winid or terms[2].winid
  if vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_set_current_win(win)
  end
end, { desc = 'Move to [T]erminal [B]uffer ' })

vim.keymap.set('t', 'gf', function()
  local file = vim.fn.expand('<cfile>')
  if file ~= '' then
    vim.cmd('wincmd p')
    vim.cmd('sfind ' .. file)
  end
end, { desc = 'Open file under the cursor' })

--------------------------------------------------
-- Togglers
--------------------------------------------------

---@param opts term
local function set_term_opts(opts)
  vim.cmd.startinsert()
  vim.bo.filetype = 'terminal'
  vim.bo.buflisted = false
  vim.wo.statuscolumn = ''
  vim.wo.winfixheight = true
  vim.wo.winfixwidth = true
  vim.keymap.set('n', 'q', '<cmd>close<cr>', { buffer = opts.bufnr, silent = true })
  vim.api.nvim_set_option_value('winhighlight', 'Normal:TerminalNormal', { win = opts.winid, scope = 'local' })
end

---@param bufnr number
---@return term
local function create_term(bufnr)
  local buf = vim.api.nvim_buf_is_valid(bufnr) and bufnr or vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, { split = 'right', win = 0, width = 50 })
  local term = { bufnr = buf, winid = win }
  if vim.bo[buf].buftype ~= 'terminal' then
    vim.cmd.terminal()
    set_term_opts(term)
  end
  return term
end

---@param num 1|2
local function toggle_term(num)
  local bufnr, winid = terms[num].bufnr, terms[num].winid
  if not vim.api.nvim_win_is_valid(winid) then
    terms[num] = create_term(bufnr)
  else
    vim.api.nvim_win_hide(winid)
  end
end

local TERMINALS_COUNT = 2

for pos = 1, TERMINALS_COUNT do
  terms[pos] = { bufnr = -1, winid = -1 }
  vim.keymap.set({ 'n', 't' }, '<leader>t' .. pos, function()
    toggle_term(pos)
  end, { desc = 'Toggle [T]erminal [' .. pos .. ']' })
end
vim.keymap.set({ 'n', 't' }, '<leader>tt', function()
  toggle_term(1)
end, { desc = '[T]oggle [T]erminal 1' })

--------------------------------------------------
-- Runners
--------------------------------------------------

--- Move to end of file
---@param bufnr number
---@param winid number
local function scroll_to_end(bufnr, winid)
  vim.api.nvim_buf_call(bufnr, function()
    local target_line = vim.tbl_count(vim.api.nvim_buf_get_lines(bufnr, 0, -1, true))
    vim.api.nvim_win_set_cursor(winid, { target_line, 0 })
  end)
end

---@param cmd string
local function run_term_command(cmd)
  vim.cmd('wa')
  if not vim.api.nvim_win_is_valid(terms[1].winid) then
    terms[1] = create_term(terms[1].bufnr)
  end
  scroll_to_end(terms[1].bufnr, terms[1].winid)
  local terminal_job_id = (vim.api.nvim_buf_get_var(terms[1].bufnr, 'terminal_job_id'))
  vim.api.nvim_chan_send(terminal_job_id, '\n')
  vim.api.nvim_chan_send(terminal_job_id, cmd .. '\n')
end

-- NOTE: improve keymaps checking this plugin code: https://github.com/samharju/yeet.nvim/blob/master/lua/yeet/buffer.lua
vim.keymap.set('n', '<leader>cb', function()
  local build = { jdtls = 'mvn spring-boot:run' }
  for _, client in ipairs(vim.lsp.get_clients()) do
    if build[client.name] then
      run_term_command(build[client.name])
      return
    end
  end
  vim.notify('No Build command for attached lsps', vim.log.levels.INFO)
end, { desc = '[C]ode [B]uild' })

vim.keymap.set('n', '<leader>ct', function()
  local test = { jdtls = 'mvn test' }
  for _, client in ipairs(vim.lsp.get_clients()) do
    if test[client.name] then
      run_term_command(test[client.name])
      return
    end
  end
  vim.notify('No Test command for attached lsps', vim.log.levels.INFO)
end, { desc = '[C]ode [T]est' })

--------------------------------------------------
-- Autocmds
--------------------------------------------------

vim.api.nvim_create_autocmd('WinEnter', {
  callback = function()
    if vim.bo.filetype == 'terminal' and vim.tbl_count(vim.api.nvim_list_wins()) == 1 then
      vim.cmd('quit')
    end
  end,
  group = terminal_autocmds,
  desc = 'Close Neovim if the last window is a terminal window',
})
