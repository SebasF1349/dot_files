vim.keymap.set(
  'n',
  'dt',
  ':Gtabedit <Plug><cfile><Bar>Gdiffsplit<CR>',
  { desc = 'Open [D]iff in New [T]ab', remap = true, buffer = 0 }
)

vim.b.undo_ftplugin = (vim.b.undo_ftplugin or '') .. '\n ' .. ' | sil! nunmap <buffer> dt'
