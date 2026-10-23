local M = {}

local function url_encode(s)
  return (s:gsub('[^%w%-._~]', function(c)
    return ('%%%02X'):format(c:byte())
  end))
end

---@class db
---@field db_user string
---@field db_pass string
---@field db_host? string
---@field db_port? number
---@field type 'dev'|'prod'
M.DB = {}
M.DB.__index = M.DB

function M.DB:url(schema)
  return ('mysql://%s:%s@%s:%s/%s?skip-ssl'):format(
    url_encode(self.db_user),
    url_encode(self.db_pass),
    self.db_host or '127.0.0.1',
    self.db_port or 3306,
    url_encode(schema or '')
  )
end

---@param configs table[]
---@return table<string, db>, table
function M.generate(configs)
  local result = {}
  local order = {}
  for _, cfg in ipairs(configs) do
    assert(cfg.name, 'Database config missing "name" field')
    assert(cfg.db_user and cfg.db_pass, 'Database "' .. cfg.name .. '" needs db_user/db_pass')
    assert(not result[cfg.name], 'Duplicate database name: ' .. cfg.name)
    setmetatable(cfg, M.DB)
    result[cfg.name] = cfg
    table.insert(order, cfg.name)
  end
  return result, order
end

return M
