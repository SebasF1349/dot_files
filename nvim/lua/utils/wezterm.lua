local M = {}

-- thanks Folke: https://github.com/folke/dot/blob/94ca5961fcfb44101c98d8eed92e137537bc3038/nvim/lua/util/init.lua#L95
local function base64(data)
  data = tostring(data)
  local bit = require('bit')
  local b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
  local b64, len = '', #data
  local rshift, lshift, bor = bit.rshift, bit.lshift, bit.bor

  for i = 1, len, 3 do
    local a, b, c = data:byte(i, i + 2)
    b = b or 0
    c = c or 0

    local buffer = bor(lshift(a, 16), lshift(b, 8), c)
    for j = 0, 3 do
      local index = rshift(buffer, (3 - j) * 6) % 64
      b64 = b64 .. b64chars:sub(index + 1, index + 1)
    end
  end

  local padding = (3 - len % 3) % 3
  b64 = b64:sub(1, -1 - padding) .. ('='):rep(padding)

  return b64
end

local function set_user_var(key, value)
  io.write(string.format('\027]1337;SetUserVar=%s=%s\a', key, base64(value)))
end

local wezterm = vim.api.nvim_create_augroup('Set Wezterm Vars', { clear = true })

function M.setup()
  vim.api.nvim_create_autocmd({ 'VimEnter' }, {
    group = wezterm,
    callback = function()
      set_user_var('IS_NVIM', true)
    end,
    once = true,
    desc = 'Set Wezterm var to true',
  })

  vim.api.nvim_create_autocmd({ 'VimLeave' }, {
    group = wezterm,
    callback = function()
      set_user_var('IS_NVIM', false)
    end,
    once = true,
    desc = 'Set Wezterm var to false',
  })
end

return M
