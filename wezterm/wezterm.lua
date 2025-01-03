local wezterm = require("wezterm")

local config = {}

if wezterm.config_builder then
	config = wezterm.config_builder()
end

require("keys").setup(config)

config.color_scheme = "Catppuccin Mocha"

if wezterm.target_triple == "x86_64-pc-windows-msvc" then
	local has_wsl, _, res = pcall(wezterm.run_child_process, { "wsl", "--version" })
	local start = "WSL version"
	if has_wsl and res:gsub("\0", ""):sub(1, #start) == start then
		config.default_prog = { "wsl.exe", "--cd", "~" }
	else
		config.default_prog = { "pwsh.exe" }
		config.default_cwd = "D:\\Trabajos\\Proyectos - Dev"
	end
	-- config.window_decorations = "RESIZE" -- it breaks wezterm in hyprland -- wait for wayland wez rewrite
	-- local background_image = "\\\\wsl$\\Ubuntu\\home\\sebasf\\dot_files\\wallpaper\\wallpaper_clean_mini.jpeg"
	local background_image = ".\\wallpaper_clean_mini.jpeg"
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
config.hide_tab_bar_if_only_one_tab = true
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

return config
