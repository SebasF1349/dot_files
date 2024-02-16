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

config.font = wezterm.font("JetBrainsMono Nerd Font")

config.window_close_confirmation = "NeverPrompt"

config.front_end = "WebGpu"
-- config.webgpu_power_preference = "HighPerformance"
-- config.animation_fps = 1
config.cursor_blink_ease_in = "Constant"
config.cursor_blink_ease_out = "Constant"

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
