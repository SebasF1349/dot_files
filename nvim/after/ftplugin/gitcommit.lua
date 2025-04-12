vim.wo.spell = true
vim.bo.spelllang = 'es,en'

local line = vim.api.nvim_get_current_line()
if #line == 0 then
  vim.cmd.startinsert()
end

vim.b.undo_ftplugin = (vim.b.undo_ftplugin or '') .. '\n ' .. 'setlocal spell< spelllang< '
