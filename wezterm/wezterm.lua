local wezterm = require("wezterm")
local utils = require("utils")

local config = wezterm.config_builder and wezterm.config_builder() or {}

require("keys").setup(config)

config.color_scheme = "Catppuccin Mocha"
config.font = wezterm.font("JetBrainsMono Nerd Font")
config.check_for_updates = false

config.window_padding = { left = "0.5cell", right = "0.5cell", top = "0cell", bottom = "0cell" }
config.use_resize_increments = true
config.unzoom_on_switch_pane = true

config.use_fancy_tab_bar = false
config.tab_max_width = 32
config.show_new_tab_button_in_tab_bar = false

config.enable_scroll_bar = false
config.inactive_pane_hsb = { saturation = 1, brightness = 0.5 }
config.window_close_confirmation = "NeverPrompt"
config.cursor_blink_ease_in = "Constant"
config.cursor_blink_ease_out = "Constant"

if utils.is_windows() then
	config.default_prog = { "pwsh", "-NoLogo", "-ExecutionPolicy", "RemoteSigned", "-NoProfileLoadTime" }
	config.window_decorations = "TITLE | RESIZE"
	local background_image = wezterm.executable_dir .. "\\wallpaper_clean_mini.jpeg"
	local scheme = wezterm.color.get_builtin_schemes()[config.color_scheme]
	config.background = {
		{
			source = { File = background_image },
			horizontal_align = "Center",
			vertical_align = "Middle",
		},
		{
			source = { Color = scheme.background },
			height = "100%",
			width = "100%",
			opacity = 0.7,
		},
	}
elseif wezterm.target_triple:find("linux") then
	config.window_background_opacity = 0.9
	config.enable_wayland = false
end

wezterm.on("update-status", function(window, pane)
	local ok, domain = pcall(function()
		return pane:get_domain_name()
	end)
	if not ok then
		return
	end

	local process_name = pane:get_foreground_process_name() or ""
	local is_ssh = domain:find("SSH") or process_name:lower():find("ssh")
	if is_ssh then
		local host = domain:match("to%s+(.+)$")
		wezterm.mux.rename_workspace(wezterm.mux.get_active_workspace(), host)
		window:set_config_overrides({
			color_scheme = "Catppuccin Frappe",
			background = {},
		})
	end

	local color_scheme = window:effective_config().resolved_palette

	local elements = {}
	table.insert(elements, { Background = { Color = color_scheme.background } })

	local mode = window:active_key_table()
	local modes = {
		copy_mode = { icon = " 󰆏 ", color = color_scheme.ansi[7] },
		search_mode = { icon = " 󰍉 ", color = color_scheme.ansi[4] },
	}
	local current = modes[mode] or { icon = " 󰌌 ", color = color_scheme.split }

	table.insert(elements, { Foreground = { Color = current.color } })
	table.insert(elements, { Text = current.icon })

	if is_ssh then
		table.insert(elements, { Foreground = { Color = color_scheme.ansi[2] } })
	else
		table.insert(elements, { Foreground = { Color = color_scheme.split } })
	end
	table.insert(elements, { Text = " 󰒋 " })

	local bg = wezterm.color.parse(color_scheme.background):lighten(0.2)
	local workspace = window:active_workspace()

	table.insert(elements, { Background = { Color = bg } })
	table.insert(elements, { Foreground = { Color = color_scheme.foreground } })
	table.insert(elements, { Text = " " .. workspace .. " " })

	window:set_right_status(wezterm.format(elements))
end)

wezterm.on("format-window-title", function(tab)
	return wezterm.mux.get_tab(tab.tab_id):window():get_workspace()
end)

wezterm.on("gui-startup", function(cmd)
	local _, pane, window = wezterm.mux.spawn_window(cmd or {})
	if not pane:get_domain_name():find("SSH") then
		local sessions = require("sessions")
		sessions.setup()
		sessions.select_workspace(window:gui_window(), pane, true)
	end
end)

return config
