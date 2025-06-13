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
	end
	config.default_prog = { "pwsh", "-NoLogo", "-ExecutionPolicy", "RemoteSigned", "-NoProfileLoadTime" }
	config.window_decorations = "RESIZE" -- it breaks wezterm in hyprland and my windows notebook?
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

wezterm.on("update-status", function(window, pane)
	local domain = pane:get_domain_name()
	if domain:find("SSH") then
		wezterm.mux.rename_workspace(wezterm.mux.get_active_workspace(), domain)

		local overrides = window:get_config_overrides() or {}
		overrides.color_scheme = "Catppuccin Frappe"
		overrides.background = {}
		window:set_config_overrides(overrides)
	end

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

wezterm.on("format-window-title", function(tab, pane, tabs, panes, config)
	local muxtab = wezterm.mux.get_tab(tab.tab_id)
    local muxwin = muxtab:window()
	return muxwin:get_workspace()
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
