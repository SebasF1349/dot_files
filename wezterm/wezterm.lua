local wezterm = require("wezterm")

local utils = require("utils")

local config = {}

if wezterm.config_builder then
	config = wezterm.config_builder()
end

require("keys").setup(config)
require("tabs").setup(config)

config.color_scheme = "Catppuccin Mocha"

if wezterm.target_triple == "x86_64-pc-windows-msvc" then
	--This next line should be the only thing that's needed, but it doesn't work for new panes
	--config.default_domain = 'WSL:Ubuntu'
	config.default_cwd = "\\\\wsl$\\Ubuntu\\home\\sebasf\\repos"
	config.default_prog = { "wsl.exe", "--cd", "~/repos" }
	config.window_decorations = "RESIZE" -- it breaks wezterm in hyprland -- wait for wayland wez rewrite
	local background_image = "\\\\wsl$\\Ubuntu\\home\\sebasf\\dot_files\\wallpaper\\wallpaper_clean.jpg"
	local scheme = wezterm.get_builtin_color_schemes()["Catppuccin Mocha"]
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
	wezterm.on("gui-startup", function(cmd)
		local _, _, window = wezterm.mux.spawn_window(cmd or {})
		window:gui_window():maximize()
	end)
elseif wezterm.target_triple == "x86_64-unknown-linux-gnu" then
	config.window_background_opacity = 0.9
end

--config.adjust_window_size_when_changing_font_size = false
config.font = wezterm.font("JetBrainsMono Nerd Font")
config.hide_tab_bar_if_only_one_tab = true
config.inactive_pane_hsb = {
	saturation = 1,
	brightness = 0.5,
}

config.enable_scroll_bar = false

config.window_close_confirmation = "NeverPrompt"

-- config.front_end = "WebGpu"
-- config.webgpu_power_preference = "HighPerformance"
-- config.animation_fps = 1
config.cursor_blink_ease_in = "Constant"
config.cursor_blink_ease_out = "Constant"

config.check_for_updates = false

config.window_padding = { left = "1cell", right = "1cell", top = "0.5cell", bottom = "0.5cell" }

local function recompute_padding(window, is_nvim)
	local overrides = window:get_config_overrides() or {}
	local new_padding = {}
	if is_nvim then
		new_padding = { left = 0, right = 0, top = 0, bottom = 0 }
	else
		new_padding = { left = "1cell", right = "1cell", top = "0.5cell", bottom = "0.5cell" }
	end
	if not overrides.window_padding or overrides.window_padding.left ~= new_padding.left then
		overrides.window_padding = new_padding
		window:set_config_overrides(overrides)
	end
end

wezterm.on("update-status", function(window, pane)
	recompute_padding(window, utils.is_nvim(pane))
end)

config.enable_wayland = false

return config
