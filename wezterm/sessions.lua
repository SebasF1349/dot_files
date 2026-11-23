local wezterm = require("wezterm")
local utils = require("utils")

local workspaces_dir = wezterm.home_dir
	.. (utils.is_windows() and "\\AppData\\Roaming\\wezterm\\workspaces\\" or "/.local/share/wezterm/workspaces/")
local OPEN_ICON = "\u{f111} "
-- new_workspace can't create this name: it splits "name:tab" and rejects empty names
local NEW_WORKSPACE = ":new"

local M = {}

---@alias MuxWindow table
---@alias MuxTab table
---@alias Window table
---@alias Pane table
---@alias Domain string|{DomainName: string}
---@alias workspace_state {name: string, window_state: {tabs: tab_state[]}}
---@alias tab_state {title: string, pane: pane_state, is_active: boolean}
---@alias pane_state {domain?: string, cwd?: string}
---@alias tab_spec {title?: string, domain: Domain, cwd?: string, is_active?: boolean}

---@param path string
---@return workspace_state|nil
local function load_state(path)
	local file = io.open(path, "r")
	if not file then
		return
	end
	local content = file:read("*a")
	file:close()
	local ok, state = pcall(function()
		local state = wezterm.json_parse(content)
		assert(#state.window_state.tabs > 0)
		return state
	end)
	if ok then
		return state
	end
	wezterm.log_error("Invalid workspace file: " .. path)
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
function M.switch_to(workspace)
	local current = wezterm.mux.get_active_workspace()
	if current ~= workspace then
		wezterm.GLOBAL.previous_workspace = current
	end
	wezterm.mux.set_active_workspace(workspace)
end

function M.switch_to_previous()
	local workspace = wezterm.GLOBAL.previous_workspace
	if workspace ~= wezterm.mux.get_active_workspace() and M.workspace_exists(workspace) then
		M.switch_to(workspace)
	end
end

--- Close every tab in the window except `keep`
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

---@param win Window
function M.close_workspace(win)
	M.close_tabs(win:mux_window())
	M.switch_to_previous()
	wezterm.GLOBAL.previous_workspace = nil
end

--- Open `tabs` as workspace `name`, in place of `gui_win`'s workspace if `replace`
---@param gui_win Window
---@param name string
---@param tabs tab_spec[]
---@param replace? boolean
local function open_workspace(gui_win, name, tabs, replace)
	local spawn = { domain = tabs[1].domain, cwd = tabs[1].cwd }
	local first, _, win
	if replace then
		wezterm.mux.rename_workspace(wezterm.mux.get_active_workspace(), name)
		win = gui_win:mux_window()
		first = win:spawn_tab(spawn)
		M.close_tabs(win, first)
	else
		spawn.workspace = name
		first, _, win = wezterm.mux.spawn_window(spawn)
	end
	M.switch_to(name)
	local active
	for i, tab in ipairs(tabs) do
		local t = i == 1 and first or win:spawn_tab({ domain = tab.domain, cwd = tab.cwd })
		t:set_title(tab.title or "")
		if tab.is_active or not active then
			active = t
		end
	end
	active:activate()
end

---@param win Window
---@param pane Pane
---@param replace? boolean
local function new_workspace(win, pane, replace)
	win:perform_action(
		utils.prompt("Enter name for new workspace", function(_, line)
			local workspace_name, domain = utils.get_domain(line)
			local name, tab_title = workspace_name:match("^([^:]*):(.*)$")
			workspace_name = name or workspace_name
			if #workspace_name == 0 then
				return
			end
			if M.workspace_exists(workspace_name) then
				return M.switch_to(workspace_name)
			end
			open_workspace(win, workspace_name, { { title = tab_title, domain = domain } }, replace)
		end),
		pane
	)
end

---@param win Window
---@param pane Pane
---@param replace? boolean
function M.select_workspace(win, pane, replace)
	local paths, open, names = {}, {}, {}
	for _, path in ipairs(wezterm.glob(workspaces_dir .. "*.json")) do
		local name = path:match("([^/\\]+)%.json$")
		paths[name] = path
		table.insert(names, name)
	end
	-- on startup the active workspace is the one being replaced
	local skip = replace and wezterm.mux.get_active_workspace()
	for _, name in ipairs(wezterm.mux.get_workspace_names()) do
		if name ~= skip then
			open[name] = true
			if not paths[name] then
				table.insert(names, name)
			end
		end
	end
	table.sort(names)

	local choices = {}
	for i, name in ipairs(names) do
		table.insert(choices, { id = name, label = i .. " - " .. (open[name] and OPEN_ICON or "  ") .. name })
	end
	table.insert(choices, { id = NEW_WORKSPACE, label = "Create New Workspace" })

	win:perform_action(
		wezterm.action.InputSelector({
			title = "Choose Workspace",
			choices = choices,
			fuzzy = true,
			fuzzy_description = "Select workspace: ",
			action = wezterm.action_callback(function(_, _, name)
				if name == NEW_WORKSPACE then
					return new_workspace(win, pane, replace)
				elseif M.workspace_exists(name) then
					return M.switch_to(name)
				end
				local state = paths[name] and load_state(paths[name])
				if not state then
					return
				end
				---@type tab_spec[]
				local tabs = {}
				for _, tab in ipairs(state.window_state.tabs) do
					local p = tab.pane or {}
					local ok, domain = pcall(wezterm.mux.get_domain, p.domain)
					table.insert(tabs, {
						title = tab.title,
						domain = p.domain and ok and domain and domain:is_spawnable() and { DomainName = p.domain } or "DefaultDomain",
						cwd = p.cwd ~= "" and p.cwd or nil,
						is_active = tab.is_active,
					})
				end
				open_workspace(win, name, tabs, replace)
			end),
		}),
		pane
	)
end

---@param win Window
function M.save_state(win)
	if not pcall(wezterm.read_dir, workspaces_dir) then
		local mkdir = utils.is_windows() and { "cmd.exe", "/c", "mkdir" } or { "mkdir", "-p" }
		table.insert(mkdir, workspaces_dir)
		wezterm.run_child_process(mkdir)
	end

	local name = wezterm.mux.get_active_workspace()
	---@type tab_state[]
	local tabs = {}
	for _, info in ipairs(win:mux_window():tabs_with_info()) do
		local pane = info.tab:panes()[1]
		local domain = pane:get_domain_name()
		local pane_state = wezterm.mux.get_domain(domain):is_spawnable()
				and { domain = domain, cwd = utils.pane_cwd(pane) or "" }
			or {}
		table.insert(tabs, { title = info.tab:get_title(), pane = pane_state, is_active = info.is_active })
	end

	local file, err = io.open(workspaces_dir .. name:gsub('[/\\:*?"<>|%c]', "_") .. ".json", "w")
	if not file then
		return win:toast_notification("WezTerm", "Failed to save workspace: " .. err, nil, 4000)
	end
	---@type workspace_state
	local state = { name = name, window_state = { tabs = tabs } }
	file:write(wezterm.json_encode(state))
	file:close()
	win:toast_notification("WezTerm", "Saved workspace " .. name, nil, 2500)
end

return M
