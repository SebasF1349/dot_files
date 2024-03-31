-- based on https://github.com/folke/dot/blob/master/config/wezterm/keys.lua
local wezterm = require("wezterm")
local act = wezterm.action

local utils = require("utils")

local M = {}

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
		-- New Tab --
		{ mods = M.modTab, key = "t", action = act.SpawnTab("CurrentPaneDomain") },
		-- Move Tabs
		{ mods = M.modTab .. "|CTRL", key = "l", action = act.MoveTabRelative(1) },
		{ mods = M.modTab .. "|CTRL", key = "h", action = act.MoveTabRelative(-1) },
		-- Acivate Tabs
		{ mods = M.modTab, key = "l", action = act({ ActivateTabRelative = 1 }) },
		{ mods = M.modTab, key = "h", action = act({ ActivateTabRelative = -1 }) },
		{ mods = M.modTab, key = "1", action = act.ActivateTab(0) },
		{ mods = M.modTab, key = "2", action = act.ActivateTab(1) },
		{ mods = M.modTab, key = "3", action = act.ActivateTab(2) },
		{ mods = M.modTab, key = "4", action = act.ActivateTab(3) },
		-- NOTE: worth making clipboard work with nvim keys too?
		-- Clipboard
		{ mods = M.modSplit, key = "C", action = act.CopyTo("Clipboard") },
		{ mods = M.modSplit, key = "V", action = act.PasteFrom("Clipboard") },
		-- { mods = M.mod, key = "Space", action = act.QuickSelect },
		-- { mods = M.mod, key = "X", action = act.ActivateCopyMode },
		-- { mods = M.mod, key = "f", action = act.Search("CurrentSelectionOrEmptyString") },
		-- { mods = M.mod, key = "p", action = act.ActivateCommandPalette },
		-- { mods = M.mod, key = "d", action = act.ShowDebugOverlay },
		-- Splits
		{ mods = M.modSplit, key = "Enter", action = M.smart_split },
		{ mods = M.modSplit, key = "|", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
		{ mods = M.modSplit, key = "_", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
		{ mods = M.modSplit, key = "q", action = act.CloseCurrentPane({ confirm = false }) },
		{ mods = M.modSplit, key = "S", action = wezterm.action.PaneSelect({ mode = "SwapWithActive" }) },
		{ mods = M.modSplit, key = "R", action = wezterm.action.RotatePanes("Clockwise") },
		{ mods = M.modSplit, key = "z", action = wezterm.action.TogglePaneZoomState },
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
				wezterm.log_info("is_zoomed: " .. tostring(is_zoomed))
				if is_zoomed then
					dir = dir == "Up" or dir == "Right" and "Next" or "Prev"
					wezterm.log_info("dir: " .. dir)
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
