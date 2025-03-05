local wezterm = require("wezterm")
local utils = require("utils")
local home_from_path = utils.is_windows() and "\\AppData\\Roaming\\wezterm\\workspaces\\" or "/.local/share/wezterm/"
local workspaces_dir = wezterm.home_dir .. home_from_path

local M = {}

-- Largely based on https://github.com/MLFlexer/resurrect.wezterm,
-- but resurrect doesn't work for me, has too many features
-- and doesn't even open the workspace (just loads window in current workspace)

--------------------------------------------------
-- Types
--------------------------------------------------

-- Wezterm stuff
---@alias MuxWindow table
---@alias MuxTab table
---@alias PaneInformation table
---@alias Window table
---@alias Pane table

---@alias workspace_state {name: string, window_state: window_state}
---@alias window_state {title: string, tabs: tab_state[]}
---@alias tab_state {title: string, pane: pane_state, is_active: boolean}
---@alias pane_state {left: integer, top: integer, height: integer, width: integer, cwd: string, domain: string, is_active: boolean, is_zoomed: boolean}

--------------------------------------------------
-- Setup
--------------------------------------------------

local function exists(file)
	local ok, err, code = os.rename(file, file)
	if not ok then
		if code == 13 then
			-- Permission denied, but it exists
			return true
		end
	end
	return ok, err
end

function M.setup()
	if not exists(workspaces_dir) then
		os.execute("mkdir " .. workspaces_dir)
	end
end

--------------------------------------------------
-- Json
--------------------------------------------------

---@param file_path string
---@param state workspace_state
local function write_json(file_path, state)
	local json_state = wezterm.json_encode(state)
	local ok, err = pcall(function()
		local file = assert(io.open(file_path, "w"))
		file:write(json_state)
		file:close()
	end)
	if not ok then
		wezterm.log_error("Failed to write state: " .. err)
	end
end

---@param file_path string
---@return workspace_state|nil
local function load_json(file_path)
	local json
	local lines = {}
	for line in io.lines(file_path) do
		table.insert(lines, line)
	end
	json = table.concat(lines)
	if not json then
		return nil
	end
	return wezterm.json_parse(json)
end

--------------------------------------------------
-- Utils
--------------------------------------------------

---@param workspace string
---@return MuxWindow
local function get_active_mux_window(workspace)
	for _, mux_win in ipairs(wezterm.mux.all_windows()) do
		if mux_win:get_workspace() == workspace then
			return mux_win
		end
	end
	return {}
end

---@param tab MuxTab
---@param mux_window MuxWindow
local function close_all_other_tabs(tab, mux_window)
	for _, t in ipairs(mux_window:tabs()) do
		if t:tab_id() ~= tab:tab_id() then
			t:activate()
			pcall(function()
				mux_window
					:gui_window()
					:perform_action(wezterm.action.CloseCurrentTab({ confirm = false }), mux_window:active_pane())
			end)
		end
	end
end

---@param mux_window MuxWindow
function M.close_all_tabs(mux_window)
	for _, t in ipairs(mux_window:tabs()) do
		t:activate()
		pcall(function()
			mux_window
				:gui_window()
				:perform_action(wezterm.action.CloseCurrentTab({ confirm = false }), mux_window:active_pane())
		end)
	end
end

---@return {id: string, label: string}
local function project_dirs()
	local projects = {}

	for _, dir in ipairs(wezterm.glob(workspaces_dir .. "/*")) do
		local file_name = dir:match("[^/]*.json$")
		file_name = file_name:sub(0, #file_name - 5)
		table.insert(projects, { id = dir, label = file_name })
	end

	return projects
end

---@param workspace string
local function update_previous_workspace(workspace)
	local current_workspace = wezterm.mux.get_active_workspace()
	if current_workspace == workspace then
		return
	end
	wezterm.GLOBAL.previous_workspace = current_workspace
end

--------------------------------------------------
-- Load or Create Workspace
--------------------------------------------------

---@param state workspace_state
---@param win MuxWindow
local function load_workspace(state, win)
	local tabs = state.window_state.tabs

	local tab_active
	for i, tab in ipairs(tabs) do
		local t, _, _ = win:spawn_tab({
			domain = { DomainName = tab.pane.domain },
			cwd = tab.pane.cwd,
		})
		if i == 1 then
			close_all_other_tabs(t, win)
		end
		t:set_title(tab.title)
		if tab.is_active then
			tab_active = t
		end
	end
	tab_active:activate()
end

---@param win Window
---@param pane Pane
---@param replace? boolean
local function new_workspace(win, pane, replace)
	win:perform_action(
		wezterm.action.PromptInputLine({
			description = "Enter name for new workspace",
			action = wezterm.action_callback(function(_, _, line)
				if not line then
					return
				end
				local workspace_name, domain = utils.get_domain(line)
				local tab_title = ""
				local tab
				if workspace_name:find(":") then
					local s = utils.split(workspace_name, ":")
					workspace_name = s[1]
					tab_title = s[2]
				end
				if replace then
					wezterm.mux.rename_workspace(wezterm.mux.get_active_workspace(), workspace_name)
					local mux_win = get_active_mux_window(workspace_name)
					local t, _, w = mux_win:spawn_tab({
						domain = domain,
					})
					close_all_other_tabs(t, w)
					tab = t
				else
					update_previous_workspace(workspace_name)
					tab, _, _ = wezterm.mux.spawn_window({
						workspace = workspace_name,
						domain = domain,
					})
				end
				wezterm.mux.set_active_workspace(workspace_name)
				tab:set_title(tab_title)
			end),
		}),
		pane
	)
end

---@param win Window
---@param pane Pane
---@param replace? boolean
function M.select_workspace(win, pane, replace)
	local workspaces = project_dirs()
	table.insert(workspaces, { id = "new", label = "Create New Workspace" })

	win:perform_action(
		wezterm.action.InputSelector({
			title = "Choose Workspace",
			choices = workspaces,
			fuzzy = true,
			fuzzy_description = "Select workspace: ",
			action = wezterm.action_callback(function(_, _, state_path, workspace_name)
				if not workspace_name or not state_path then
					return
				end
				if state_path == "new" then
					new_workspace(win, pane, replace)
					return
				end
				for _, workspace in ipairs(wezterm.mux.get_workspace_names()) do
					if workspace == workspace_name then
						update_previous_workspace(workspace_name)
						wezterm.mux.set_active_workspace(workspace)
						return
					end
				end
				local state = load_json(state_path)
				if state then
					local window
					if replace then
						wezterm.mux.rename_workspace(wezterm.mux.get_active_workspace(), workspace_name)
						window = get_active_mux_window(workspace_name)
					else
						update_previous_workspace(workspace_name)
						_, _, window = wezterm.mux.spawn_window({
							workspace = state.name,
							cwd = "", -- FIX: without this a first not-in-state tab gets created ??
						})
					end
					load_workspace(state, window)
					wezterm.mux.set_active_workspace(state.name)
				end
			end),
		}),
		pane
	)
end

--------------------------------------------------
-- Save Workspace
--------------------------------------------------

---@param pane PaneInformation[]
---@return pane_state
local function get_pane_state(pane)
	-- I'm only using one pane by tab
	local root = pane[1]

	local domain = root.pane:get_domain_name()
	if wezterm.mux.get_domain(domain):is_spawnable() then
		root.domain = domain

		if not root.pane:get_current_working_dir() then
			root.cwd = ""
		else
			root.cwd = root.pane:get_current_working_dir().file_path
			if utils.is_windows() then
				root.cwd = root.cwd:gsub("^/([a-zA-Z]):", "%1:")
			end
		end
	end

	root.pane = nil

	return root
end

---@param tab MuxTab
---@return tab_state
local function get_tab_state(tab)
	local panes = tab:panes_with_info()

	local tab_state = {
		title = tab:get_title(),
		pane = get_pane_state(panes),
	}

	return tab_state
end

---@param window MuxWindow
---@return window_state
local function get_window_state(window)
	local window_state = {
		title = window:get_title(),
		tabs = {},
	}

	local tabs = window:tabs_with_info()

	for i, tab in ipairs(tabs) do
		local tab_state = get_tab_state(tab.tab)
		tab_state.is_active = tab.is_active
		window_state.tabs[i] = tab_state
	end

	return window_state
end

---@return workspace_state
local function get_workspace_state()
	local workspace_state = {
		name = wezterm.mux.get_active_workspace(),
		window_state = {},
	}
	local mux_win = get_active_mux_window(workspace_state.name)
	workspace_state.window_state = get_window_state(mux_win)
	return workspace_state
end

function M.save_state()
	local state = get_workspace_state()
	write_json(workspaces_dir .. state.name .. ".json", state)
end

return M
