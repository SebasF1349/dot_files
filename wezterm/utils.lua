local M = {}

function M.is_nvim(pane)
	return pane:get_foreground_process_name():find("n?vim")
		or (pane:get_user_vars().WEZTERM_PROG and pane:get_user_vars().WEZTERM_PROG:find("nv"))
end

return M
