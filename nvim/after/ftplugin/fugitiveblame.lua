vim.wo.statuscolumn = ' '
vim.wo.signcolumn = 'yes'
vim.bo.buflisted = false
vim.bo.bufhidden = 'wipe'

vim.keymap.set('n', 'q', '<cmd>close<cr>', { buf = 0 })

vim.b.undo_ftplugin = (vim.b.undo_ftplugin or '')
  .. '\n '
  .. 'setlocal statuscolumn< signcolumn< buflisted< bufhidden<'
  .. ' | sil! nunmap <buffer> q'
