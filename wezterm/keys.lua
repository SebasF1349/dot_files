-- based on https://github.com/folke/dot/blob/master/config/wezterm/keys.lua
local wezterm = require("wezterm")
local act = wezterm.action
local sessions = require("sessions")
local ssh = require("ssh")
local utils = require("utils")

local M = {}

M.modWorkspace = "CTRL|ALT"
M.mod = "ALT"

---@param description string
---@param fn fun(window: table, line: string)
local function prompt(description, fn)
	return act.PromptInputLine({
		description = description,
		action = wezterm.action_callback(function(window, _, line)
			if line and #line > 0 then
				fn(window, line)
			end
		end),
	})
end

---@param n integer
local function switch_workspace_relative(n)
	return wezterm.action_callback(function(win, pane)
		if #wezterm.mux.get_workspace_names() > 1 then
			wezterm.GLOBAL.previous_workspace = win:active_workspace()
		end
		win:perform_action(act.SwitchWorkspaceRelative(n), pane)
	end)
end

function M.setup(config)
	config.disable_default_key_bindings = true
	config.keys = {
		-- Dumb workaround to make C-space work in nvim
		{ mods = "CTRL", key = " ", action = act.SendKey({ key = " ", mods = "CTRL" }) },
		-- Workspaces
		{ mods = M.modWorkspace, key = "s", action = wezterm.action_callback(sessions.save_state) },
		{
			mods = M.modWorkspace,
			key = "w",
			action = wezterm.action_callback(function(win, pane)
				sessions.select_workspace(win, pane)
			end),
		},
		{
			mods = M.modWorkspace,
			key = "q",
			action = wezterm.action_callback(function(win, _)
				local current = win:active_workspace()
				local workspace = wezterm.GLOBAL.previous_workspace
				wezterm.GLOBAL.previous_workspace = nil
				sessions.close_tabs(win:mux_window())
				if workspace and workspace ~= current and sessions.workspace_exists(workspace) then
					wezterm.mux.set_active_workspace(workspace)
				end
			end),
		},
		{ mods = M.modWorkspace, key = "k", action = switch_workspace_relative(1) },
		{ mods = M.modWorkspace, key = "j", action = switch_workspace_relative(-1) },
		{
			-- previous workspace, like vim's CTRL-6
			mods = M.mod,
			key = "6",
			action = wezterm.action_callback(function(win, _)
				local current = win:active_workspace()
				local workspace = wezterm.GLOBAL.previous_workspace
				if workspace and workspace ~= current and sessions.workspace_exists(workspace) then
					wezterm.GLOBAL.previous_workspace = current
					wezterm.mux.set_active_workspace(workspace)
				end
			end),
		},
		-- Tabs
		{
			mods = M.mod,
			key = "t",
			action = prompt("Enter name of new tab", function(window, line)
				local tab_name, domain = utils.get_domain(line)
				window:mux_window():spawn_tab({ domain = domain }):set_title(tab_name)
			end),
		},
		{ mods = M.mod, key = "T", action = act.SpawnTab("CurrentPaneDomain") },
		{
			mods = M.mod,
			key = "r",
			action = prompt("Enter new name for tab", function(window, line)
				window:active_tab():set_title(line)
			end),
		},
		{ mods = M.mod, key = "Q", action = act.CloseCurrentTab({ confirm = false }) },
		{ mods = M.mod, key = "S", action = wezterm.action_callback(ssh.select_ssh) },
		{ mods = M.mod, key = "=", action = act.MoveTabRelative(1) },
		{ mods = M.mod, key = "-", action = act.MoveTabRelative(-1) },
		{ mods = M.mod, key = "n", action = act.ActivateTabRelative(1) },
		{ mods = M.mod, key = "p", action = act.ActivateTabRelative(-1) },
		-- Clipboard
		{ mods = M.mod, key = "Y", action = act.CopyTo("Clipboard") },
		{ mods = M.mod, key = "P", action = act.PasteFrom("Clipboard") },
		{ mods = M.mod, key = "V", action = act.ActivateCopyMode },
		-- Search
		{ mods = M.mod, key = "f", action = act.Search("CurrentSelectionOrEmptyString") },
		{ mods = M.mod, key = "F", action = act.QuickSelect },
		{
			mods = M.mod,
			key = "u",
			action = act.QuickSelectArgs({
				label = "open url",
				-- stop at quotes/brackets and drop trailing punctuation
				patterns = { "https?://[^\\s\"'<>()\\[\\]]*[^\\s\"'<>()\\[\\].,;:!?]" },
				action = wezterm.action_callback(function(window, pane)
					wezterm.open_with(window:get_selection_text_for_pane(pane))
				end),
			}),
		},
		-- Splits
		{ mods = M.mod, key = "Enter", action = M.smart_split },
		{ mods = M.mod, key = "v", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
		{ mods = M.mod, key = "s", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
		{ mods = M.mod, key = "q", action = act.CloseCurrentPane({ confirm = false }) },
		{ mods = M.mod, key = "R", action = act.RotatePanes("Clockwise") },
		{ mods = M.mod, key = "z", action = act.TogglePaneZoomState },
		M.split_nav("resize", "ALT|SHIFT", "<", "Left"),
		M.split_nav("resize", "ALT|SHIFT", ">", "Right"),
		M.split_nav("resize", "ALT", ",", "Up"),
		M.split_nav("resize", "ALT", ".", "Down"),
		M.split_nav("move", "ALT", "h", "Left"),
		M.split_nav("move", "ALT", "j", "Down"),
		M.split_nav("move", "ALT", "k", "Up"),
		M.split_nav("move", "ALT", "l", "Right"),
		-- Scrollback (CTRL-u / CTRL-d half-page scrolling comes from the default copy_mode table)
		{ mods = M.mod, key = "[", action = act.ScrollToPrompt(-1) },
		{ mods = M.mod, key = "]", action = act.ScrollToPrompt(1) },
	}
	for i = 1, 4 do
		table.insert(config.keys, { mods = M.mod, key = tostring(i), action = act.ActivateTab(i - 1) })
	end

	local default_tables = wezterm.gui and wezterm.gui.default_key_tables() or {}
	local copy_mode = default_tables.copy_mode or {}
	local search_mode = default_tables.search_mode or {}
	local shared_mappings = {
		{
			key = "y",
			mods = M.mod,
			action = act.Multiple({
				act.CopyTo("PrimarySelection"),
				act.ClearSelection,
				act.CopyMode("ClearSelectionMode"),
				act.CopyMode("ClearPattern"),
			}),
		},
		{
			key = "Escape",
			mods = "NONE",
			action = act.Multiple({
				act.CopyMode("ClearSelectionMode"),
				act.CopyMode("ClearPattern"),
				act.CopyMode("Close"),
			}),
		},
	}
	for _, mapping in ipairs(shared_mappings) do
		table.insert(copy_mode, mapping)
		table.insert(search_mode, mapping)
	end
	config.key_tables = { copy_mode = copy_mode, search_mode = search_mode }
end

M.smart_split = wezterm.action_callback(function(window, pane)
	local dim = pane:get_dimensions()
	local split = dim.pixel_height > dim.pixel_width and act.SplitVertical or act.SplitHorizontal
	window:perform_action(split({ domain = "CurrentPaneDomain" }), pane)
end)

function M.split_nav(resize_or_move, mods, key, dir)
	local event = "SplitNav_" .. resize_or_move .. "_" .. dir
	wezterm.on(event, function(win, pane)
		if utils.is_nvim(pane) then
			-- pass the keys through to vim/nvim
			return win:perform_action({ SendKey = { key = key, mods = mods } }, pane)
		end
		if resize_or_move == "resize" then
			return win:perform_action({ AdjustPaneSize = { dir, 3 } }, pane)
		end
		local is_zoomed = false
		for _, p in ipairs(pane:tab():panes_with_info()) do
			is_zoomed = is_zoomed or p.is_zoomed
		end
		-- don't reassign `dir`: it's an upvalue shared by every press of this key
		local target = dir
		if is_zoomed then
			target = (dir == "Up" or dir == "Right") and "Next" or "Prev"
		end
		win:perform_action({ ActivatePaneDirection = target }, pane)
		win:perform_action({ SetPaneZoomState = is_zoomed }, pane)
	end)
	return { key = key, mods = mods, action = act.EmitEvent(event) }
end

return M
