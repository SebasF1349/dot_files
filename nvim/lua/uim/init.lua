local M = {}

-- TODO: Make highlights autoload (plugin/ directory)
vim.api.nvim_set_hl(0, 'UimSelectLabels', { link = 'Title', default = true })
vim.api.nvim_set_hl(0, 'UimTitle', { link = 'FloatTitle', default = true })
vim.api.nvim_set_hl(0, 'UimFooter', { link = 'FloatTitle', default = true })
vim.api.nvim_set_hl(0, 'UimNormal', { link = 'NormalFloat', default = true })
vim.api.nvim_set_hl(0, 'UimBorder', { link = 'FloatBorder', default = true })

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
