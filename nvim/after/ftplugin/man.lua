vim.wo[0][0].statuscolumn = ' '
vim.wo[0][0].signcolumn = 'yes'
vim.bo.buflisted = false
vim.bo.bufhidden = 'wipe'

vim.keymap.set('n', 'q', '<cmd>q!<cr>', { buf = 0 })

vim.keymap.set('n', 'N', '/^[A-Z]<CR>:noh<CR>', { desc = '[N]ext Section', buf = 0 })
vim.keymap.set('n', 'P', '?^[A-Z]<CR>:noh<CR>', { desc = '[P]revious Section', buf = 0 })

vim.keymap.set('n', 'S', [[<CMD>g/^\w<CR>]], { desc = 'List [S]ections', buf = 0 })

vim.b.undo_ftplugin = (vim.b.undo_ftplugin or '')
  .. '\n '
  .. 'setlocal statuscolumn< signcolumn< buflisted< bufhidden<'
  .. ' | sil! nunmap <buffer> q'
  .. ' | sil! nunmap <buffer> N'
  .. ' | sil! nunmap <buffer> P'
  .. ' | sil! nunmap <buffer> S'
