local wezterm = require("wezterm")

local M = {}

function M.select_ssh(win, pane)
	local domains = {}
	for _, domain in ipairs(wezterm.default_ssh_domains()) do
		local ssh, d = domain.name:match("(.*):(.*)")
		if ssh == "SSH" then
			table.insert(domains, { id = d, label = d })
		end
	end

	win:perform_action(
		wezterm.action.InputSelector({
			title = "Choose SSH",
			choices = domains,
			fuzzy = true,
			fuzzy_description = "Select SSH: ",
			action = wezterm.action_callback(function(_, _, id, label)
				if not id then
					return
				end
				pane:send_text("wezterm ssh " .. id .. "\r")
				pane:tab():set_title(label)
			end),
		}),
		pane
	)
end

return M
