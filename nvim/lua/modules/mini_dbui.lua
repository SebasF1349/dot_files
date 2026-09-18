local ssh_module = require('modules.ssh_types')
local M = {}

---@class MiniState
---@field dbs table<string, db>
---@field ssh table<string, ssh>
---@field db_order string[]
---@field connected_dbs table<string, boolean>
---@field schemas table<string, string[]>

---@type MiniState
local state = {
  dbs = {},
  ssh = {},
  db_order = {},
  connected_dbs = {},
  schemas = {},
}

local augroup = vim.api.nvim_create_augroup('MiniDbui', { clear = true })
local save_path = vim.fs.joinpath(vim.fn.stdpath('data'), 'dadbod_queries')

local function get_saved_queries(db_name)
  vim.fn.mkdir(vim.fs.joinpath(save_path, db_name), 'p')
  return vim.fn.glob(vim.fs.joinpath(save_path, db_name, '*.sql'), true, true) or {}
end

function M.exec_query(action)
  if type(action) == 'string' then
    vim.cmd(action)
  else
    action()
  end

  vim.cmd.wincmd('j')

  vim.keymap.set('n', 'K', function()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local lines = vim.api.nvim_buf_get_lines(0, 0, row, false)
    local header_line = lines[2]
    local count = 0

    for i = #lines, 1, -1 do
      local line = lines[i]
      local target_str = (i == row) and line:sub(1, col + 1) or line
      local _, added = target_str:gsub('|', '')
      count = count + added

      if i <= row and vim.startswith(line, '|') then
        break
      end
    end

    local target_pos
    for _ = 1, count do
      target_pos = header_line:find('|', (target_pos or 0) + 1)
      if not target_pos then
        break
      end
    end

    if not target_pos then
      return
    end

    local next_pipe = header_line:find('|', target_pos + 1)
    local end_pos = next_pipe and (next_pipe - 1) or #header_line
    local col_name = vim.trim(header_line:sub(target_pos + 1, end_pos))

    if col_name ~= '' then
      vim.lsp.util.open_floating_preview({ col_name }, 'md', {})
    end
  end, { buf = 0, desc = 'Show column name for current cell' })
end

local function run_db_query(url, query)
  local ok, cmd = pcall(vim.fn['db#adapter#dispatch'], url, 'interactive')
  if not ok or type(cmd) ~= 'table' then
    return nil, 'Failed to get adapter command'
  end

  local _, env = pcall(vim.fn['db#adapter#env'], url)
  local res = vim
    .system(cmd, {
      text = true,
      stdin = query,
      env = vim.tbl_extend('force', vim.fn.environ(), type(env) == 'table' and env or {}),
    })
    :wait()

  if res.code ~= 0 then
    return nil, res.stderr ~= '' and res.stderr or res.stdout
  end
  return vim.split(res.stdout, '\r?\n', { trimempty = true })
end

local function open_buffer(name, schema, query_file, keep_win)
  local base_url = vim.g.dbs[name]
  if not base_url then
    return
  end

  if not keep_win then
    vim.cmd('tabnew')
  end

  local buf
  if query_file then
    vim.cmd('edit ' .. vim.fn.fnameescape(query_file))
    buf = vim.api.nvim_get_current_buf()
  else
    vim.cmd('enew')
    buf = vim.api.nvim_get_current_buf()
    vim.bo[buf].buftype = 'nofile'
    vim.bo[buf].bufhidden = 'hide'
    vim.bo[buf].filetype = 'sql'
  end

  vim.b[buf].display_name =
    string.format('[db:%s] %s', name, query_file and vim.fs.basename(query_file) or schema or 'default')
  vim.b[buf].db = schema
      and (base_url:match('/%?') and base_url:gsub('/%?', '/' .. schema .. '?') or (base_url .. '/' .. schema))
    or base_url
  vim.b[buf].db_key_name = name
  vim.b[buf].db_schema_name = schema or ''
  vim.bo[buf].omnifunc = M.custom_sql_omni
  vim.bo[buf].complete = 'o'
  vim.bo[buf].autocomplete = true
  vim.bo[buf].completeopt = 'menuone,popup,noselect,fuzzy'

  vim.keymap.set('i', '.', function()
    vim.api.nvim_feedkeys('.', 'n', false)
    vim.defer_fn(function()
      vim.api.nvim_feedkeys(vim.keycode('<C-x><C-o>'), 'm', false)
    end, 50)
  end, { buf = buf, desc = 'Delayed SQL omnicompletion' })
end

local function fetch_schemas(name, url)
  vim.g.dbs = vim.tbl_extend('force', vim.g.dbs or {}, { [name] = url })
  local res, err = run_db_query(url, 'SHOW DATABASES;')

  if err then
    vim.notify('Fetch schemas err: ' .. err, vim.log.levels.ERROR)
    return false
  end

  state.schemas[name] = {}
  for _, line in ipairs(res or {}) do
    local clean = vim.trim(line)
    if clean ~= '' and not clean:match('^[-+|]+') and not clean:match('^[Dd]atabase') then
      table.insert(state.schemas[name], clean)
    end
  end

  state.connected_dbs[name] = true
  return true
end

local function select_schema_and_open(name)
  local schemas = state.schemas[name] or {}
  if #schemas == 0 then
    open_buffer(name, nil)
    return
  end

  vim.ui.select(schemas, { prompt = 'Select Schema (' .. name .. '):' }, function(schema)
    if schema then
      open_buffer(name, schema)
    end
  end)
end

local function handle_db_selection(name)
  local db = state.dbs[name]
  local url = db:get_connection_cmd()

  if state.connected_dbs[name] then
    select_schema_and_open(name)
    return
  end

  vim.notify('Connecting to ' .. name .. '...', vim.log.levels.INFO)
  if not db.db_host and state.ssh[name] then
    state.ssh[name]:create_tunnel(name, db.db_port, function()
      if fetch_schemas(name, url) then
        vim.notify('Connected to ' .. name, vim.log.levels.INFO)
        select_schema_and_open(name)
      end
    end)
  else
    if fetch_schemas(name, url) then
      vim.notify('Connected to ' .. name, vim.log.levels.INFO)
      select_schema_and_open(name)
    end
  end
end

function M.toggle_ui()
  if vim.b.db_key_name then
    pcall(vim.cmd.tabclose)
    return
  end

  vim.ui.select(state.db_order, { prompt = 'Select Database:' }, function(name)
    if name then
      handle_db_selection(name)
    end
  end)
end

function M.open_saved_queries()
  local db = vim.b.db_key_name
  local queries = get_saved_queries(db)
  if #queries == 0 then
    vim.notify('No saved queries for ' .. db, vim.log.levels.INFO)
    return
  end

  vim.ui.select(queries, {
    prompt = 'Open saved query: ',
    format_item = function(path)
      return vim.fn.fnamemodify(path, ':t')
    end,
  }, function(query_file)
    if not query_file then
      return
    end

    local schema = vim.b.db_schema_name

    open_buffer(db, schema, query_file, true)
  end)
end

function M.save_query()
  local db = vim.b.db_key_name
  if not db then
    return vim.notify('Not in a DB buffer', vim.log.levels.ERROR)
  end
  if vim.startswith(vim.fn.expand('%:p'), save_path) then
    vim.cmd('w')
    vim.notify('Query saved', vim.log.levels.INFO)
    return
  end

  vim.ui.input({ prompt = 'Query name (no .sql): ' }, function(input)
    if input and input ~= '' then
      vim.fn.mkdir(vim.fs.joinpath(save_path, db), 'p')
      vim.cmd('write ' .. vim.fn.fnameescape(vim.fs.joinpath(save_path, db, input .. '.sql')))
      vim.notify('Query saved', vim.log.levels.INFO)
    end
  end)
end

function M.disconnect(name)
  state.connected_dbs[name] = nil

  local g_dbs = vim.g.dbs or {}
  g_dbs[name] = nil
  vim.g.dbs = g_dbs

  local tunnel = ssh_module.active_tunnels[name]
  if tunnel then
    tunnel:kill('sigterm')
    ssh_module.active_tunnels[name] = nil
  end
  vim.notify('Disconnected from ' .. name, vim.log.levels.INFO)
end

function M.get_connected_dbs()
  return vim.tbl_keys(state.connected_dbs)
end

function M.setup(databases, ssh, db_order)
  state.dbs, state.ssh = databases or {}, ssh or {}
  state.db_order = db_order or vim.tbl_keys(state.dbs)

  vim.api.nvim_create_autocmd('VimLeavePre', { group = augroup, callback = ssh_module.kill_all })
end

function M.custom_sql_omni(findstart, base)
  if findstart == 1 then
    return vim.fn['vim_dadbod_completion#omni'](1, base)
  end

  local results = vim.fn['vim_dadbod_completion#omni'](0, base)
  results = type(results) == 'table' and results or {}
  if base == '' then
    return results
  end

  local seen = {}
  for _, item in ipairs(results) do
    seen[item.word] = true
  end

  local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
  for _, line in ipairs(vim.api.nvim_buf_get_lines(0, math.max(0, row - 100), row, false)) do
    for word in line:gmatch('[%w_]+') do
      if word:sub(1, #base) == base and not seen[word] then
        seen[word] = true
        table.insert(results, { word = word, menu = '[Buf]', icase = 1 })
      end
    end
  end
  return results
end

vim.api.nvim_create_autocmd('User', {
  pattern = '*/DBExecutePost',
  group = augroup,
  callback = function()
    local query_info = vim.b[0].db
    if query_info and query_info.runtime then
      local runtime_str =
        string.format('-- %s query execution time: %.3fs', vim.fs.basename(query_info.input), query_info.runtime)
      vim.notify(runtime_str, vim.log.levels.INFO)
    end
  end,
})

return M
