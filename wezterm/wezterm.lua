local wezterm = require("wezterm")
local utils = require("utils")
local ssh = require("ssh")

local config = wezterm.config_builder and wezterm.config_builder() or {}

require("keys").setup(config)

local local_scheme, ssh_scheme = "Catppuccin Mocha Custom", "Catppuccin Frappe Custom"
config.color_scheme = local_scheme
config.font = wezterm.font("JetBrainsMono Nerd Font")
config.check_for_updates = false
config.enable_kitty_keyboard = true
config.scrollback_lines = 20000
if ssh.is_ssh_process then
	config.default_workspace = "SSH"
end

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
--- "Catppuccin Mocha Custom" is loaded from colors/catppuccin-mocha-custom.toml
---@param name string
---@return table
local function load_scheme(name)
	if not scheme_cache[name] then
		local file = name:lower():gsub(" ", "-")
		scheme_cache[name] = wezterm.color.load_scheme(wezterm.config_dir .. "/colors/" .. file .. ".toml")
	end
	return scheme_cache[name]
end

if utils.is_windows() then
	config.default_prog = { "pwsh", "-NoLogo", "-ExecutionPolicy", "RemoteSigned", "-NoProfileLoadTime" }
	config.window_decorations = "RESIZE"
	config.background = {
		{
			source = { File = wezterm.executable_dir .. "\\wallpaper_clean_mini.jpeg" },
			horizontal_align = "Center",
			vertical_align = "Middle",
		},
		{ source = { Color = load_scheme(local_scheme).background }, height = "100%", width = "100%", opacity = 0.7 },
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

	local host = domain:match("^SSH:(.+)$")
	local tab = pane:tab()
	if host and tab and tab:get_title() == "" then
		tab:set_title(host)
		window:focus()
	end

	local overrides = window:get_config_overrides() or {}
	local wanted_scheme = is_ssh and ssh_scheme or nil
	if overrides.color_scheme ~= wanted_scheme then
		overrides.color_scheme = wanted_scheme
		overrides.background = is_ssh and {} or nil
		window:set_config_overrides(overrides)
	end

	local scheme = load_scheme(is_ssh and ssh_scheme or local_scheme)
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
	if ssh.is_ssh_process then
		return "SSH"
	end
	local ok, win = pcall(wezterm.mux.get_window, tab.window_id)
	return ok and win and win:get_workspace() or tab.active_pane.title
end)

wezterm.on("gui-startup", function(cmd)
	if ssh.is_ssh_process then
		return -- spawn nothing: wezterm's default startup honours `--domain SSH:<host>`
	end
	local _, pane, window = wezterm.mux.spawn_window(cmd or {})
	if not cmd and not pane:get_domain_name():find("SSH") then
		require("sessions").select_workspace(window:gui_window(), pane, true)
	end
end)

return config
