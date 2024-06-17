local M = {}

local current_version = "nvim-0.10"
local nightly_version = "nvim-0.11"

M.is_old = function()
  return vim.fn.has(current_version) == 0
end

M.is_stable = function()
  return vim.fn.has(current_version) == 1 and vim.fn.has(nightly_version) == 0
end

M.is_nightly = function()
  return vim.fn.has(nightly_version) == 1
end

return M
