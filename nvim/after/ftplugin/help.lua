vim.wo.statuscolumn = ' '
vim.wo.signcolumn = 'yes'
vim.bo.buflisted = false
vim.bo.bufhidden = 'wipe'

vim.keymap.set('n', 'q', '<cmd>close<cr>', { buffer = 0, silent = true })

vim.b.undo_ftplugin = (vim.b.undo_ftplugin or '')
  .. '\n '
  .. 'setlocal statuscolumn< signcolumn< buflisted< bufhidden< modifiable<'
  .. ' | sil! nunmap <buffer> q'
