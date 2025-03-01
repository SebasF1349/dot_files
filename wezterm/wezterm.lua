local wezterm = require("wezterm")
local utils = require("utils")

local config = {}

if wezterm.config_builder then
	config = wezterm.config_builder()
end

require("keys").setup(config)

config.color_scheme = "Catppuccin Mocha"

if utils.is_windows() then
	local has_wsl, _, res = pcall(wezterm.run_child_process, { "wsl", "--version" })
	local start = "WSL version"
	if has_wsl and res:gsub("\0", ""):sub(1, #start) == start then
		config.default_domain = "WSL:Ubuntu"
	else
		config.default_cwd = "D:\\Trabajos\\Proyectos - Dev"
	end
	config.default_prog = { "pwsh.exe" }
	-- config.window_decorations = "RESIZE" -- it breaks wezterm in hyprland -- wait for wayland wez rewrite
	local background_image = wezterm.executable_dir .. "\\wallpaper_clean_mini.jpeg"
	local scheme = wezterm.color.get_builtin_schemes()["Catppuccin Mocha"]
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
elseif wezterm.target_triple == "x86_64-unknown-linux-gnu" then
	config.window_background_opacity = 0.9
end

--config.adjust_window_size_when_changing_font_size = false
config.font = wezterm.font("JetBrainsMono Nerd Font")
config.use_fancy_tab_bar = false
config.tab_max_width = 32
config.unzoom_on_switch_pane = true
config.show_new_tab_button_in_tab_bar = false
config.inactive_pane_hsb = {
	saturation = 1,
	brightness = 0.5,
}
config.use_resize_increments = true

config.enable_scroll_bar = false

config.window_close_confirmation = "NeverPrompt"

-- config.front_end = "WebGpu"
-- config.webgpu_power_preference = "HighPerformance"
-- config.animation_fps = 1
config.cursor_blink_ease_in = "Constant"
config.cursor_blink_ease_out = "Constant"

config.check_for_updates = false

config.window_padding = { left = "0.5cell", right = "0.5cell", top = "0cell", bottom = "0cell" }

config.enable_wayland = false

wezterm.on("update-status", function(window, _)
	local workspace = window:active_workspace()

	local color_scheme = window:effective_config().resolved_palette
	local bg = wezterm.color.parse(color_scheme.background):lighten(0.2)
	local fg = color_scheme.foreground

	local elements = {
		{ Foreground = { Color = fg } },
		{ Background = { Color = bg } },
		{ Text = " " .. workspace .. " " },
	}

	window:set_right_status(wezterm.format(elements))
end)

wezterm.on("gui-startup", function(cmd)
	local sessions = require("sessions")
	local _, pane, window = wezterm.mux.spawn_window(cmd or {})
	sessions.select_workspace(window:gui_window(), pane, true)
end)

return config
