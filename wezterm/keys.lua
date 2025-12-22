-- based on https://github.com/folke/dot/blob/master/config/wezterm/keys.lua
local wezterm = require("wezterm")
local act = wezterm.action
local sessions = require("sessions")
local ssh = require("ssh")
local utils = require("utils")

local M = {}

M.modWorkspace = "CTRL|ALT"
M.modSplit = "SHIFT|ALT"
M.modTab = "ALT"

M.smart_split = wezterm.action_callback(function(window, pane)
	local dim = pane:get_dimensions()
	if dim.pixel_height > dim.pixel_width then
		window:perform_action(act.SplitVertical({ domain = "CurrentPaneDomain" }), pane)
	else
		window:perform_action(act.SplitHorizontal({ domain = "CurrentPaneDomain" }), pane)
	end
end)

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
			key = "n",
			action = wezterm.action_callback(function(win, pane)
				wezterm.GLOBAL.previous_workspace = win:active_workspace()
				win:perform_action(act.SwitchWorkspaceRelative(1), pane)
			end),
		},
		{
			mods = M.modWorkspace,
			key = "p",
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
			mods = M.modTab,
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
		{ mods = M.modTab, key = "T", action = act.SpawnTab("CurrentPaneDomain") },
		{
			mods = M.modTab,
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
		{ mods = M.modTab, key = "q", action = act.CloseCurrentTab({ confirm = false }) },
		{
			mods = M.modTab,
			key = "s",
			action = wezterm.action_callback(function(win, pane)
				ssh.select_ssh(win, pane)
			end),
		},
		-- Move Tabs
		{ mods = M.modTab, key = ".", action = act.MoveTabRelative(1) },
		{ mods = M.modTab, key = ",", action = act.MoveTabRelative(-1) },
		-- Acivate Tabs
		{ mods = M.modTab, key = "n", action = act.ActivateTabRelative(1) },
		{ mods = M.modTab, key = "p", action = act.ActivateTabRelative(-1) },
		{ mods = M.modTab, key = "1", action = act.ActivateTab(0) },
		{ mods = M.modTab, key = "2", action = act.ActivateTab(1) },
		{ mods = M.modTab, key = "3", action = act.ActivateTab(2) },
		{ mods = M.modTab, key = "4", action = act.ActivateTab(3) },
		-- Clipboard
		{ mods = M.modTab, key = "c", action = act.CopyTo("Clipboard") },
		{ mods = M.modTab, key = "v", action = act.PasteFrom("Clipboard") },
		{ mods = M.modTab, key = "y", action = act.ActivateCopyMode },
		-- { mods = M.modTab, key = "s", action = act.QuickSelect },
		{ mods = M.modTab, key = "f", action = act.Search("CurrentSelectionOrEmptyString") },
		-- { mods = M.mod, key = "p", action = act.ActivateCommandPalette },
		-- { mods = M.mod, key = "d", action = act.ShowDebugOverlay },
		-- Splits
		{ mods = M.modSplit, key = "Enter", action = M.smart_split },
		{ mods = M.modSplit, key = "|", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
		{ mods = M.modSplit, key = "_", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
		{ mods = M.modSplit, key = "Q", action = act.CloseCurrentPane({ confirm = false }) },
		{ mods = M.modSplit, key = "S", action = act.PaneSelect({ mode = "SwapWithActive" }) },
		{ mods = M.modSplit, key = "R", action = act.RotatePanes("Clockwise") },
		{ mods = M.modSplit, key = "z", action = act.TogglePaneZoomState },
		M.split_nav("resize", "CTRL|SHIFT", "<", "Left"),
		M.split_nav("resize", "CTRL|SHIFT", ">", "Right"),
		M.split_nav("resize", "CTRL", ",", "Up"),
		M.split_nav("resize", "CTRL", ".", "Down"),
		M.split_nav("move", "CTRL", "h", "Left"),
		M.split_nav("move", "CTRL", "j", "Down"),
		M.split_nav("move", "CTRL", "k", "Up"),
		M.split_nav("move", "CTRL", "l", "Right"),
		-- Scrollback
		M.scroll("CTRL", "u", "Up"),
		M.scroll("CTRL", "d", "Down"),
	}
end

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
					end
				end
				if is_zoomed then
					dir = dir == "Up" or dir == "Right" and "Next" or "Prev"
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
