vim.keymap.set('n', 'N', '/^[A-Z]<CR>:noh<CR>', { desc = '[N]ext Section' })
vim.keymap.set('n', 'P', '?^[A-Z]<CR>:noh<CR>', { desc = '[P]revious Section' })

vim.keymap.set('n', 'S', [[<CMD>g/^\w<CR>]], { desc = 'List [S]ections' })

vim.b.undo_ftplugin = (vim.b.undo_ftplugin or '')
  .. '\n '
  .. ' | sil! nunmap <buffer> N'
  .. ' | sil! nunmap <buffer> P'
  .. ' | sil! nunmap <buffer> S'
