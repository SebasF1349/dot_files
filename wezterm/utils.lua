local wezterm = require("wezterm")

local M = {}

function M.is_nvim(pane)
	return pane:get_user_vars().IS_NVIM == "true"
		or (pane:get_foreground_process_name() and (pane:get_foreground_process_name():find("nv") or pane
			:get_foreground_process_name()
			:find("n?vim")))
		or (
			pane:get_user_vars().WEZTERM_PROG
			and (pane:get_user_vars().WEZTERM_PROG:find("nv") or pane:get_user_vars().WEZTERM_PROG:find("n?vim"))
		)
end

function M.is_windows()
	return wezterm.target_triple == "x86_64-pc-windows-msvc"
end

---@param inputstr string
---@param sep string
---@return string[]
function M.split(inputstr, sep)
	local t = {}
	for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
		table.insert(t, str)
	end
	return t
end

---@param name string
---@return string, string|{DomainName: string}
function M.get_domain(name)
	---@type string|{DomainName: string}
	local domain = "CurrentPaneDomain"
	if name:sub(-1) == "#" then
		local wsl_domains = wezterm.default_wsl_domains()
		if #wsl_domains >= 1 then
			name = name:sub(1, -2)
			domain = { DomainName = wsl_domains[1].name }
		end
	elseif name:sub(-1) == "~" then
		name = name:sub(1, -2)
		domain = { DomainName = "local" }
	end
	return name, domain
end

return M
