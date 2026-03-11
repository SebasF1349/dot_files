local M = {}

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
    'StrictHostKeyChecking=accept-new', -- Auto-accept new host keys
    '-N',
    '-L',
    string.format('%s:127.0.0.1:3306', port),
    self.ssh_host,
  }
end

function M.SSH:create_tunnel(active_tunnels, name, port)
  local obj = vim.system(self:get_tunnel_cmd(port), { detach = true }, function(res)
    active_tunnels[name] = nil
    if res.code ~= 0 and res.code ~= 143 and res.code ~= 9 then
      vim.schedule(function()
        vim.notify('Tunnel "' .. name .. '" failed: ' .. (res.stderr or ''), vim.log.levels.ERROR)
      end)
    end
  end)
  return obj.pid
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
