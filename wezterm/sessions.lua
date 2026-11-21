local wezterm = require("wezterm")
local utils = require("utils")
local ssh = require("ssh")
local home_from_path = utils.is_windows() and "\\AppData\\Roaming\\wezterm\\workspaces\\"
	or "/.local/share/wezterm/workspaces/"
local workspaces_dir = wezterm.home_dir .. home_from_path

local M = {}

-- Largely based on https://github.com/MLFlexer/resurrect.wezterm,
-- but resurrect doesn't work for me, has too many features
-- and doesn't even open the workspace (just loads window in current workspace)

---@alias MuxWindow table
---@alias MuxTab table
---@alias Window table
---@alias Pane table
---@alias workspace_state {name: string, window_state: window_state}
---@alias window_state {title: string, tabs: tab_state[]}
---@alias tab_state {title: string, pane: pane_state, is_active: boolean}
---@alias pane_state {left: integer, top: integer, height: integer, width: integer, cwd: string, domain: string, is_active: boolean, is_zoomed: boolean}

--------------------------------------------------
-- Utils
--------------------------------------------------

function M.setup()
	if pcall(wezterm.read_dir, workspaces_dir) then
		return
	end
	local args = utils.is_windows() and { "cmd.exe", "/c", "mkdir", workspaces_dir }
		or { "mkdir", "-p", workspaces_dir }
	local ok, _, stderr = wezterm.run_child_process(args)
	if not ok then
		wezterm.log_error("Failed to create " .. workspaces_dir .. ": " .. (stderr or ""))
	end
end

---@param file_path string
---@return workspace_state|nil
local function load_state(file_path)
	local file = io.open(file_path, "r")
	if not file then
		return nil
	end
	local content = file:read("*a")
	file:close()
	local ok, state = pcall(wezterm.json_parse, content or "")
	local tabs = ok and type(state) == "table" and type(state.window_state) == "table" and state.window_state.tabs
	if type(tabs) ~= "table" or #tabs == 0 then
		wezterm.log_error("Invalid workspace file: " .. file_path)
		return nil
	end
	return state
end

---@param workspace string
---@return boolean
function M.workspace_exists(workspace)
	for _, name in ipairs(wezterm.mux.get_workspace_names()) do
		if name == workspace then
			return true
		end
	end
	return false
end

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

--- Close every tab in the window, except `keep` (if given)
---@param mux_window MuxWindow
---@param keep? MuxTab
function M.close_tabs(mux_window, keep)
	for _, t in ipairs(mux_window:tabs()) do
		if not keep or t:tab_id() ~= keep:tab_id() then
			t:activate()
			pcall(function()
				mux_window
					:gui_window()
					:perform_action(wezterm.action.CloseCurrentTab({ confirm = false }), mux_window:active_pane())
			end)
		end
	end
end

---@param workspace string
local function update_previous_workspace(workspace)
	local current_workspace = wezterm.mux.get_active_workspace()
	if current_workspace ~= workspace then
		wezterm.GLOBAL.previous_workspace = current_workspace
	end
end

---@param name string|nil
---@return string|{DomainName: string}
local function spawn_domain(name)
	local ok, domain = pcall(wezterm.mux.get_domain, name)
	if name and ok and domain and domain:is_spawnable() then
		return { DomainName = name }
	end
	return "DefaultDomain"
end

--------------------------------------------------
-- Load or Create Workspace
--------------------------------------------------

---@param state workspace_state
---@param win MuxWindow
local function load_workspace(state, win)
	local tab_active
	for i, tab in ipairs(state.window_state.tabs) do
		local pane_state = tab.pane or {}
		local t = win:spawn_tab({
			domain = spawn_domain(pane_state.domain),
			cwd = pane_state.cwd ~= "" and pane_state.cwd or nil,
		})
		if i == 1 then
			M.close_tabs(win, t)
		end
		t:set_title(tab.title or "")
		if tab.is_active or not tab_active then
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
				local workspace_name, domain = utils.get_domain(line or "")
				local name, tab_title = workspace_name:match("^([^:]*):(.*)$")
				workspace_name = name or workspace_name
				if #workspace_name == 0 then
					return
				end
				local tab
				if replace then
					wezterm.mux.rename_workspace(wezterm.mux.get_active_workspace(), workspace_name)
					local t, _, w = get_active_mux_window(workspace_name):spawn_tab({ domain = domain })
					M.close_tabs(w, t)
					tab = t
				else
					update_previous_workspace(workspace_name)
					tab = wezterm.mux.spawn_window({ workspace = workspace_name, domain = domain })
				end
				wezterm.mux.set_active_workspace(workspace_name)
				tab:set_title(tab_title or "")
			end),
		}),
		pane
	)
end

---@param win Window
---@param pane Pane
---@param replace? boolean
function M.select_workspace(win, pane, replace)
	local workspaces = {}
	for i, path in ipairs(wezterm.glob(workspaces_dir .. "*.json")) do
		local file_name = path:match("([^/\\]+)%.json$")
		if file_name then
			table.insert(workspaces, { id = path, label = i .. " - " .. file_name })
		end
	end
	if #wezterm.default_ssh_domains() > 0 then
		table.insert(workspaces, { id = "ssh", label = "SSH" })
	end
	table.insert(workspaces, { id = "new", label = "Create New Workspace" })

	win:perform_action(
		wezterm.action.InputSelector({
			title = "Choose Workspace",
			choices = workspaces,
			fuzzy = true,
			fuzzy_description = "Select workspace: ",
			action = wezterm.action_callback(function(_, _, state_path, label)
				if not state_path or not label then
					return
				end
				if state_path == "new" then
					return new_workspace(win, pane, replace)
				end
				local workspace_name = label:gsub("^%d+ %- ", "")
				if M.workspace_exists(workspace_name) then
					update_previous_workspace(workspace_name)
					return wezterm.mux.set_active_workspace(workspace_name)
				end
				local state
				if state_path ~= "ssh" then
					state = load_state(state_path)
					if not state then
						return
					end
				end
				local w
				if replace then
					wezterm.mux.rename_workspace(wezterm.mux.get_active_workspace(), workspace_name)
					w = get_active_mux_window(workspace_name)
				else
					update_previous_workspace(workspace_name)
					local cwd = state and (state.window_state.tabs[1].pane or {}).cwd
					_, _, w = wezterm.mux.spawn_window({
						workspace = workspace_name,
						cwd = (cwd and cwd ~= "") and cwd or wezterm.home_dir,
					})
				end
				if state then
					wezterm.mux.set_active_workspace(workspace_name)
					return load_workspace(state, w)
				end
				local t, p = w:spawn_tab({ domain = { DomainName = "local" }, cwd = wezterm.home_dir })
				wezterm.mux.set_active_workspace(workspace_name)
				M.close_tabs(w, t)
				ssh.select_ssh(w:gui_window(), p)
			end),
		}),
		pane
	)
end

--------------------------------------------------
-- Save Workspace
--------------------------------------------------

function M.save_state()
	M.setup()
	local name = wezterm.mux.get_active_workspace()
	local mux_win = get_active_mux_window(name)
	local tabs = {}
	for _, info in ipairs(mux_win:tabs_with_info()) do
		local root = info.tab:panes_with_info()[1] -- I'm only using one pane by tab
		local domain = root.pane:get_domain_name()
		if wezterm.mux.get_domain(domain):is_spawnable() then
			local cwd = root.pane:get_current_working_dir()
			root.domain = domain
			root.cwd = cwd and cwd.file_path or ""
			if utils.is_windows() then
				root.cwd = root.cwd:gsub("^/([a-zA-Z]):", "%1:")
			end
		end
		root.pane = nil
		table.insert(tabs, { title = info.tab:get_title(), pane = root, is_active = info.is_active })
	end

	---@type workspace_state
	local state = { name = name, window_state = { title = mux_win:get_title(), tabs = tabs } }
	local file, err = io.open(workspaces_dir .. name .. ".json", "w")
	if not file then
		return wezterm.log_error("Failed to open file: " .. err)
	end
	file:write(wezterm.json_encode(state))
	file:close()
end

return M
