local scratch_buffer

vim.api.nvim_create_user_command('Messages', function()
  scratch_buffer = vim.api.nvim_create_buf(false, true)
  vim.bo[scratch_buffer].filetype = 'vim'
  local messages = vim.split(vim.fn.execute('messages', 'silent'), '\n')
  vim.api.nvim_buf_set_text(scratch_buffer, 0, 0, 0, 0, messages)
  vim.cmd('vertical sbuffer ' .. scratch_buffer)
  vim.opt_local.wrap = true
  vim.bo.buflisted = false
  vim.bo.bufhidden = 'wipe'
  vim.keymap.set('n', 'q', '<cmd>close<CR>', { buffer = scratch_buffer })
end, {})

vim.api.nvim_create_autocmd('WinEnter', {
  callback = function()
    if vim.api.nvim_get_current_buf() == scratch_buffer and vim.tbl_count(vim.api.nvim_list_wins()) == 1 then
      vim.cmd('quit')
    end
  end,
  desc = 'Close Neovim if the last window is a terminal window',
})
