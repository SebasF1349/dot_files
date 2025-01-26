local M = {}

--- First letter uppercase, lowercase the rest
---@param str string
---@return string
local function capitalize(str)
  local hl, _ = str:lower():gsub('^%l', string.upper)
  return hl
end

---@param severity vim.diagnostic.Severity
---@return string
M.get_diagnostic_hl = function(severity)
  return 'DiagnosticSign' .. capitalize(vim.diagnostic.severity[severity])
end

M.diagnostic_hl_char =
  { E = 'DiagnosticSignError', W = 'DiagnosticSignWarn', I = 'DiagnosticSignInfo', N = 'DiagnosticSignHint' }

M.diagnostic_icons_num = { ' ', ' ', ' ', ' ' }

M.diagnostic_icons_char = { E = ' ', W = ' ', I = ' ', N = ' ' }

return M
