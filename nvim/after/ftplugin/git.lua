vim.wo.statuscolumn = ' '
vim.wo.signcolumn = 'yes'
vim.bo.buflisted = false
vim.bo.bufhidden = 'wipe'
vim.bo.tabstop = 8

vim.keymap.set('n', '<C-n>', 'jp', { buf = 0, remap = true })
vim.keymap.set('n', '<C-p>', 'kp', { buf = 0, remap = true })

vim.keymap.set('n', 'q', '<cmd>close<cr>', { buf = 0 })

vim.b.undo_ftplugin = (vim.b.undo_ftplugin or '')
  .. '\n '
  .. 'setlocal tabstop< statuscolumn< signcolumn< buflisted< bufhidden< modifiable<'
  .. ' | sil! nunmap <buffer> q'
  .. ' | sil! nunmap <buffer> <C-n>'
  .. ' | sil! nunmap <buffer> <C-p>'
