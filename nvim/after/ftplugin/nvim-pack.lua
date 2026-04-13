vim.keymap.set('n', 'q', '<cmd>close<CR>', { desc = 'Close', buf = 0 })

vim.keymap.set('n', 'gx', function()
  local cfile = vim.fn.expand('<cfile>')
  if vim.startswith(cfile, 'http') or not cfile:match('%x%x%x%x%x+') then
    vim.ui.open(cfile)
    return
  end

  local current_line = vim.api.nvim_win_get_cursor(0)[1]
  local url = nil

  for i = current_line, math.max(1, current_line - 10), -1 do
    local line_content = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1]
    url = line_content:match('Source:%s*(https?://[%w%./%-]+)')
    if url then
      break
    end
  end

  if url then
    vim.ui.open(url .. '/commit/' .. cfile)
  else
    vim.print("Could not find a 'Source:' URL above the cursor")
  end
end, { desc = 'Open in Browser', buf = 0 })

vim.b.undo_ftplugin = (vim.b.undo_ftplugin or '') .. '\n ' .. 'sil! nunmap <buffer> q'
