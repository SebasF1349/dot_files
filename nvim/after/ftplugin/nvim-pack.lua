vim.keymap.set('n', 'q', '<cmd>close<CR>', { desc = 'Close', buffer = 0 })

vim.b.undo_ftplugin = (vim.b.undo_ftplugin or '')
  .. '\n '
  .. 'sil! nunmap <buffer> q'
