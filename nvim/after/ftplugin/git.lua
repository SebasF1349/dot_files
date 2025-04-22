vim.bo.tabstop = 8

vim.b.undo_ftplugin = (vim.b.undo_ftplugin or '') .. '\n ' .. 'setlocal tabstop< '
