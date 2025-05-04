vim.wo.statuscolumn = ' '
vim.wo.signcolumn = 'yes'
vim.bo.buflisted = false
vim.bo.bufhidden = 'wipe'

vim.b.undo_ftplugin = (vim.b.undo_ftplugin or '')
  .. '\n '
  .. 'setlocal statuscolumn< signcolumn< buflisted< bufhidden< modifiable<'
