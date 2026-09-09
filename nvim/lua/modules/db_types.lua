local M = {}

local function url_encode(str)
  if str then
    str = str:gsub('([^%w%-%.%_%~])', function(c)
      return string.format('%%%02X', string.byte(c))
    end)
  end
  return str
end

local mysql_cmd = 'mysql://%s:%s@%s:%s/?skip-ssl'

---@class db
---@field db_user string
---@field db_pass string
---@field db_host? string
---@field db_port number
---@field type 'dev'|'prod'
M.DB = {}
M.DB.__index = M.DB

function M.DB:generate_cmd(ip, port)
  return string.format(mysql_cmd, url_encode(self.db_user), url_encode(self.db_pass), ip, port)
end

function M.DB:get_connection_cmd()
  return self:generate_cmd(self.db_host or '127.0.0.1', self.db_port or 3306)
end

---@param configs table[]
---@return table<string, db>, table
function M.generate(configs)
  local result = {}
  local order = {}
  local port = 3306
  for _, cfg in ipairs(configs) do
    assert(cfg.name, 'Database config missing "name" field')
    setmetatable(cfg, M.DB)
    if not cfg.db_host then
      port = port + 1
      cfg.db_port = port
    end
    result[cfg.name] = cfg
    table.insert(order, cfg.name)
  end
  return result, order
end

return M
