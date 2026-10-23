local ssh_module = require('modules.ssh_types')
local M = {}

---@class MiniState
---@field dbs table<string, db>
---@field ssh table<string, ssh>
---@field db_order string[]
---@field schemas table<string, string[]>

---@type MiniState
local state = {
  dbs = {},
  ssh = {},
  db_order = {},
  schemas = {},
}

local augroup = vim.api.nvim_create_augroup('MiniDbui', { clear = true })
local save_path = vim.fs.joinpath(vim.fn.stdpath('data'), 'dadbod_queries')

local sql_helpers = {
  {
    name = 'Columns',
    query = [[
SELECT
    COLUMN_NAME,
    COLUMN_TYPE,
    IS_NULLABLE,
    COLUMN_DEFAULT,
    COLUMN_KEY,
    EXTRA,
    COLLATION_NAME,
    COLUMN_COMMENT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = '%s'
    AND TABLE_SCHEMA = '%s'
ORDER BY ORDINAL_POSITION;
      ]],
  },
  {
    name = 'Indexes',
    query = [[
SELECT
    TABLE_NAME,
    NON_UNIQUE,
    INDEX_NAME,
    SEQ_IN_INDEX AS 'Sequence in Index',
    COLUMN_NAME,
    INDEX_TYPE,
    COLLATION,
    CARDINALITY,
    NULLABLE,
    COMMENT,
    INDEX_COMMENT
FROM INFORMATION_SCHEMA.STATISTICS
WHERE TABLE_NAME = '%s'
    AND TABLE_SCHEMA = '%s';
      ]],
  },
  {
    name = 'Keys',
    query = [[
SELECT
    CONSTRAINT_NAME,
    COLUMN_NAME,
    ORDINAL_POSITION,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE TABLE_NAME = '%s'
    AND TABLE_SCHEMA = '%s'
ORDER BY CONSTRAINT_NAME;
      ]],
  },
  {
    name = 'References',
    query = [[
SELECT
    TABLE_SCHEMA,
    TABLE_NAME,
    COLUMN_NAME,
    CONSTRAINT_NAME,
    REFERENCED_COLUMN_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE REFERENCED_TABLE_NAME = '%s'
    AND REFERENCED_TABLE_SCHEMA = '%s'
ORDER BY TABLE_NAME;
      ]],
  },
  {
    name = 'Table Data',
    query = [[
SELECT 
    ENGINE,
    TABLE_ROWS,
    AUTO_INCREMENT,
    ROUND(DATA_LENGTH / 1024 / 1024, 2) AS 'Data_Size_MB',
    ROUND(INDEX_LENGTH / 1024 / 1024, 2) AS 'Index_Size_MB',
    ROUND(DATA_FREE / 1024 / 1024, 2) AS 'Free_Space_MB',
    CREATE_TIME,
    UPDATE_TIME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_NAME = '%s' 
    AND TABLE_SCHEMA = '%s';
      ]],
  },
  {
    name = 'Triggers',
    query = [[
SELECT 
    TRIGGER_NAME, 
    ACTION_TIMING, 
    EVENT_MANIPULATION AS 'EVENT', 
    ACTION_STATEMENT AS 'LOGIC'
FROM INFORMATION_SCHEMA.TRIGGERS
WHERE EVENT_OBJECT_TABLE = '%s' 
    AND TRIGGER_SCHEMA = '%s';
      ]],
  },
}

local function get_saved_queries(db_name)
  return vim.fn.glob(vim.fs.joinpath(save_path, db_name, '*.sql'), true, true)
end

local function exec_query(action)
  local display_name = vim.b[0].display_name
  vim.cmd(action)
  vim.cmd.wincmd('P')
  vim.b[0].display_name = display_name

  vim.keymap.set('n', 'K', function()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local count = 0
    for i = row, 1, -1 do
      local line = vim.fn.getline(i)
      if i == row then
        line = line:sub(1, col + 1)
      end
      count = count + select(2, line:gsub('|', ''))
      if vim.startswith(line, '|') then
        break
      end
    end
    local name = vim.trim(vim.split(vim.fn.getline(2), '|', { plain = true })[count + 1] or '')
    if name ~= '' then
      vim.lsp.util.open_floating_preview({ name }, 'md', {})
    end
  end, { buf = 0, desc = 'Show column name for current cell' })
end

local function run_db_query(url, query)
  local ok, cmd = pcall(vim.fn['db#adapter#dispatch'], url, 'interactive')
  if not ok or type(cmd) ~= 'table' then
    return nil, 'Failed to get adapter command'
  end

  local _, env = pcall(vim.fn['db#adapter#env'], url)
  local res =
    vim.system(cmd, { text = true, stdin = query, env = type(env) == 'table' and env or nil, timeout = 60000 }):wait()

  if res.code ~= 0 then
    return nil, res.stderr ~= '' and res.stderr or res.stdout
  end
  return vim.split(res.stdout, '\r?\n', { trimempty = true })
end

local function get_statement_node()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local col = (vim.api.nvim_get_current_line():find('%S') or 1) - 1
  local node = vim.treesitter.get_node({ bufnr = 0, pos = { row - 1, col } })
  while node and node:type() ~= 'statement' do
    node = node:parent()
  end
  if node then
    return vim.treesitter.get_node_range(node)
  end
end
local function open_buffer(name, schema, query_file, keep_win)
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

  vim.b[buf].db = state.dbs[name]:url(schema)
  vim.b[buf].display_name =
    string.format('[db:%s] %s', name, query_file and vim.fs.basename(query_file) or schema or 'default')
  vim.b[buf].db_key_name = name
  vim.b[buf].db_schema_name = schema or ''
  vim.bo[buf].omnifunc = vim.fn['vim_dadbod_completion#omni']
  vim.bo[buf].complete = 'o,.'
  vim.bo[buf].autocomplete = true
  vim.bo[buf].completeopt = 'menuone,popup,noselect,fuzzy'

  local win = vim.api.nvim_get_current_win()
  vim.wo[win][0].winhighlight = state.dbs[name].type == 'prod' and 'Normal:DiffDelete' or ''

  vim.keymap.set('n', '<leader>q', M.open_saved_queries, { desc = 'DB: Open Saved [Q]ueries', buf = buf })

  vim.keymap.set('n', '<leader>h', function()
    vim.ui.select(sql_helpers, {
      prompt = 'Query: ',
      format_item = function(item)
        return item.name
      end,
    }, function(choice)
      if not choice then
        return
      end
      local query = choice.query:format('', vim.b.db_schema_name)
      local output = vim.split(query, '\n')
      local cursor = vim.api.nvim_win_get_cursor(0)
      vim.api.nvim_buf_set_lines(0, cursor[1] - 1, cursor[1] - 1, false, output)
    end)
  end, { desc = 'DB: [H]elpers', buf = buf })

  vim.keymap.set('x', 'aq', function()
    local start_row, start_col, end_row, end_col = get_statement_node()
    if not start_row then
      return
    end
    vim.api.nvim_win_set_cursor(0, { start_row + 1, start_col })
    vim.cmd.normal({ 'o', bang = true })
    vim.api.nvim_win_set_cursor(0, { end_row + 1, end_col })
  end, { desc = 'DB: Select SQL Query', buf = buf })
  vim.keymap.set('o', 'aq', '<cmd>normal vaq<CR>', { desc = 'DB: SQL Query Text-Object', buf = buf, remap = true })

  vim.keymap.set('x', '<CR>', function()
    vim.api.nvim_feedkeys(vim.keycode('<Esc>'), 'x', false)
    exec_query("'<,'>DB")
  end, { desc = 'DB: Execute', buf = buf })
  vim.keymap.set('n', '<CR>', function()
    vim.cmd('normal vaq')
    vim.api.nvim_feedkeys(vim.keycode('<Esc>'), 'x', false)
    exec_query("'<,'>DB")
  end, { desc = 'DB: Execute', buf = buf, remap = true })
  vim.keymap.set('n', 'W', M.save_query, { desc = 'DB: [W]rite', buf = buf })

  vim.keymap.set({ 'n', 'x' }, '<C-q>', 'db#op_exec()', { desc = 'DB: Execute Operator', buf = buf, expr = true })

  vim.keymap.set('i', '.', function()
    vim.api.nvim_feedkeys('.', 'n', false)
    vim.defer_fn(function()
      vim.api.nvim_feedkeys(vim.keycode('<C-x><C-o>'), 'm', false)
    end, 50)
  end, { buf = buf, desc = 'Delayed SQL omnicompletion' })
end

local function fetch_schemas(name, url)
  local res, err = run_db_query(
    url,
    [[SHOW DATABASES WHERE `Database` NOT IN ('information_schema', 'mysql', 'performance_schema', 'sys');]]
  )

  if err then
    vim.notify('Fetch schemas err: ' .. err, vim.log.levels.ERROR)
    return false
  end

  state.schemas[name] = vim.list_slice(res or {}, 2)
  return true
end

local function select_schema_and_open(name)
  vim.ui.select(state.schemas[name] or {}, { prompt = 'Select Schema (' .. name .. '):' }, function(schema)
    if schema then
      open_buffer(name, schema)
    end
  end)
end

local function free_port()
  local tcp = assert(vim.uv.new_tcp())
  tcp:bind('127.0.0.1', 0)
  local port = tcp:getsockname().port
  tcp:close()
  return port
end

local function handle_db_selection(name)
  local db = state.dbs[name]
  local tunnel = not db.db_host and state.ssh[name]

  if state.schemas[name] and (not tunnel or ssh_module.active_tunnels[name]) then
    select_schema_and_open(name)
    return
  end

  if tunnel then
    db.db_port = free_port()
  end
  local url = db:url()

  local function on_connect()
    if fetch_schemas(name, url) then
      vim.notify('Connected to ' .. name, vim.log.levels.INFO)
      select_schema_and_open(name)
    else
      ssh_module.kill_tunnel(name)
    end
  end

  vim.notify('Connecting to ' .. name .. '...', vim.log.levels.INFO)
  if tunnel then
    tunnel:create_tunnel(name, db.db_port or '3306', on_connect)
  else
    on_connect()
  end
end

function M.toggle_ui()
  if vim.b.display_name and vim.startswith(vim.b.display_name, '[db:') then
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
      return vim.fs.basename(path)
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
  ssh_module.kill_tunnel(name)
  state.schemas[name] = nil
  vim.notify('Disconnected from ' .. name, vim.log.levels.INFO)
end

function M.setup(databases, ssh, db_order)
  state.dbs, state.ssh, state.db_order = databases, ssh or {}, db_order

  vim.keymap.set('n', '<leader>dd', M.toggle_ui, { desc = '[D]B: Toggle UI' })
  vim.keymap.set('n', '<leader>ds', function()
    vim.ui.select(vim.tbl_keys(state.schemas), { prompt = 'Disconnect:' }, function(name)
      if name then
        M.disconnect(name)
      end
    end)
  end, { desc = '[D]B: [S]top Connection' })
end

vim.api.nvim_create_autocmd('User', {
  pattern = '*/DBExecutePost',
  group = augroup,
  callback = function(args)
    local query_info = vim.b[args.buf].db
    if not (query_info and query_info.runtime) then
      return
    end
    local display_name = vim.b[args.buf].display_name
    local runtime_str = string.format('-- %s query execution time: %.3fs', display_name or '', query_info.runtime)
    vim.notify(runtime_str, vim.log.levels.INFO)
  end,
})

vim.api.nvim_create_autocmd('VimLeavePre', { group = augroup, callback = ssh_module.kill_all })

return M
