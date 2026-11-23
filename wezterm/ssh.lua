local wezterm = require("wezterm")
local utils = require("utils")

local M = {}

-- Every ssh connection opens as a tab in a separate wezterm process, whose window class lets
-- the window manager place it, e.g. for i3: assign [class="^wezterm-ssh$"] 2
M.class = "wezterm-ssh"
M.env = "WEZTERM_SSH_WINDOW"
M.is_ssh_process = os.getenv(M.env) == "1"

---@param host string
function M.open(host)
	local gui = wezterm.executable_dir .. (utils.is_windows() and "\\wezterm-gui.exe" or "/wezterm-gui")
	-- without --always-new-process, `start` hands the tab to the running instance with this class
	local args = utils.is_windows() and { "cmd.exe", "/c", "set", M.env .. "=1&&" } or { "env", M.env .. "=1" }
	for _, arg in ipairs({ gui, "start", "--class", M.class, "--new-tab", "--domain", "SSH:" .. host }) do
		table.insert(args, arg)
	end
	wezterm.background_child_process(args)
end

---@param win table
---@param pane table
function M.select_ssh(win, pane)
	local choices = {}
	for _, domain in ipairs(wezterm.default_ssh_domains()) do
		local host = domain.name:match("^SSH:(.+)$")
		if host then
			table.insert(choices, { id = host, label = host })
		end
	end
	win:perform_action(
		wezterm.action.InputSelector({
			title = "Choose SSH",
			choices = choices,
			fuzzy = true,
			fuzzy_description = "Select SSH: ",
			action = wezterm.action_callback(function(_, _, host)
				if host then
					M.open(host)
				end
			end),
		}),
		pane
	)
end

return M
