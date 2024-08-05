--------------------------------------------------
-- Buffer Management
--------------------------------------------------
-- NOTE: maybe use a custom list as arglist misses a good API and buflist is clunky
-- deleting a buf is an extra keymap
-- change gb prefix for \ ?

local function delete_buf()
  vim.api.nvim_set_option_value('buflisted', false, { buf = 0 })
  local alternative_buffer = vim.fn.expand('#:p')
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if
      vim.api.nvim_buf_is_loaded(bufnr)
      and vim.api.nvim_get_option_value('buflisted', { buf = bufnr })
      and vim.api.nvim_buf_get_name(bufnr) == alternative_buffer
    then
      return '<cmd>edit #<CR>'
    end
  end
  return '<cmd>silent! bnext<CR>'
end

local function delete_all_other_bufs()
  local current_bufnr = vim.api.nvim_win_get_buf(0)
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) and bufnr ~= current_bufnr then
      vim.api.nvim_set_option_value('buflisted', false, { buf = bufnr })
    end
  end
end

vim.api.nvim_create_user_command('CleanBuflist', function(opts)
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.list_contains(opts.fargs, tostring(bufnr)) ~= opts.bang then
      vim.api.nvim_set_option_value('buflisted', false, { buf = bufnr })
    end
  end
  if not vim.api.nvim_get_option_value('buflisted', { buf = 0 }) then
    vim.cmd('silent! bnext')
  end
end, { nargs = '*', bang = true })

vim.keymap.set('n', 'gbb', '<cmd>ls<CR>:b<space>', { desc = 'Change Open [B]uffer' })
vim.keymap.set('n', ']b', '<cmd>bnext<CR>', { desc = 'Next Open Buffer' })
vim.keymap.set('n', '[b', '<cmd>bprevious<CR>', { desc = 'Previous Open Buffer' })
-- maybe add keymap for `:b#` that's easier than C-^
vim.keymap.set('n', 'gba', '<cmd>set buflisted<CR>', { desc = '[A]dd Open Buffer' })
vim.keymap.set('n', 'gbd', delete_buf, { desc = '[D]elete Open Buffer', expr = true })
-- not using :bdel as it removes the file from diagnostics
vim.keymap.set('n', 'gbc', '<cmd>ls<CR>:CleanBuflist ', { desc = '[C]lean Open Buffer' })
vim.keymap.set('n', 'gbo', delete_all_other_bufs, { desc = 'Make [O]nly Buffer' })

--------------------------------------------------
-- Opening Buffers
--------------------------------------------------

local edit_buffer = {
  w = { cmd = ':edit ', desc = '[W]indow' },
  s = { cmd = ':split ', desc = '[S]plit' },
  v = { cmd = ':vsplit ', desc = '[V]ertical split' },
}

for key, opts in pairs(edit_buffer) do
  -- vim.keymap.set('n', 'ge' .. key, opts.cmd .. '**/*', { desc = '[E]dit Buffer in ' .. opts.desc })
  vim.keymap.set('n', 'gE' .. key, function()
    return opts.cmd .. vim.fn.expand('%:p:h') .. '/'
  end, { desc = '[E]dit Buffer in Current Directory in ' .. opts.desc, expr = true })
  -- vim.keymap.set('n', 'gs' .. key, function()
  --   return opts.cmd .. '**/* | set nobuflisted' .. ('<left>'):rep(18)
  -- end, { desc = 'Open [S]cratch Buffer in ' .. opts.desc, expr = true })
  vim.keymap.set('n', 'ga' .. key, function()
    local current_path = vim.fn.expand('%:p')
    local alternative_path
    if vim.o.filetype == 'java' then
      if current_path:find('test') then
        alternative_path = current_path:gsub('/test/', '/main/'):gsub('Test', '')
      else
        alternative_path = current_path:gsub('/main/', '/test/'):gsub('%.java', 'Test.java')
      end
    end
    return opts.cmd .. alternative_path .. '<CR>'
  end, { desc = 'Edit [A]lternative File in ' .. opts.desc, expr = true })
end

local find_buffer = {
  w = { cmd = ':find ', desc = '[W]indow' },
  s = { cmd = ':sfind ', desc = '[S]plit' },
  v = { cmd = ':vsplit | find ', desc = '[V]ertical split' },
}

for key, opts in pairs(find_buffer) do
  vim.keymap.set('n', 'ge' .. key, opts.cmd, { desc = '[E]dit Buffer in ' .. opts.desc })
  vim.keymap.set('n', 'gs' .. key, function()
    return opts.cmd .. ' | set nobuflisted' .. ('<left>'):rep(18)
  end, { desc = 'Open [S]cratch Buffer in ' .. opts.desc, expr = true })
end
