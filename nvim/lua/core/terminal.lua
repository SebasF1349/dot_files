---@class term
---@field buf_num number
---@field win_id number

---@param term term
local function check_term_data(term)
  if term.win_id ~= -1 and not vim.list_contains(vim.api.nvim_list_wins(), term.win_id) then
    term.win_id = -1
    if not vim.list_contains(vim.api.nvim_list_bufs(), term.buf_num) then
      term.buf_num = -1
    end
  end
end

---@type term[]
local terms = {}
---@param num 1|2
local function toggle_term(num)
  local term = terms[num]
  check_term_data(term)
  if term.buf_num == -1 then
    vim.cmd('botright vsplit | vertical resize 50 | set winfixwidth winfixheight | term')
    term.buf_num = vim.api.nvim_get_current_buf()
    term.win_id = vim.api.nvim_get_current_win()
    vim.api.nvim_set_option_value('winhighlight', 'Normal:TerminalNormal', { win = term.win_id, scope = 'local' })
  elseif term.win_id == -1 then
    vim.cmd('botright vsplit | vertical resize 50 | set winfixwidth winfixheight | b' .. term.buf_num)
    term.win_id = vim.api.nvim_get_current_win()
  else
    vim.api.nvim_win_close(term.win_id, true)
    term.win_id = -1
  end
end

for pos = 1, 2 do
  terms[pos] = { buf_num = -1, win_id = -1, is_hidden = -1 }
  vim.keymap.set({ 'n', 't' }, 't' .. pos, function()
    toggle_term(pos)
  end, { desc = 'Toggle [T]erminal [' .. pos .. ']' })
end
vim.keymap.set({ 'n', 't' }, 'tt', function()
  toggle_term(1)
end, { desc = '[T]oggle [T]erminal 1' })

vim.keymap.set({ 'n', 't' }, 'tb', function()
  local win = (terms[1].win_id and terms[1].win_id ~= -1) and terms[1].win_id or terms[2].win_id
  if win and win ~= -1 and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_set_current_win(win)
  end
end, { desc = 'Move to [T]erminal [B]uffer ' })

vim.keymap.set('t', 'jk', '<C-\\><C-n>', { desc = 'Escape Terminal Mode' })

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
vim.keymap.set('n', 'crb', function()
  local build = { jdtls = 'mvn spring-boot:run' }
  for _, client in ipairs(vim.lsp.get_clients()) do
    if build[client.name] then
      run_term_command(build[client.name])
      return
    end
  end
  vim.notify('No Build command for attached lsps', vim.log.levels.INFO)
end, { desc = '[C]ode [R]unner [B]uild' })

vim.keymap.set('n', 'crt', function()
  local test = { jdtls = 'mvn test' }
  for _, client in ipairs(vim.lsp.get_clients()) do
    if test[client.name] then
      run_term_command(test[client.name])
      return
    end
  end
  vim.notify('No Test command for attached lsps', vim.log.levels.INFO)
end, { desc = '[C]ode [R]unner [T]est' })
