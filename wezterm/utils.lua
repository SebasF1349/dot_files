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

return M
