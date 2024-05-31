local M = {}

local current_version = "nvim-0.10"
local nightly_version = "nvim-0.11"

M.is_old = function()
  return not vim.fn.has(current_version)
end

M.is_stable = function()
  return vim.fn.has(current_version) and not vim.fn.has(nightly_version)
end

M.is_nightly = function()
  return vim.fn.has(nightly_version)
end

return M
