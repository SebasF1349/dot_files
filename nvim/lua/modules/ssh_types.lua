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
    '-e',
    'ssh',
    '-o',
    'StrictHostKeyChecking=accept-new',
    '-o',
    'ExitOnForwardFailure=yes',
    '-o',
    'ServerAliveInterval=30',
    '-N',
    '-L',
    string.format('%s:127.0.0.1:3306', port),
    self.ssh_host,
  }
end

local function wait_for_port(name, port, callback, retries)
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
        wait_for_port(name, port, callback, retries - 1)
      end, 200)
    else
      vim.schedule(function()
        vim.notify('SSH tunnel port ' .. port .. ' failed to open', vim.log.levels.ERROR)
        M.kill_tunnel(name)
      end)
    end
  end)
end

function M.kill_tunnel(name)
  local obj = M.active_tunnels[name]
  M.active_tunnels[name] = nil
  if obj then
    obj:kill('sigterm')
  end
end

function M.SSH:create_tunnel(name, port, on_ready)
  M.kill_tunnel(name)
  local obj
  obj = vim.system(self:get_tunnel_cmd(port), { text = true, env = { SSHPASS = self.ssh_pw } }, function(res)
    if M.active_tunnels[name] ~= obj then
      return
    end
    M.active_tunnels[name] = nil
    vim.schedule(function()
      vim.notify(('Tunnel "%s" died: %s'):format(name, res.stderr or ''), vim.log.levels.ERROR)
    end)
  end)
  M.active_tunnels[name] = obj
  wait_for_port(name, port, on_ready, 50)
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
