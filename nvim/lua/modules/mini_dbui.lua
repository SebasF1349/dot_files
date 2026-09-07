local M = {}

M.active_tunnels = {}

---@class SchemaState
---@field expanded boolean
---@field tables string[]

---@class DBState
---@field connected boolean
---@field expanded boolean
---@field schemas string[]
---@field schema_state table<string, SchemaState>
---@field saved string[]
---@field s_expanded boolean

---@class MiniState
---@field dbs table<string, db>
---@field ssh table<string, ssh>
---@field ui_tab integer|nil
---@field ui_buf integer|nil
---@field ui_win integer|nil
---@field db_state table<string, DBState>
---@field lines_map table<number, table>

---@type MiniState
local state = {
  dbs = {},
  ssh = {},
  ui_tab = nil,
  ui_buf = nil,
  ui_win = nil,
  db_state = {},
  lines_map = {},
}

local save_path = vim.fn.stdpath('data') .. '/dadbod_queries'
vim.fn.mkdir(save_path, 'p')

local function get_saved_queries(db_name)
  local path = save_path .. '/' .. db_name
  vim.fn.mkdir(path, 'p')
  local files = vim.fn.glob(path .. '/*.sql', true, true)
  local list = {}
  for _, file in ipairs(files) do
    table.insert(list, vim.fn.fnamemodify(file, ':t'))
  end
  return list
end

local function get_schema_url(base_url, schema)
  if base_url:match('/%?') then
    return base_url:gsub('/%?', '/' .. schema .. '?')
  else
    return base_url .. '/' .. schema
  end
end

local function run_db_query(url, query)
  local ok_cmd, cmd = pcall(vim.fn['db#adapter#dispatch'], url, 'interactive')
  if not ok_cmd or not cmd then
    return nil, 'Failed to get adapter command'
  end

  local full_cmd = vim.tbl_extend('error', {}, cmd)
  table.insert(full_cmd, '-e')
  table.insert(full_cmd, query)

  local env_dict = {}
  local ok_env, env_res = pcall(vim.fn['db#adapter#env'], url)
  if ok_env and type(env_res) == 'table' then
    env_dict = env_res
  end

  local saved_env = {}
  for k, v in pairs(env_dict) do
    saved_env[k] = vim.env[k]
    vim.env[k] = v
  end

  local res = vim.fn.systemlist(full_cmd)
  local err = vim.v.shell_error

  for k, _ in pairs(env_dict) do
    vim.env[k] = saved_env[k]
  end

  if err ~= 0 then
    return nil, table.concat(res, '\n')
  end

  return res, nil
end

local function draw()
  if not state.ui_buf or not vim.api.nvim_buf_is_valid(state.ui_buf) then
    return
  end

  local lines = {}
  state.lines_map = {}
  local line_nr = 1
  local names = vim.tbl_keys(state.dbs)
  table.sort(names)

  for _, name in ipairs(names) do
    local s = state.db_state[name]
    local icon = s.expanded and '▾' or '▸'
    local status = s.connected and '' or ' (Disconnected)'

    table.insert(lines, string.format('%s %s%s', icon, name, status))
    state.lines_map[line_nr] = { type = 'db', name = name }
    line_nr = line_nr + 1

    if s.expanded and s.connected then
      local s_icon = s.s_expanded and '▾' or '▸'
      table.insert(lines, string.format('  %s Saved Queries (%d)', s_icon, #s.saved))
      state.lines_map[line_nr] = { type = 'node', name = name, node = 'saved' }
      line_nr = line_nr + 1
      if s.s_expanded then
        for _, q in ipairs(s.saved) do
          table.insert(lines, string.format('    - %s', q))
          state.lines_map[line_nr] = { type = 'query', name = name, val = q }
          line_nr = line_nr + 1
        end
      end

      for _, schema in ipairs(s.schemas) do
        local ss = s.schema_state[schema]
        local sc_icon = ss.expanded and '▾' or '▸'
        table.insert(lines, string.format('  %s %s', sc_icon, schema))
        state.lines_map[line_nr] = { type = 'schema', name = name, schema = schema }
        line_nr = line_nr + 1

        if ss.expanded then
          table.insert(lines, '    [New Query]')
          state.lines_map[line_nr] = { type = 'new_query', name = name, schema = schema }
          line_nr = line_nr + 1

          for _, tbl in ipairs(ss.tables) do
            table.insert(lines, string.format('    - %s', tbl))
            state.lines_map[line_nr] = { type = 'table', name = name, schema = schema, val = tbl }
            line_nr = line_nr + 1
          end
        end
      end
    end
  end

  vim.bo[state.ui_buf].modifiable = true
  vim.api.nvim_buf_set_lines(state.ui_buf, 0, -1, false, lines)
  vim.bo[state.ui_buf].modifiable = false
  vim.bo[state.ui_buf].modified = false
end

local function open_buffer(name, schema, table_name, query_file)
  local base_url = vim.g.dbs[name]
  if not base_url then
    return
  end

  local url = base_url
  if schema then
    url = get_schema_url(base_url, schema)
  end

  local target_win = nil
  if state.ui_tab and vim.api.nvim_tabpage_is_valid(state.ui_tab) then
    for _, w in ipairs(vim.api.nvim_tabpage_list_wins(state.ui_tab)) do
      if w ~= state.ui_win then
        target_win = w
        break
      end
    end
  end

  if target_win then
    vim.api.nvim_set_current_win(target_win)
  else
    vim.cmd('wincmd p')
  end

  if query_file then
    vim.cmd('keepalt noautocmd edit ' .. save_path .. '/' .. name .. '/' .. query_file)
  else
    vim.cmd('enew')
  end

  local buf = vim.api.nvim_get_current_buf()
  vim.bo[buf].buftype = ''
  vim.bo[buf].swapfile = false

  vim.b[buf].db = url
  vim.b[buf].dbui_db_key_name = name
  vim.b[buf].dbui_table_name = table_name or ''
  vim.b[buf].dbui_schema_name = schema or ''

  if schema and state.db_state[name] and state.db_state[name].schema_state[schema] then
    vim.b[buf].mini_dbui_tables = state.db_state[name].schema_state[schema].tables
  end

  vim.bo[buf].filetype = 'sql'

  if not query_file and table_name then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { string.format('SELECT * FROM `%s` LIMIT 10;', table_name) })
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_buf_call(buf, function()
          vim.cmd('%DB')
        end)
      end
    end)
  end
end

local function finish_connection(name, url)
  local vim_dbs = vim.g.dbs or {}
  vim_dbs[name] = url
  vim.g.dbs = vim_dbs

  local s = state.db_state[name]
  s.schemas = {}
  s.schema_state = {}

  local res, err = run_db_query(url, 'SHOW DATABASES;')
  if res then
    for _, line in ipairs(res) do
      local clean = vim.trim(line)
      if clean ~= '' and not clean:match('^[-+|]+') and not clean:lower():match('^database') then
        table.insert(s.schemas, clean)
        s.schema_state[clean] = { expanded = false, tables = {} }
      end
    end
  else
    vim.notify('Failed to fetch schemas for ' .. name .. ': ' .. (err or ''), vim.log.levels.ERROR)
  end

  s.saved = get_saved_queries(name)
  s.connected = true
  s.expanded = true
  s.s_expanded = false

  draw()
  vim.notify('Connected to ' .. name, vim.log.levels.INFO)
end

local function toggle_db(name)
  local s = state.db_state[name]
  local db = state.dbs[name]

  if s.connected then
    s.expanded = not s.expanded
    draw()
  else
    vim.notify('Connecting to ' .. name .. '...', vim.log.levels.INFO)
    local url = db:get_connection_cmd()

    if not db.db_host and state.ssh[name] then
      local pid = state.ssh[name]:create_tunnel(M.active_tunnels, name, db.db_port)
      M.active_tunnels[name] = pid
      vim.defer_fn(function()
        finish_connection(name, url)
      end, 1500)
    else
      finish_connection(name, url)
    end
  end
end

local function on_cr()
  local line = vim.api.nvim_win_get_cursor(0)[1]
  local meta = state.lines_map[line]
  if not meta then
    return
  end

  if meta.type == 'db' then
    toggle_db(meta.name)
  elseif meta.type == 'schema' then
    local ss = state.db_state[meta.name].schema_state[meta.schema]
    ss.expanded = not ss.expanded

    if ss.expanded and #ss.tables == 0 then
      local base_url = state.dbs[meta.name]:get_connection_cmd()
      local schema_url = get_schema_url(base_url, meta.schema)

      local ok, res = pcall(vim.fn['db#adapter#dispatch'], schema_url, 'tables')
      if ok and type(res) == 'table' then
        for _, tbl in ipairs(res) do
          local clean = vim.trim(tbl)
          if
            clean ~= ''
            and not clean:match('^[-+|]+')
            and not clean:lower():match('^table')
            and not clean:lower():match('^row')
          then
            table.insert(ss.tables, clean)
          end
        end
      end
    end
    draw()
  elseif meta.type == 'new_query' then
    open_buffer(meta.name, meta.schema, nil, nil)
  elseif meta.type == 'node' then
    local s = state.db_state[meta.name]
    s.s_expanded = not s.s_expanded
    draw()
  elseif meta.type == 'table' then
    open_buffer(meta.name, meta.schema, meta.val, nil)
  elseif meta.type == 'query' then
    open_buffer(meta.name, nil, nil, meta.val)
  end
end

function M.save_query()
  local db_name = vim.b.dbui_db_key_name
  if not db_name then
    return vim.notify('Not in a DB buffer', vim.log.levels.ERROR)
  end

  if vim.fn.expand('%:p'):match(save_path) then
    vim.cmd('w')
    return vim.notify('Query saved', vim.log.levels.INFO)
  end

  vim.ui.input({ prompt = 'Query name (no .sql): ' }, function(input)
    if not input or input == '' then
      return
    end
    local filepath = save_path .. '/' .. db_name .. '/' .. input .. '.sql'
    vim.cmd('write ' .. filepath)
    state.db_state[db_name].saved = get_saved_queries(db_name)
    draw()
  end)
end

function M.toggle_ui()
  if state.ui_tab and vim.api.nvim_tabpage_is_valid(state.ui_tab) then
    if vim.api.nvim_get_current_tabpage() == state.ui_tab then
      vim.cmd('tabclose')
      state.ui_tab = nil
      state.ui_win = nil
      state.ui_buf = nil
      return
    else
      vim.api.nvim_set_current_tabpage(state.ui_tab)
      return
    end
  end

  vim.cmd('tabnew')
  state.ui_tab = vim.api.nvim_get_current_tabpage()

  vim.cmd('enew')
  local query_buf = vim.api.nvim_get_current_buf()
  vim.bo[query_buf].buftype = 'nofile'
  vim.bo[query_buf].swapfile = false

  vim.cmd('topleft 40vnew')
  state.ui_win = vim.api.nvim_get_current_win()
  state.ui_buf = vim.api.nvim_get_current_buf()

  vim.bo[state.ui_buf].buftype = 'nofile'
  vim.bo[state.ui_buf].filetype = 'dbui'
  vim.bo[state.ui_buf].swapfile = false
  vim.bo[state.ui_buf].modified = false
  vim.api.nvim_buf_set_name(state.ui_buf, '[DBUI]')

  vim.keymap.set('n', '<CR>', on_cr, { buffer = state.ui_buf })
  draw()
end

function M.disconnect(name)
  local s = state.db_state[name]
  if s then
    s.connected = false
    s.expanded = false
    draw()
  end

  local dbs = vim.g.dbs or {}
  dbs[name] = nil
  vim.g.dbs = dbs

  local pid = M.active_tunnels[name]
  if pid then
    vim.uv.kill(pid, 15)
    M.active_tunnels[name] = nil
  end
end

function M.setup(databases, ssh)
  state.dbs = databases or {}
  state.ssh = ssh or {}
  for name, _ in pairs(state.dbs) do
    state.db_state[name] =
      { connected = false, expanded = false, schemas = {}, schema_state = {}, saved = {}, s_expanded = false }
  end

  vim.api.nvim_create_autocmd('VimLeavePre', {
    callback = function()
      for _, pid in pairs(M.active_tunnels) do
        vim.uv.kill(pid, 15)
      end
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(buf) then
          vim.bo[buf].modified = false
        end
      end
    end,
  })

  vim.api.nvim_create_autocmd('WinEnter', {
    callback = function()
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == 'nofile' then
          vim.bo[buf].modified = false
        end
      end

      if state.ui_tab and vim.api.nvim_tabpage_is_valid(state.ui_tab) then
        local curr_tab = vim.api.nvim_get_current_tabpage()
        if curr_tab == state.ui_tab and #vim.api.nvim_list_tabpages() == 1 then
          vim.cmd('quitall!')
        end
      end
    end,
  })
end

return M
