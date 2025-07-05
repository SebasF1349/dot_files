vim.wo.statuscolumn = ' '
vim.wo.signcolumn = 'yes'
vim.bo.buflisted = false
vim.bo.bufhidden = 'wipe'

vim.keymap.set('n', 'q', '<cmd>close<cr>', { buffer = 0 })

vim.keymap.set(
  'n',
  'dt',
  ':Gtabedit <Plug><cfile><Bar>Gdiffsplit<CR>',
  { desc = 'Open [D]iff in New [T]ab', remap = true, buffer = 0 }
)

vim.b.undo_ftplugin = (vim.b.undo_ftplugin or '')
  .. '\n '
  .. 'setlocal statuscolumn< signcolumn< buflisted< bufhidden<'
  .. ' | sil! nunmap <buffer> dt'
  .. ' | sil! nunmap <buffer> q'
