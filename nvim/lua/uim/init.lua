local M = {}

---@param opts uim.Opts
function M.setup(opts)
  local config = require('uim.config')
  config.setup(opts)
end

function M.select()
  return require('uim.select').select
end

function M.input()
  return require('uim.input').input
end

return M
