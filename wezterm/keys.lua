-- based on https://github.com/folke/dot/blob/master/config/wezterm/keys.lua
local wezterm = require("wezterm")
local act = wezterm.action
local sessions = require("sessions")
local ssh = require("ssh")
local utils = require("utils")

local M = {}

M.modWorkspace = "CTRL|ALT"
M.mod = "ALT"

function M.setup(config)
	config.disable_default_key_bindings = true
	config.keys = {
		-- Dumb workaround to make C-space work in nvim
		{
			key = " ",
			mods = "CTRL",
			action = act.SendKey({
				key = " ",
				mods = "CTRL",
			}),
		},
		-- Workspaces
		{
			mods = M.modWorkspace,
			key = "s",
			action = wezterm.action_callback(function(_, _)
				sessions.save_state()
			end),
		},
		{
			mods = M.modWorkspace,
			key = "w",
			action = wezterm.action_callback(function(win, pane)
				wezterm.GLOBAL.previous_workspace = win:active_workspace()
				sessions.select_workspace(win, pane)
			end),
		},
		{
			mods = M.modWorkspace,
			key = "q",
			action = wezterm.action_callback(function(win, _)
				sessions.close_all_tabs(win:mux_window())
				local workspace = wezterm.GLOBAL.previous_workspace
				if not workspace then
					return
				end
				wezterm.mux.set_active_workspace(workspace)
			end),
		},
		{
			mods = M.modWorkspace,
			key = "k",
			action = wezterm.action_callback(function(win, pane)
				wezterm.GLOBAL.previous_workspace = win:active_workspace()
				win:perform_action(act.SwitchWorkspaceRelative(1), pane)
			end),
		},
		{
			mods = M.modWorkspace,
			key = "j",
			action = wezterm.action_callback(function(win, pane)
				wezterm.GLOBAL.previous_workspace = win:active_workspace()
				win:perform_action(act.SwitchWorkspaceRelative(-1), pane)
			end),
		},
		{
			mods = M.modWorkspace,
			key = "3", -- #
			action = wezterm.action_callback(function(win, _)
				local workspace = wezterm.GLOBAL.previous_workspace
				if not workspace then
					return
				end
				wezterm.GLOBAL.previous_workspace = win:active_workspace()
				wezterm.mux.set_active_workspace(workspace)
			end),
		},
		-- New Tab
		{
			mods = M.mod,
			key = "t",
			action = act.PromptInputLine({
				description = "Enter name of new tab",
				action = wezterm.action_callback(function(window, _, line)
					if line and #line > 0 then
						local tab_name, domain = utils.get_domain(line)
						local tab, _, _ = window:mux_window():spawn_tab({ domain = domain })
						tab:set_title(tab_name)
					end
				end),
			}),
		},
		{ mods = M.mod, key = "T", action = act.SpawnTab("CurrentPaneDomain") },
		{
			mods = M.mod,
			key = "r",
			action = act.PromptInputLine({
				description = "Enter new name for tab",
				action = wezterm.action_callback(function(window, _, line)
					if line and #line > 0 then
						window:active_tab():set_title(line)
					end
				end),
			}),
		},
		{ mods = M.mod, key = "Q", action = act.CloseCurrentTab({ confirm = false }) },
		{
			mods = M.mod,
			key = "S",
			action = wezterm.action_callback(function(win, pane)
				ssh.select_ssh(win, pane)
			end),
		},
		-- Move Tabs
		{ mods = M.mod, key = "=", action = act.MoveTabRelative(1) },
		{ mods = M.mod, key = "-", action = act.MoveTabRelative(-1) },
		-- Acivate Tabs
		{ mods = M.mod, key = "n", action = act.ActivateTabRelative(1) },
		{ mods = M.mod, key = "p", action = act.ActivateTabRelative(-1) },
		{ mods = M.mod, key = "1", action = act.ActivateTab(0) },
		{ mods = M.mod, key = "2", action = act.ActivateTab(1) },
		{ mods = M.mod, key = "3", action = act.ActivateTab(2) },
		{ mods = M.mod, key = "4", action = act.ActivateTab(3) },
		-- Clipboard
		{ mods = M.mod, key = "Y", action = act.CopyTo("Clipboard") },
		{ mods = M.mod, key = "P", action = act.PasteFrom("Clipboard") },
		{ mods = M.mod, key = "V", action = act.ActivateCopyMode },
		-- Search
		{ mods = M.mod, key = "f", action = act.Search("CurrentSelectionOrEmptyString") },
		{ mods = M.mod, key = "F", action = act.QuickSelect },
		{
			key = "u",
			mods = M.mod,
			action = wezterm.action.QuickSelectArgs({
				label = "open url",
				patterns = {
					"https?://\\S+",
				},
				skip_action_on_paste = true,
				action = wezterm.action_callback(function(window, pane)
					local url = window:get_selection_text_for_pane(pane)
					wezterm.open_with(url)
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
		-- Scrollback
		M.scroll("CTRL", "u", "Up"),
		M.scroll("CTRL", "d", "Down"),
		{ mods = M.mod, key = "[", action = act.ScrollToPrompt(-1) },
		{ mods = M.mod, key = "]", action = act.ScrollToPrompt(1) },
	}

	local copy_mode = {}
	local search_mode = {}
	if wezterm.gui then
		local default_tables = wezterm.gui.default_key_tables()
		copy_mode = default_tables.copy_mode
		search_mode = default_tables.search_mode
	end

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

	config.key_tables = {
		copy_mode = copy_mode,
		search_mode = search_mode,
	}
end

M.smart_split = wezterm.action_callback(function(window, pane)
	local dim = pane:get_dimensions()
	if dim.pixel_height > dim.pixel_width then
		window:perform_action(act.SplitVertical({ domain = "CurrentPaneDomain" }), pane)
	else
		window:perform_action(act.SplitHorizontal({ domain = "CurrentPaneDomain" }), pane)
	end
end)

function M.scroll(mods, key, dir)
	local event = "Scroll_" .. dir
	wezterm.on(event, function(win, pane)
		if utils.is_nvim(pane) then
			-- pass the keys through to vim/nvim
			win:perform_action({ SendKey = { key = key, mods = mods } }, pane)
		elseif dir == "Up" then
			win:perform_action({ ScrollByPage = -0.5 }, pane)
		else
			win:perform_action({ ScrollByPage = 0.5 }, pane)
		end
	end)
	return {
		key = key,
		mods = mods,
		action = wezterm.action.EmitEvent(event),
	}
end

function M.split_nav(resize_or_move, mods, key, dir)
	local event = "SplitNav_" .. resize_or_move .. "_" .. dir
	wezterm.on(event, function(win, pane)
		if utils.is_nvim(pane) then
			-- pass the keys through to vim/nvim
			win:perform_action({ SendKey = { key = key, mods = mods } }, pane)
		else
			if resize_or_move == "resize" then
				win:perform_action({ AdjustPaneSize = { dir, 3 } }, pane)
			else
				local panes = pane:tab():panes_with_info()
				local is_zoomed = false
				for _, p in ipairs(panes) do
					if p.is_zoomed then
						is_zoomed = true
						break
					end
				end
				if is_zoomed then
					dir = (dir == "Up" or dir == "Right") and "Next" or "Prev"
				end
				win:perform_action({ ActivatePaneDirection = dir }, pane)
				win:perform_action({ SetPaneZoomState = is_zoomed }, pane)
			end
		end
	end)
	return {
		key = key,
		mods = mods,
		action = wezterm.action.EmitEvent(event),
	}
end

return M
