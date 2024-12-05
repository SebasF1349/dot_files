local M = {}

M.is_win = vim.fn.has('win32') ~= 0

M.dir_separator = vim.fn.has('win32') ~= 0 and '\\' or '/'

return M
