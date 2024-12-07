local M = {}

M.is_win = vim.fn.has('win32') ~= 0

M.dir_separator = vim.fn.has('win32') ~= 0 and '\\' or '/'

M.joinpath = function(...)
  local path = vim.fs.joinpath(...)
  if M.is_win then
    path = path:gsub('/', '\\')
  end
  return path
end

return M
