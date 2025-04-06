vim.wo.statuscolumn = ' '
vim.wo.signcolumn = 'yes'
vim.bo.buflisted = false
vim.bo.bufhidden = 'wipe'

vim.keymap.set('n', 'q', '<cmd>q!<cr>', { buffer = 0, silent = true })

vim.keymap.set('n', 'N', '/^[A-Z]<CR>:noh<CR>', { desc = '[N]ext Section' })
vim.keymap.set('n', 'P', '?^[A-Z]<CR>:noh<CR>', { desc = '[P]revious Section' })

vim.keymap.set('n', 'S', [[<CMD>g/^\w<CR>]], { desc = 'List [S]ections' })

vim.b.undo_ftplugin = (vim.b.undo_ftplugin or '')
  .. '\n '
  .. 'setlocal statuscolumn< signcolumn< buflisted< bufhidden<'
  .. ' | sil! nunmap <buffer> q'
  .. ' | sil! nunmap <buffer> N'
  .. ' | sil! nunmap <buffer> P'
  .. ' | sil! nunmap <buffer> S'
