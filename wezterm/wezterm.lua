local wezterm = require("wezterm")
local utils = require("utils")

local config = wezterm.config_builder and wezterm.config_builder() or {}

require("keys").setup(config)

config.color_scheme = "Catppuccin Mocha Custom"
local color_scheme_file = "catppuccin-mocha-custom"
local ssh_color_scheme = "Catppuccin Frappe Custom"
local ssh_color_scheme_file = "catppuccin-frappe-custom"
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

local scheme_cache = {}
local function load_scheme(file)
	if not scheme_cache[file] then
		scheme_cache[file] = wezterm.color.load_scheme(wezterm.config_dir .. "/colors/" .. file .. ".toml")
	end
	return scheme_cache[file]
end

if utils.is_windows() then
	config.default_prog = { "pwsh", "-NoLogo", "-ExecutionPolicy", "RemoteSigned", "-NoProfileLoadTime" }
	config.window_decorations = "RESIZE"
	local background_image = wezterm.executable_dir .. "\\wallpaper_clean_mini.jpeg"
	config.background = {
		{
			source = { File = background_image },
			horizontal_align = "Center",
			vertical_align = "Middle",
		},
		{
			source = { Color = load_scheme(color_scheme_file).background },
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
	local ok, domain = pcall(pane.get_domain_name, pane)
	if not ok or not domain then
		return
	end

	local process = (pane:get_foreground_process_name() or ""):match("([^/\\]+)$") or ""
	local is_ssh = domain:find("SSH") ~= nil or process:lower():gsub("%.exe$", "") == "ssh"
	local host = is_ssh and domain:match("to%s+(.+)$")
	if host and window:active_workspace() ~= host then
		wezterm.mux.rename_workspace(window:active_workspace(), host)
	end

	-- only touch the overrides when they change, this runs every status tick
	local overrides = window:get_config_overrides() or {}
	local wanted_scheme = is_ssh and ssh_color_scheme or nil
	if overrides.color_scheme ~= wanted_scheme then
		overrides.color_scheme = wanted_scheme
		overrides.background = is_ssh and {} or nil
		window:set_config_overrides(overrides)
	end

	local scheme = load_scheme(is_ssh and ssh_color_scheme_file or color_scheme_file)
	local mode = ({
		copy_mode = { icon = " 󰆏 ", color = scheme.ansi[7] },
		search_mode = { icon = " 󰍉 ", color = scheme.ansi[4] },
	})[window:active_key_table()] or { icon = " 󰌌 ", color = scheme.split }

	window:set_right_status(wezterm.format({
		{ Background = { Color = scheme.background } },
		{ Foreground = { Color = mode.color } },
		{ Text = mode.icon },
		{ Foreground = { Color = is_ssh and scheme.ansi[2] or scheme.split } },
		{ Text = " 󰒋 " },
		{ Background = { Color = wezterm.color.parse(scheme.background):lighten(0.2) } },
		{ Foreground = { Color = scheme.foreground } },
		{ Text = " " .. window:active_workspace() .. " " },
	}))
end)

wezterm.on("format-window-title", function(tab)
	local ok, win = pcall(wezterm.mux.get_window, tab.window_id)
	if ok and win then
		return win:get_workspace()
	end
	return tab.active_pane.title
end)

wezterm.on("gui-startup", function(cmd)
	local _, pane, window = wezterm.mux.spawn_window(cmd or {})
	if not pane:get_domain_name():find("SSH") and not cmd then
		local sessions = require("sessions")
		sessions.setup()
		sessions.select_workspace(window:gui_window(), pane, true)
	end
end)

return config
