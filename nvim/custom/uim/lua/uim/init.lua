local M = {}

function M.select()
  return require('uim.uim').select
end

function M.input()
  return require('uim.uim').input
end

return M
