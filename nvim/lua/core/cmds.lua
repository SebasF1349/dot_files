vim.api.nvim_create_user_command('Messages', function()
  local scratch_buffer = vim.api.nvim_create_buf(false, true)
  vim.bo[scratch_buffer].filetype = 'vim'
  local messages = vim.split(vim.fn.execute('messages', 'silent'), '\n')
  vim.api.nvim_buf_set_text(scratch_buffer, 0, 0, 0, 0, messages)
  vim.cmd('vertical sbuffer ' .. scratch_buffer)
  vim.opt_local.wrap = true
  vim.keymap.set('n', 'q', '<cmd>close<CR>', { buffer = scratch_buffer })
end, {})
