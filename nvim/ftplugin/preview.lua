vim.bo.bufhidden = 'wipe'
vim.bo.buflisted = false
vim.bo.modifiable = false
vim.wo.number = false
vim.wo.relativenumber = false
vim.wo.statuscolumn = ''
vim.wo.conceallevel = 3
vim.wo.concealcursor = 'nvic'
vim.wo.spell = false

vim.cmd('wincmd J')

vim.keymap.set('n', 'q', '<cmd>q<CR>', { desc = 'Close', buffer = 0 })

vim.keymap.set('n', '<leader>pq', '<cmd>pclose<CR>', { desc = 'Close' })
vim.keymap.set('n', '<leader>pb', '<cmd>wincmd P<CR>', { desc = 'Open Preview Buffer' })

-- don't use undo_ftplugin as buffer usually changes ft next
-- and this window/buffer is not used for anything else anyway
