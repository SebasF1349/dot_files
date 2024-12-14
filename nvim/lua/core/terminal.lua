--------------------------------------------------
-- Globals
--------------------------------------------------

---@class term
---@field buf_num number
---@field win_id number

---@type term[]
local terms = {}

--------------------------------------------------
-- Keymaps
--------------------------------------------------

vim.keymap.set('t', 'jk', '<C-\\><C-n>', { desc = 'Escape Terminal Mode' })

vim.keymap.set({ 'n', 't' }, '<leader>tb', function()
  local win = (terms[1].win_id and terms[1].win_id ~= -1) and terms[1].win_id or terms[2].win_id
  if win and win ~= -1 and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_set_current_win(win)
  end
end, { desc = 'Move to [T]erminal [B]uffer ' })

--------------------------------------------------
-- Togglers
--------------------------------------------------

---@param term term
local function check_term_data(term)
  if term.win_id ~= -1 and not vim.list_contains(vim.api.nvim_list_wins(), term.win_id) then
    term.win_id = -1
    if not vim.list_contains(vim.api.nvim_list_bufs(), term.buf_num) then
      term.buf_num = -1
    end
  end
end

local term_cmd = 'botright vsplit | vertical resize 50 | set winfixwidth winfixheight'

---@param num 1|2
local function toggle_term(num)
  local term = terms[num]
  check_term_data(term)
  if term.buf_num == -1 then
    vim.cmd(term_cmd .. '| term')
    term.buf_num = vim.api.nvim_get_current_buf()
    term.win_id = vim.api.nvim_get_current_win()
    vim.cmd.startinsert()
    vim.bo.filetype = 'terminal'
    vim.bo.buflisted = false
    vim.wo.statuscolumn = ''
    vim.wo.winfixheight = true
    vim.wo.winfixwidth = true
    vim.keymap.set('n', 'q', '<cmd>close<cr>', { buffer = term.buf_num, silent = true })
    vim.api.nvim_set_option_value('winhighlight', 'Normal:TerminalNormal', { win = term.win_id, scope = 'local' })
    vim.api.nvim_create_autocmd('BufEnter', {
      buffer = term.buf_num,
      callback = function()
        vim.cmd.startinsert()
      end,
    })
  elseif term.win_id == -1 then
    vim.cmd(term_cmd .. '| b' .. term.buf_num)
    term.win_id = vim.api.nvim_get_current_win()
  else
    vim.api.nvim_win_close(term.win_id, true)
    term.win_id = -1
  end
end

local TERMINALS_COUNT = 2

for pos = 1, TERMINALS_COUNT do
  terms[pos] = { buf_num = -1, win_id = -1, is_hidden = -1 }
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

local function scroll_to_end(bufnr, winid)
  vim.api.nvim_buf_call(bufnr, function()
    local target_line = vim.tbl_count(vim.api.nvim_buf_get_lines(bufnr, 0, -1, true))
    vim.api.nvim_win_set_cursor(winid, { target_line, 0 })
  end)
end

---@param cmd string
local function run_term_command(cmd)
  vim.cmd('wa')
  local term = terms[1]
  check_term_data(term)
  if term.win_id == -1 then
    toggle_term(1)
  end
  scroll_to_end(term.buf_num, term.win_id)
  local terminal_job_id = (vim.api.nvim_buf_get_var(term.buf_num, 'terminal_job_id'))
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

local terminal_autocmds = vim.api.nvim_create_augroup('Terminal Autocmds', { clear = true })

vim.api.nvim_create_autocmd('WinEnter', {
  callback = function()
    if vim.bo.filetype == 'terminal' and vim.tbl_count(vim.api.nvim_list_wins()) == 1 then
      vim.cmd('quit')
    end
  end,
  group = terminal_autocmds,
  desc = 'Close Neovim if the last window is a terminal window',
})
