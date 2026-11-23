local wezterm = require("wezterm")

local M = {}

---@param pane table
---@return boolean
function M.is_nvim(pane)
	return pane:get_user_vars().IS_NVIM == "true"
end

---@return boolean
function M.is_windows()
	return wezterm.target_triple:find("windows") ~= nil
end

--- PromptInputLine that only calls `fn` when something was entered
---@param description string
---@param fn fun(window: table, line: string)
function M.prompt(description, fn)
	return wezterm.action.PromptInputLine({
		description = description,
		action = wezterm.action_callback(function(window, _, line)
			if line and #line > 0 then
				fn(window, line)
			end
		end),
	})
end

---@param pane table
---@return string|nil
function M.pane_cwd(pane)
	local url = pane:get_current_working_dir()
	if url and M.is_windows() then
		return (url.file_path:gsub("^/(%a):", "%1:"))
	end
	return url and url.file_path
end

--- Strip a trailing "#" (first WSL domain) or "~" (local domain) from `name`
---@param name string
---@return string, string|{DomainName: string}
function M.get_domain(name)
	local suffix = name:sub(-1)
	local wsl = suffix == "#" and wezterm.default_wsl_domains()[1]
	if wsl then
		return name:sub(1, -2), { DomainName = wsl.name }
	elseif suffix == "~" then
		return name:sub(1, -2), { DomainName = "local" }
	end
	return name, "CurrentPaneDomain"
end

return M
