-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
	config = wezterm.config_builder()
end

require("keys").setup(config)
require("tabs").setup(config)

--wezterm.on('gui-startup', function(cmd)
--  local tab, pane, window = wezterm.mux.spawn_window(cmd or {})
--window:gui_window():maximize()
--end)

-- This is where you actually apply your config choices

config.color_scheme = "Catppuccin Mocha"

if wezterm.target_triple == "x86_64-pc-windows-msvc" then
	--This next line should be the only thing that's needed, but it doesn't work for new panes
	--config.default_domain = 'WSL:Ubuntu'
	config.default_cwd = "\\\\wsl$\\Ubuntu\\home\\sebasf\\repos"
	config.default_prog = { "wsl.exe", "--cd", "~/repos" }
elseif wezterm.target_triple == "x86_64-unknown-linux-gnu" then
	--Let open in home or in current directory, it works on linux, not in wsl
	--config.default_prog = { '/bin/bash', '-l' }
	--config.default_cwd = './~'
end

config.adjust_window_size_when_changing_font_size = false
config.hide_tab_bar_if_only_one_tab = true
config.inactive_pane_hsb = {
	saturation = 1,
	brightness = 0.5,
}

config.enable_scroll_bar = false

config.window_background_opacity = 0.9

config.window_close_confirmation = "NeverPrompt"

config.front_end = "WebGpu"
-- config.webgpu_power_preference = "HighPerformance"
-- config.animation_fps = 1
config.cursor_blink_ease_in = "Constant"
config.cursor_blink_ease_out = "Constant"

config.check_for_updates = false

config.window_padding = { left = "1cell", right = "1cell", top = "0.5cell", bottom = "0.5cell" }

local function recompute_padding(window, is_nvim)
	local overrides = window:get_config_overrides() or {}
	local new_padding = {}
	if is_nvim == "true" then
		new_padding = { left = 0, right = 0, top = 0, bottom = 0 }
	else
		new_padding = { left = "1cell", right = "1cell", top = "0.5cell", bottom = "0.5cell" }
	end
	if not overrides.window_padding or overrides.window_padding.left ~= new_padding.left then
		overrides.window_padding = new_padding
		window:set_config_overrides(overrides)
	end
end

wezterm.on("user-var-changed", function(window, _, name, value)
	if name ~= "IS_NVIM" then
		return
	end
	recompute_padding(window, value)
end)

local function recompute_font_size(window)
	window:toast_notification("test", 12)
	local window_dims = window:get_dimensions()
	local overrides = window:get_config_overrides() or {}
	local font_pixel_size = overrides.font_size * window_dims.dpi / 72
	local number_rows = math.floor(window_dims / font_pixel_size)
	local rest = window_dims % font_pixel_size
	local new_pixel_font_size = font_pixel_size + rest / number_rows
	local new_font_size = new_pixel_font_size * 72 / window_dims.dpi
	overrides.font_size = new_font_size
	window:set_config_overrides(overrides)
	-- if not window_dims.is_full_screen then
	-- 	if not overrides.window_padding then
	-- 		-- not changing anything
	-- 		return
	-- 	end
	-- 	overrides.window_padding = nil
	-- else
	-- 	-- Use only the middle 33%
	-- 	local third = math.floor(window_dims.pixel_width / 3)
	-- 	local new_padding = {
	-- 		left = third,
	-- 		right = third,
	-- 		top = 0,
	-- 		bottom = 0,
	-- 	}
	-- 	if overrides.window_padding and new_padding.left == overrides.window_padding.left then
	-- 		-- padding is same, avoid triggering further changes
	-- 		return
	-- 	end
	-- 	overrides.window_padding = new_padding
	-- end
end

wezterm.on("window-resized", function(window)
	recompute_font_size(window)
end)

wezterm.on("window-config-reloaded", function(window)
	recompute_font_size(window)
end)
-- config.underline_thickness = 3
-- config.cursor_thickness = 4
-- config.underline_position = -6

-- if wezterm.target_triple:find("windows") then
--   --config.default_prog = { "pwsh" }
--   config.window_decorations = "RESIZE|TITLE"
--   wezterm.on("gui-startup", function(cmd)
--     local screen = wezterm.gui.screens().active
--     local tab, pane, window = wezterm.mux.spawn_window(cmd or {})
--     local gui = window:gui_window()
--     local width = 0.7 * screen.width
--     local height = 0.7 * screen.height
--     gui:set_inner_size(width, height)
--     gui:set_position((screen.width - width) / 2, (screen.height - height) / 2)
--   end)
-- else
--   config.term = "wezterm"
--   config.window_decorations = "RESIZE"
-- end

return config
