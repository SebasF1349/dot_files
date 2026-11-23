local wezterm = require("wezterm")
local act = wezterm.action
local cb = wezterm.action_callback
local sessions = require("sessions")
local ssh = require("ssh")
local utils = require("utils")

local M = {}

local mod, mod_ws = "ALT", "CTRL|ALT"

---@param window table
---@param pane table
local function copy_last_output(window, pane)
	local zones = pane:get_semantic_zones("Output")
	for i = #zones, 1, -1 do
		local text = pane:get_text_from_semantic_zone(zones[i]):gsub("%s+$", "")
		if #text > 0 then
			window:copy_to_clipboard(text, "Clipboard")
			local lines = select(2, text:gsub("\n", "")) + 1
			return window:toast_notification("WezTerm", "Copied " .. lines .. " line(s) of output", nil, 2500)
		end
	end
	window:toast_notification("WezTerm", "No command output found (is shell integration on?)", nil, 2500)
end

---@param window table
---@param pane table
local function open_in_nvim(window, pane)
	local file, line, col = window:get_selection_text_for_pane(pane):match("^(.-):(%d+):?(%d*)$")
	if not file then
		return
	end
	local cursor = ("cursor(%s, %s)"):format(line, col ~= "" and col or 1)
	local cwd = utils.pane_cwd(pane)
	if file:sub(1, 1) == "~" then
		file = wezterm.home_dir .. file:sub(2)
	elseif cwd and not (file:match("^/") or file:match("^%a:[/\\]")) then
		file = cwd .. "/" .. file
	end
	for _, p in ipairs(pane:tab():panes()) do
		if utils.is_nvim(p) then
			p:activate()
			-- <C-\><C-n> leaves insert/terminal mode
			return p:send_text(("\x1c\x0e:e %s | call %s\r"):format(file:gsub("([ %%#|])", "\\%1"), cursor))
		end
	end
	local dim = pane:get_dimensions()
	local direction = dim.pixel_height > dim.pixel_width and "Bottom" or "Right"
	pane:split({ direction = direction, args = { "nvim", "+call " .. cursor, file }, cwd = cwd })
end

---@param n integer
local function switch_workspace_relative(n)
	return cb(function(win, pane)
		if #wezterm.mux.get_workspace_names() > 1 then
			wezterm.GLOBAL.previous_workspace = win:active_workspace()
		end
		win:perform_action(act.SwitchWorkspaceRelative(n), pane)
	end)
end

local smart_split = cb(function(window, pane)
	local dim = pane:get_dimensions()
	local split = dim.pixel_height > dim.pixel_width and act.SplitVertical or act.SplitHorizontal
	window:perform_action(split({ domain = "CurrentPaneDomain" }), pane)
end)

---@param resize_or_move "resize"|"move"
---@param mods string
---@param key string
---@param dir "Left"|"Right"|"Up"|"Down"
local function split_nav(resize_or_move, mods, key, dir)
	local event = "SplitNav_" .. resize_or_move .. "_" .. dir
	wezterm.on(event, function(win, pane)
		if utils.is_nvim(pane) then
			return win:perform_action(act.SendKey({ key = key, mods = mods }), pane)
		end
		if resize_or_move == "resize" then
			return win:perform_action(act.AdjustPaneSize({ dir, 3 }), pane)
		end
		local is_zoomed = false
		for _, p in ipairs(pane:tab():panes_with_info()) do
			is_zoomed = is_zoomed or p.is_zoomed
		end
		local target = is_zoomed and ((dir == "Up" or dir == "Right") and "Next" or "Prev") or dir
		win:perform_action(act.ActivatePaneDirection(target), pane)
		win:perform_action(act.SetPaneZoomState(is_zoomed), pane)
	end)
	return { key = key, mods = mods, action = act.EmitEvent(event) }
end

function M.setup(config)
	config.disable_default_key_bindings = true
	config.keys = {
		-- workaround to make C-space work in nvim
		{ mods = "CTRL", key = " ", action = act.SendKey({ key = " ", mods = "CTRL" }) },
		{ mods = mod_ws, key = "s", action = cb(sessions.save_state) },
		{ mods = mod_ws, key = "w", action = cb(sessions.select_workspace) },
		{ mods = mod_ws, key = "q", action = cb(sessions.close_workspace) },
		{ mods = mod_ws, key = "k", action = switch_workspace_relative(1) },
		{ mods = mod_ws, key = "j", action = switch_workspace_relative(-1) },
		{ mods = mod, key = "6", action = cb(sessions.switch_to_previous) },
		{
			mods = mod,
			key = "t",
			action = utils.prompt("Enter name of new tab", function(window, line)
				local tab_name, domain = utils.get_domain(line)
				window:mux_window():spawn_tab({ domain = domain }):set_title(tab_name)
			end),
		},
		{ mods = mod, key = "T", action = act.SpawnTab("CurrentPaneDomain") },
		{
			mods = mod,
			key = "r",
			action = utils.prompt("Enter new name for tab", function(window, line)
				window:active_tab():set_title(line)
			end),
		},
		{ mods = mod, key = "Q", action = act.CloseCurrentTab({ confirm = false }) },
		{ mods = mod, key = "S", action = cb(ssh.select_ssh) },
		{ mods = mod, key = "=", action = act.MoveTabRelative(1) },
		{ mods = mod, key = "-", action = act.MoveTabRelative(-1) },
		{ mods = mod, key = "n", action = act.ActivateTabRelative(1) },
		{ mods = mod, key = "p", action = act.ActivateTabRelative(-1) },
		{ mods = mod, key = "Y", action = act.CopyTo("Clipboard") },
		{ mods = mod, key = "P", action = act.PasteFrom("Clipboard") },
		{ mods = mod, key = "V", action = act.ActivateCopyMode },
		{ mods = mod, key = "O", action = cb(copy_last_output) },
		{ mods = mod, key = "f", action = act.Search("CurrentSelectionOrEmptyString") },
		{ mods = mod, key = "F", action = act.QuickSelect },
		{
			mods = mod,
			key = "u",
			action = act.QuickSelectArgs({
				label = "open url",
				-- stops at quotes/brackets and drops trailing punctuation
				patterns = { "https?://[^\\s\"'<>()\\[\\]]*[^\\s\"'<>()\\[\\].,;:!?]" },
				action = cb(function(window, pane)
					wezterm.open_with(window:get_selection_text_for_pane(pane))
				end),
			}),
		},
		{
			mods = mod,
			key = "e",
			action = act.QuickSelectArgs({
				label = "open in nvim",
				-- requires an extension so times like 12:30 don't match
				patterns = { "[\\w./~-]*\\.\\w+:\\d+(?::\\d+)?" },
				action = cb(open_in_nvim),
			}),
		},
		{ mods = mod, key = "Enter", action = smart_split },
		{ mods = mod, key = "v", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
		{ mods = mod, key = "s", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
		{ mods = mod, key = "q", action = act.CloseCurrentPane({ confirm = false }) },
		{ mods = mod, key = "R", action = act.RotatePanes("Clockwise") },
		{ mods = mod, key = "z", action = act.TogglePaneZoomState },
		split_nav("resize", "ALT|SHIFT", "<", "Left"),
		split_nav("resize", "ALT|SHIFT", ">", "Right"),
		split_nav("resize", "ALT", ",", "Up"),
		split_nav("resize", "ALT", ".", "Down"),
		split_nav("move", "ALT", "h", "Left"),
		split_nav("move", "ALT", "j", "Down"),
		split_nav("move", "ALT", "k", "Up"),
		split_nav("move", "ALT", "l", "Right"),
		{ mods = mod, key = "[", action = act.ScrollToPrompt(-1) },
		{ mods = mod, key = "]", action = act.ScrollToPrompt(1) },
	}
	for i = 1, 4 do
		table.insert(config.keys, { mods = mod, key = tostring(i), action = act.ActivateTab(i - 1) })
	end

	local defaults = wezterm.gui and wezterm.gui.default_key_tables() or {}
	config.key_tables = { copy_mode = defaults.copy_mode or {}, search_mode = defaults.search_mode or {} }
	local clear = { act.CopyMode("ClearSelectionMode"), act.CopyMode("ClearPattern") }
	for _, tbl in pairs(config.key_tables) do
		table.insert(tbl, {
			mods = mod,
			key = "y",
			action = act.Multiple({ act.CopyTo("PrimarySelection"), act.ClearSelection, clear[1], clear[2] }),
		})
		table.insert(tbl, { mods = "NONE", key = "Escape", action = act.Multiple({ clear[1], clear[2], act.CopyMode("Close") }) })
	end
end

return M
