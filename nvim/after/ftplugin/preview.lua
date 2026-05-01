vim.bo.bufhidden = 'wipe'
vim.bo.buflisted = false
vim.bo.modifiable = false
vim.wo[0][0].number = false
vim.wo[0][0].relativenumber = false
vim.wo[0][0].statuscolumn = ''
vim.wo[0][0].conceallevel = 3
vim.wo[0][0].concealcursor = 'nvic'
vim.wo[0][0].spell = false

vim.cmd('wincmd J')

vim.keymap.set('n', 'q', '<cmd>q<CR>', { desc = 'Close', buf = 0 })

vim.keymap.set('n', '<leader>pq', '<cmd>pclose<CR>', { desc = 'Close' })
vim.keymap.set('n', '<leader>pb', '<cmd>wincmd P<CR>', { desc = 'Open Preview Buffer' })

-- don't use undo_ftplugin as buffer usually changes ft next
-- and this window/buffer is not used for anything else anyway
