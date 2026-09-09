local ssh_module = require('modules.ssh_types')
local M = {}

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
---@field db_order string[]
---@field ui_tab integer|nil
---@field ui_buf integer|nil
---@field ui_win integer|nil
---@field query_buf integer|nil
---@field db_state table<string, DBState>
---@field lines_map table<number, table>

---@type MiniState
local state = {
  dbs = {},
  ssh = {},
  db_order = {},
  ui_tab = nil,
  ui_buf = nil,
  ui_win = nil,
  query_buf = nil,
  db_state = {},
  lines_map = {},
}

local ns = vim.api.nvim_create_namespace('mini_dbui_ns')

local save_path = vim.fn.stdpath('data') .. '/dadbod_queries'
vim.fn.mkdir(save_path, 'p')

local function setup_highlights()
  vim.cmd([[
    highlight default link MiniDbuiDb Special
    highlight default link MiniDbuiSchema Directory
    highlight default link MiniDbuiTable Identifier
    highlight default link MiniDbuiSaved Comment
    highlight default link MiniDbuiNewQuery String
  ]])
end

local function get_saved_queries(db_name)
  local path = save_path .. '/' .. db_name
  vim.fn.mkdir(path, 'p')
  local list = {}
  for _, file in ipairs(vim.fn.glob(path .. '/*.sql', true, true) or {}) do
    table.insert(list, vim.fn.fnamemodify(file, ':t'))
  end
  return list
end

local function get_schema_url(base_url, schema)
  return base_url:match('/%?') and base_url:gsub('/%?', '/' .. schema .. '?') or (base_url .. '/' .. schema)
end

function M.exec_query(action, label)
  local start = vim.uv.hrtime()
  if type(action) == 'string' then
    vim.cmd(action)
  else
    action()
  end
  vim.notify(
    string.format('%s finished in %.2fms', label or 'Query', (vim.uv.hrtime() - start) / 1e6),
    vim.log.levels.INFO
  )
end

local function run_db_query(url, query)
  local ok_cmd, cmd = pcall(vim.fn['db#adapter#dispatch'], url, 'interactive')
  if not ok_cmd or type(cmd) ~= 'table' then
    return nil, 'Failed to get adapter command'
  end

  local ok_env, env_res = pcall(vim.fn['db#adapter#env'], url)
  local env_dict = (ok_env and type(env_res) == 'table') and env_res or {}

  local res = vim
    .system(cmd, {
      text = true,
      stdin = query,
      env = vim.tbl_extend('force', vim.fn.environ(), env_dict),
    })
    :wait()

  if res.code ~= 0 then
    return nil, res.stderr ~= '' and res.stderr or res.stdout
  end
  return vim.split(res.stdout, '\r?\n', { trimempty = true }), nil
end

local function add_line(lines, line_hl, text, meta, hl_group)
  table.insert(lines, text)
  state.lines_map[#lines] = meta
  if hl_group then
    line_hl[#lines] = hl_group
  end
end

local function draw()
  if not state.ui_buf or not vim.api.nvim_buf_is_valid(state.ui_buf) then
    return
  end
  setup_highlights()
  local lines, line_hl = {}, {}
  state.lines_map = {}

  for _, name in ipairs(state.db_order) do
    local s = state.db_state[name]
    if s then
      add_line(
        lines,
        line_hl,
        string.format('%s %s%s', s.expanded and '▾' or '▸', name, s.connected and '' or ' (Disconnected)'),
        { type = 'db', name = name },
        'MiniDbuiDb'
      )

      if s.expanded and s.connected then
        add_line(
          lines,
          line_hl,
          string.format('  %s Saved Queries (%d)', s.s_expanded and '▾' or '▸', #s.saved),
          { type = 'node', name = name, node = 'saved' },
          'MiniDbuiSaved'
        )

        if s.s_expanded then
          for _, q in ipairs(s.saved) do
            add_line(lines, line_hl, string.format('    - %s', q), { type = 'query', name = name, val = q })
          end
        end

        for _, schema in ipairs(s.schemas) do
          local ss = s.schema_state[schema]
          add_line(
            lines,
            line_hl,
            string.format('  %s %s', ss.expanded and '▾' or '▸', schema),
            { type = 'schema', name = name, schema = schema },
            'MiniDbuiSchema'
          )

          if ss.expanded then
            add_line(
              lines,
              line_hl,
              '    [Query Scratchpad]',
              { type = 'new_query', name = name, schema = schema },
              'MiniDbuiNewQuery'
            )

            for _, tbl in ipairs(ss.tables) do
              add_line(
                lines,
                line_hl,
                string.format('    - %s', tbl),
                { type = 'table', name = name, schema = schema, val = tbl },
                'MiniDbuiTable'
              )
            end
          end
        end
      end
    end
  end

  vim.bo[state.ui_buf].modifiable = true
  vim.api.nvim_buf_set_lines(state.ui_buf, 0, -1, false, lines)
  vim.api.nvim_buf_clear_namespace(state.ui_buf, ns, 0, -1)

  for l_idx, hl_group in pairs(line_hl) do
    vim.api.nvim_buf_set_extmark(
      state.ui_buf,
      ns,
      l_idx - 1,
      0,
      { end_row = l_idx - 1, end_col = -1, hl_group = hl_group, hl_eol = true, strict = false }
    )
  end
  vim.bo[state.ui_buf].modifiable, vim.bo[state.ui_buf].modified = false, false
end

local function focus_target_win()
  if state.ui_tab and vim.api.nvim_tabpage_is_valid(state.ui_tab) then
    for _, w in ipairs(vim.api.nvim_tabpage_list_wins(state.ui_tab)) do
      if w ~= state.ui_win then
        vim.api.nvim_set_current_win(w)
        return
      end
    end
  end
  vim.cmd('wincmd p')
end

local function open_buffer(name, schema, table_name, query_file)
  local base_url = vim.g.dbs[name]
  if not base_url then
    return
  end

  focus_target_win()

  local buf
  if query_file then
    local filepath = save_path .. '/' .. name .. '/' .. query_file
    vim.cmd('edit ' .. vim.fn.fnameescape(filepath))
    buf = vim.api.nvim_get_current_buf()
  else
    if not state.query_buf or not vim.api.nvim_buf_is_valid(state.query_buf) then
      vim.cmd('enew')
      state.query_buf = vim.api.nvim_get_current_buf()
      buf = state.query_buf
      vim.bo[buf].buftype, vim.bo[buf].bufhidden, vim.bo[buf].swapfile, vim.bo[buf].filetype =
        'nofile', 'hide', false, 'sql'
    else
      vim.api.nvim_set_current_buf(state.query_buf)
      buf = state.query_buf
    end
  end

  if not buf then
    return
  end

  vim.b[buf].db = schema and get_schema_url(base_url, schema) or base_url
  vim.b[buf].db_key_name = name
  vim.b[buf].db_schema_name = schema or ''

  vim.keymap.set('i', '.', function()
    vim.api.nvim_feedkeys('.', 'n', false)
    vim.defer_fn(function()
      local keys = vim.api.nvim_replace_termcodes('<C-x><C-o>', true, false, true)
      vim.api.nvim_feedkeys(keys, 'm', false)
    end, 50)
  end, { buffer = buf, desc = 'Delayed SQL omnicompletion' })

  if table_name and not query_file then
    local query = string.format('SELECT * FROM `%s` LIMIT 10;', table_name)
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

    if #lines == 1 and lines[1] == '' then
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { query })
    else
      vim.api.nvim_buf_set_lines(buf, -1, -1, false, { '', query })
    end

    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_buf_call(buf, function()
          M.exec_query('%DB', 'Table Preview')
        end)
      end
    end)
  end
end
local function finish_connection(name, url)
  vim.g.dbs = vim.tbl_extend('force', vim.g.dbs or {}, { [name] = url })
  local s = state.db_state[name]
  s.schemas, s.schema_state = {}, {}

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

  s.saved, s.connected, s.expanded, s.s_expanded = get_saved_queries(name), true, true, false
  draw()
  vim.notify('Connected to ' .. name, vim.log.levels.INFO)
end

local function toggle_db(name)
  local s, db = state.db_state[name], state.dbs[name]
  if s.connected then
    s.expanded = not s.expanded
    draw()
  else
    vim.notify('Connecting to ' .. name .. '...', vim.log.levels.INFO)
    local url = db:get_connection_cmd()
    if not db.db_host and state.ssh[name] then
      state.ssh[name]:create_tunnel(name, db.db_port, function()
        finish_connection(name, url)
      end)
    else
      finish_connection(name, url)
    end
  end
end

local function on_cr()
  local meta = state.lines_map[vim.api.nvim_win_get_cursor(0)[1]]
  if not meta then
    return
  end

  if meta.type == 'db' then
    toggle_db(meta.name)
  elseif meta.type == 'schema' then
    local ss = state.db_state[meta.name].schema_state[meta.schema]
    ss.expanded = not ss.expanded
    if ss.expanded and #ss.tables == 0 then
      local schema_url = get_schema_url(state.dbs[meta.name]:get_connection_cmd(), meta.schema)
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
    state.db_state[meta.name].s_expanded = not state.db_state[meta.name].s_expanded
    draw()
  elseif meta.type == 'table' then
    open_buffer(meta.name, meta.schema, meta.val, nil)
  elseif meta.type == 'open_buffer' then
    focus_target_win()
    if vim.api.nvim_buf_is_valid(meta.bufnr) then
      vim.api.nvim_set_current_buf(meta.bufnr)
    end
  elseif meta.type == 'query' then
    open_buffer(meta.name, nil, nil, meta.val)
  end
end

function M.save_query()
  local db_name = vim.b.db_key_name
  if not db_name then
    return vim.notify('Not in a DB buffer', vim.log.levels.ERROR)
  end

  if vim.fn.expand('%:p'):match(save_path) then
    vim.cmd('w')
    draw()
    return vim.notify('Query saved', vim.log.levels.INFO)
  end

  vim.ui.input({ prompt = 'Query name (no .sql): ' }, function(input)
    if not input or input == '' then
      return
    end
    vim.cmd('write ' .. save_path .. '/' .. db_name .. '/' .. input .. '.sql')
    state.db_state[db_name].saved = get_saved_queries(db_name)
    draw()
  end)
end

function M.toggle_ui()
  if state.ui_tab and vim.api.nvim_tabpage_is_valid(state.ui_tab) then
    if vim.api.nvim_get_current_tabpage() == state.ui_tab then
      vim.cmd('tabclose')
      state.ui_tab, state.ui_win = nil, nil
    else
      vim.api.nvim_set_current_tabpage(state.ui_tab)
      draw()
    end
    return
  end

  vim.cmd('tabnew')
  state.ui_tab = vim.api.nvim_get_current_tabpage()
  vim.cmd('enew')
  vim.bo[vim.api.nvim_get_current_buf()].buftype = 'nofile'
  vim.bo[vim.api.nvim_get_current_buf()].bufhidden = 'hide'

  vim.cmd('topleft 40vnew')
  state.ui_win, state.ui_buf = vim.api.nvim_get_current_win(), vim.api.nvim_get_current_buf()

  vim.bo[state.ui_buf].buftype = 'nofile'
  vim.bo[state.ui_buf].filetype = 'dbui'
  vim.bo[state.ui_buf].bufhidden = 'hide'
  vim.bo[state.ui_buf].swapfile = false

  pcall(vim.api.nvim_buf_set_name, state.ui_buf, '[DBUI]')
  vim.keymap.set('n', '<CR>', on_cr, { buf = state.ui_buf })
  draw()
end

function M.disconnect(name)
  if state.db_state[name] then
    state.db_state[name].connected, state.db_state[name].expanded = false, false
    draw()
  end
  vim.g.dbs = vim.tbl_filter(function(k)
    return k ~= name
  end, vim.g.dbs or {})
  if ssh_module.active_tunnels[name] then
    ssh_module.active_tunnels[name]:kill('sigterm')
    ssh_module.active_tunnels[name] = nil
  end
end

function M.setup(databases, ssh, db_order)
  state.dbs, state.ssh = databases or {}, ssh or {}
  state.db_order = db_order or vim.tbl_keys(state.dbs)
  for _, name in ipairs(state.db_order) do
    state.db_state[name] =
      { connected = false, expanded = false, schemas = {}, schema_state = {}, saved = {}, s_expanded = false }
  end

  local augroup = vim.api.nvim_create_augroup('MiniDbui', { clear = true })
  vim.api.nvim_create_autocmd('VimLeavePre', { group = augroup, callback = ssh_module.kill_all })
  vim.api.nvim_create_autocmd('WinEnter', {
    group = augroup,
    callback = function()
      if state.ui_win and vim.api.nvim_win_is_valid(state.ui_win) then
        local wins = vim.api.nvim_tabpage_list_wins(0)
        if #wins == 1 and wins[1] == state.ui_win then
          if #vim.api.nvim_list_tabpages() == 1 then
            vim.cmd('quitall!')
          else
            vim.cmd('tabclose')
          end
        end
      end
    end,
  })
  vim.api.nvim_create_autocmd('BufEnter', {
    group = augroup,
    callback = function()
      if state.ui_tab and vim.api.nvim_tabpage_is_valid(state.ui_tab) then
        draw()
      end
    end,
  })
end

_G.custom_sql_omni = function(findstart, base)
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

  for _, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
    for word in line:gmatch('[%w_]+') do
      if word:sub(1, #base) == base and not seen[word] then
        seen[word] = true
        table.insert(results, { word = word, menu = '[Buf]', icase = 1 })
      end
    end
  end
  return results
end

return M
