local M = {}

local function set_user_var(key, value)
  vim.api.nvim_ui_send(string.format('\027]1337;SetUserVar=%s=%s\a', key, vim.base64.encode(tostring(value))))
end

local wezterm_cmd = vim.uv.os_uname().release:find('WSL') and 'wezterm.exe' or 'wezterm'

---Run `wezterm cli <args>` asynchronously, notifying on failure
---@param args string[]
---@param err_msg string
function M.cli(args, err_msg)
  vim.system(vim.list_extend({ wezterm_cmd, 'cli' }, args), { text = true }, function(p)
    if p.code ~= 0 then
      vim.schedule(function()
        vim.notify(err_msg .. '\n' .. p.stderr, vim.log.levels.ERROR, { title = 'Wezterm' })
      end)
    end
  end)
end

local wezterm = vim.api.nvim_create_augroup('Set Wezterm Vars', { clear = true })

function M.setup()
  vim.api.nvim_create_autocmd({ 'VimEnter', 'VimLeavePre' }, {
    group = wezterm,
    callback = function(ev)
      set_user_var('IS_NVIM', ev.event == 'VimEnter')
    end,
    desc = 'Set Wezterm IS_NVIM var',
  })
end

return M
