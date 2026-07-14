local M = {}

M.is_win = vim.fn.has('win32') ~= 0

M.dir_separator = M.is_win and '\\' or '/'

return M
