local M = {}

function M.select()
  return require('uim.select').select
end

function M.input()
  return require('uim.input').input
end

return M
