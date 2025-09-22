vim.wo.spell = true
vim.bo.spelllang = 'es,en'
vim.bo.comments = 'b:#,b:-'
vim.bo.formatoptions = vim.bo.formatoptions .. 'cro'

local line = vim.api.nvim_get_current_line()
if #line == 0 then
  vim.cmd.startinsert()
end

vim.b.undo_ftplugin = (vim.b.undo_ftplugin or '') .. '\n ' .. 'setlocal spell< spelllang< comments< formatoptions< '
