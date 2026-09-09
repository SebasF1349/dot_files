local M = {}

M.active_tunnels = {}

---@class ssh
---@field ssh_host string
---@field ssh_pw string
M.SSH = {}
M.SSH.__index = M.SSH

function M.SSH:get_tunnel_cmd(port)
  return {
    'sshpass',
    '-p',
    self.ssh_pw,
    'ssh',
    '-o',
    'StrictHostKeyChecking=accept-new',
    '-N',
    '-L',
    string.format('%s:127.0.0.1:3306', port),
    self.ssh_host,
  }
end

local function wait_for_port(port, callback, retries, interval)
  retries = retries or 15
  interval = interval or 100
  local client = vim.uv.new_tcp()
  if not client then
    vim.notify('Error creating a tcp connection', vim.log.levels.ERROR)
    return
  end
  client:connect('127.0.0.1', port, function(err)
    client:close()
    if not err then
      vim.schedule(callback)
    elseif retries > 0 then
      vim.defer_fn(function()
        wait_for_port(port, callback, retries - 1, interval)
      end, interval)
    else
      vim.schedule(function()
        vim.notify('SSH tunnel port ' .. port .. ' failed to open', vim.log.levels.ERROR)
      end)
    end
  end)
end

function M.SSH:create_tunnel(name, port, on_ready)
  if M.active_tunnels[name] then
    M.active_tunnels[name]:kill('sigterm')
  end

  local obj = vim.system(self:get_tunnel_cmd(port), { detach = true }, function(res)
    M.active_tunnels[name] = nil
    if res.code ~= 0 and res.code ~= 143 and res.code ~= 9 then
      vim.schedule(function()
        vim.notify('Tunnel "' .. name .. '" failed: ' .. (res.stderr or ''), vim.log.levels.ERROR)
      end)
    end
  end)

  M.active_tunnels[name] = obj
  wait_for_port(port, on_ready)
end

function M.kill_all()
  for _, obj in pairs(M.active_tunnels) do
    obj:kill('sigterm')
  end
  M.active_tunnels = {}
end

---@param configs table[]
---@return table<string, ssh>
function M.generate(configs)
  local result = {}
  for name, cfg in pairs(configs) do
    setmetatable(cfg, M.SSH)
    result[name] = cfg
  end
  return result
end

return M
