local M = {}

M.is_win = vim.fn.has('win32') ~= 0

M.dir_separator = M.is_win and '\\' or '/'

M.correct_separator = function(path)
  if M.is_win then
    path = path:gsub('/', '\\')
  end
  return path
end

M.joinpath = function(...)
  local path = vim.fs.joinpath(...)
  return M.correct_separator(path)
end

return M
