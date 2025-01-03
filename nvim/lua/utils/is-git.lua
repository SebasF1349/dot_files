local is_git

---@return boolean
local M = function()
  if is_git == nil then
    is_git = vim.fs.root(vim.uv.cwd() or 0, '.git') ~= nil
  end
  return is_git
end

return M
