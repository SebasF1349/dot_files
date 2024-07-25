local is_git

---@return boolean
local M = function()
  if is_git == nil then
    is_git = vim.fs.root(vim.env.PWD, '.git') ~= nil
  end
  return is_git
end

return M
