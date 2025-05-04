vim.bo.modifiable = true
vim.cmd('silent! %s/\\v-( ?[^\\x00-\\x7F])/-/')
vim.cmd('silent! %s/\\v:\\s+[0-9]*( ?[^\\x00-\\x7F])/:/')
vim.bo.modifiable = false
vim.api.nvim_win_set_cursor(0, { 1, 0 })
