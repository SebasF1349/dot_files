local M = {}

vim.api.nvim_set_hl(0, 'UimSelectLabels', { link = 'Title' })
vim.api.nvim_set_hl(0, 'UimTitle', { link = 'FloatTitle' })
vim.api.nvim_set_hl(0, 'UimFooter', { link = 'FloatTitle' })
vim.api.nvim_set_hl(0, 'UimNormal', { link = 'NormalFloat' })
vim.api.nvim_set_hl(0, 'UimBorder', { link = 'FloatBorder' })

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
