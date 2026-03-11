local M = {}

local function url_encode(str)
  if str then
    -- Find any character that isn't alphanumeric, '-', '_', '.', or '~'
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
  local db_user = url_encode(self.db_user)
  local db_pass = url_encode(self.db_pass)
  return string.format(mysql_cmd, db_user, db_pass, ip, port)
end

function M.DB:get_connection_cmd()
  local host = self.db_host or '127.0.0.1'
  local port = self.db_port or '3306'
  return self.generate_cmd(self, host, port)
end

---@param configs table[]
---@return table<string, db>
function M.generate(configs)
  local result = {}
  local port = 3306
  for name, cfg in pairs(configs) do
    setmetatable(cfg, M.DB)
    if not cfg.db_host then
      port = port + 1
      cfg.db_port = port
    end
    result[name] = cfg
  end
  return result
end

return M
