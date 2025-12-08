local ui = require('utils.ui')
local signs = ui.diagnostic_icons_char
local highlights = ui.diagnostic_hl_char

local qfbufnr
local qfim_namespace = vim.api.nvim_create_namespace('qfim')
local qfim_file_namespace = vim.api.nvim_create_namespace('qfim-file')
local qf_group = vim.api.nvim_create_augroup('qflist', { clear = true })
local last_cmd = ''

--------------------------------------------------
-- Types
--------------------------------------------------

---@alias ListType
---| '"c"' # quickfix list
---| '"l"' # location list

---@class qflist
---@field changedtick number
---@field context table | string
---@field id number
---@field idx number
---@field items vim.quickfix.entry[]
---@field nr number
---@field qfbufnr number
---@field size number
---@field title string
---@field winid number
---@field filewinid? number

--------------------------------------------------
-- Utils
--------------------------------------------------

---@param winid? integer
---@return nil| ListType
local function getListType(winid)
  winid = winid or vim.api.nvim_get_current_win()
  local info = vim.fn.getwininfo(winid)[1]
  if info.quickfix == 0 then
    return nil
  elseif info.loclist == 0 then
    return 'c'
  else
    return 'l'
  end
end

---@param listType ListType
---@param what table
---@param action? " " | "a" | "r"
---@param winid? number
local function setList(listType, what, action, winid)
  action = action or ' '
  if listType == 'c' then
    vim.fn.setqflist({}, action, what)
  else
    vim.fn.setloclist(winid or 0, {}, action, what)
  end
end

---@param listType ListType
---@param nr? number | '$'
---@param winid? number
---@return qflist
local function getList(listType, nr, winid)
  nr = nr or 0
  if listType == 'c' then
    return vim.fn.getqflist({ nr = nr, all = 0 })
  else
    winid = winid or 0
    local ll = vim.fn.getloclist(winid, { nr = nr, all = 0 })
    if not ll.filewinid then
      ll.filewinid = -1
    end
    return ll
  end
end

-- NOTE: This supposes only one list is opened, if there is more than one quickfix wins
---@return qflist
local function getActiveList()
  local qflist = getList('c')
  local loclist = getList('l')

  local wintype = getListType()
  if wintype == 'c' then
    return qflist
  elseif wintype == 'l' then
    return loclist
  -- If loclist is empty, use quickfix
  elseif loclist.size == 0 then
    return qflist
  -- If quickfix is empty, use loclist
  elseif qflist.size == 0 then
    return loclist
  elseif qflist.winid ~= 0 then
    if loclist.winid == 0 then
      return qflist
    end
  elseif loclist.winid ~= 0 then
    return loclist
  end
  -- They're either both empty or both open
  return qflist
end

---@param listType ListType
---@param severity? vim.diagnostic.SeverityFilter
---@return qflist | nil
local function getDiagList(listType, severity)
  severity = severity or vim.diagnostic.severity.HINT
  local size = listType == 'c' and vim.fn.getqflist({ nr = '$' }).nr or vim.fn.getloclist(0, { nr = '$' }).nr
  for i = size, 1, -1 do
    local list = getList(listType, i)
    if
      list.context ~= ''
      and list.context.qfim_diag
      and list.context.qfim_diag.type == listType
      and list.context.qfim_diag.severity == severity
    then
      return list
    end
  end
end

---@param list qflist
---@return boolean
local function isDiffTool(list)
  return list.title:find('difftool') ~= nil
end

--------------------------------------------------
-- Better Grep
--------------------------------------------------

vim.opt.grepprg = 'rg --vimgrep --smart-case --hidden'
vim.opt.grepformat = '%f:%l:%c:%m'

---@param listType 'c' | 'l'
---@param args table
local function grep(listType, args)
  local async = require('vim._async')

  async.run(function()
    local grepprg = vim.o.grepprg
    local cmd = vim.split(grepprg, '%s+', { trimempty = true })

    for _, arg in ipairs(args) do
      if arg:match("^['\"].*['\"]$") then
        arg = arg:sub(2, -2)
      end
      table.insert(cmd, arg)
    end
    table.insert(cmd, '--fixed-strings')

    local batch_size = 500
    local chunk = {}
    local action = ' '

    local result = async.await(3, vim.system, cmd, {
      text = true,
      stdout = function(err, data)
        assert(not err)
        if data then
          local lines = vim.split(data, '\n', { trimempty = true })
          if #lines > 0 then
            for _, line in ipairs(lines) do
              table.insert(chunk, line)
            end
          end
        end

        local process = {}
        for i = 1, batch_size do
          process[i] = chunk[i]
        end

        if #chunk >= batch_size then
          local new_chunk = {}
          for i = batch_size + 1, #chunk do
            table.insert(new_chunk, chunk[i])
          end
          chunk = new_chunk
        else
          chunk = {}
        end

        vim.schedule(function()
          if #process > 0 or data ~= nil then
            setList(listType, {
              lines = not data and chunk or process,
              efm = vim.o.errorformat,
            }, action)
            action = 'a'
          end
        end)
      end,
    })

    if result.code ~= 0 then
      vim.notify('Grep failed with exit code: ' .. result.code, vim.log.levels.ERROR)
    end
  end)
end

vim.api.nvim_create_user_command('Rg', function(opts)
  grep('c', opts.fargs)
end, { nargs = '+', complete = 'file_in_path' })

vim.api.nvim_create_user_command('LRg', function(opts)
  grep('l', opts.fargs)
end, { nargs = '+', complete = 'file_in_path' })

vim.keymap.set('n', '<leader>rg', ':Rg ', { desc = '[R]efactor [G]rep' })

--------------------------------------------------
-- Treesitter highlighting
--------------------------------------------------

---@class uim.TSHighlight
---@field [1] integer start_col
---@field [2] integer end_col
---@field [3] string highlight group

local _cached_queries = {}
---@param lang string
---@return vim.treesitter.Query?
local function get_highlight_query(lang)
  local query = _cached_queries[lang]
  if query == nil then
    query = vim.treesitter.query.get(lang, 'highlights') or false
    _cached_queries[lang] = query
  end
  if query then
    return query
  end
end

---@param bufnr integer
---@param lnum integer
---@return uim.TSHighlight[]
local function buf_get_ts_highlights(bufnr, lnum)
  local filetype = vim.bo[bufnr].filetype
  if not filetype or filetype == '' then
    filetype = vim.filetype.match({ buf = bufnr }) or ''
  end
  local lang = vim.treesitter.language.get_lang(filetype) or filetype
  if lang == '' then
    return {}
  end
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, lang)
  if not ok or not parser then
    return {}
  end

  local row = lnum - 1
  if not parser:is_valid() then
    parser:parse(true)
  end

  local hls = {}
  parser:for_each_tree(function(tstree, tree)
    if not tstree then
      return
    end

    local root_node = tstree:root()
    local root_start_row, _, root_end_row, _ = root_node:range()

    -- Only worry about trees within the line range
    if root_start_row > row or root_end_row < row then
      return
    end

    local query = get_highlight_query(tree:lang())

    -- Some injected languages may not have highlight queries.
    if not query then
      return
    end

    for capture, node, metadata in query:iter_captures(root_node, bufnr, row, root_end_row + 1) do
      if capture == nil then
        break
      end

      local range = vim.treesitter.get_range(node, bufnr, metadata[capture])
      local start_row, start_col, _, end_row, end_col, _ = unpack(range)
      if start_row > row then
        break
      end
      local capture_name = query.captures[capture]
      local hl = string.format('@%s.%s', capture_name, tree:lang())
      if end_row > start_row then
        end_col = -1
      end
      table.insert(hls, { start_col, end_col, hl })
    end
  end)

  return hls
end

--------------------------------------------------
-- Better Quickfix Window Style
--------------------------------------------------

local GIT_STATUS_MAP = {
  ['A'] = 'ADDED',
  ['B'] = 'BROKEN',
  ['C'] = 'COPIED',
  ['D'] = 'DELETED',
  ['M'] = 'MODIFIED',
  ['R'] = 'RENAMED',
  ['T'] = 'CHANGED',
  ['U'] = 'UNMERGED',
  ['X'] = 'UNKNOWN',
}

-- from https://www.reddit.com/r/neovim/comments/1klka38/tinkering_quickfix_ui/
--- @param list vim.quickfix.entry[]
local function add_virt_lines(list)
  vim.api.nvim_buf_clear_namespace(qfbufnr, qfim_file_namespace, 0, -1)
  local lastfname = ''
  for i, item in ipairs(list) do
    local fname = vim.fn.bufname(item.bufnr)
    fname = vim.fn.fnamemodify(fname, ':p:~:.')
    if fname ~= '' and fname ~= lastfname then
      lastfname = fname
      local path = vim.fn.fnamemodify(fname, ':h')
      if path == '.' then
        path = ''
      end
      local name = vim.fn.fnamemodify(fname, ':p:t')
      vim.api.nvim_buf_set_extmark(qfbufnr, qfim_file_namespace, i - 1, 0, {
        virt_lines = { { { name .. ' ', 'qfFileName' }, { path, 'Comment' } } },
        virt_lines_above = true,
        strict = false,
      })
    end
  end
  vim.api.nvim_feedkeys(vim.keycode('<C-u>'), 'm', true)
end

-- workaround for cannot scroll to see virtual line before first line - see https://github.com/neovim/neovim/issues/16166
vim.api.nvim_create_autocmd('CursorMoved', {
  group = qf_group,
  callback = function()
    if vim.bo.filetype ~= 'qf' then
      return
    end
    local row = unpack(vim.api.nvim_win_get_cursor(0))
    if row == 1 then
      vim.api.nvim_feedkeys(vim.keycode('<C-u>'), 'm', true)
    end
  end,
  desc = 'Show first virtual line',
})

---@param items vim.quickfix.entry[]
---@param i integer
---@param stop boolean
local function hl_line(items, i, stop)
  if stop and i == 100 then return end
  local item = table.remove(items, 1)
  if not item then
    return
  end

  local text_space = 2
  if item.lnum > 0 then
    text_space = #tostring(item.lnum) + 4
    vim.hl.range(qfbufnr, qfim_namespace, 'CursorLineNr', { i, 0 }, { i, text_space })
  end
  local default_hl = 'CursorLineNr'
  if item.type ~= '' then
    default_hl = highlights[item.type]
  else
    -- TS highlight
    if not vim.api.nvim_buf_is_loaded(item.bufnr) then
      vim.fn.bufload(item.bufnr)
    end

    local src_line = vim.api.nvim_buf_get_lines(item.bufnr, item.lnum - 1, item.lnum, false)[1]
    if src_line then
      -- I trim spaces so I need to take that into account before comparing
      -- (if the og line has spaces at the end it deserves to not be found)
      local src_space = src_line:match('^%s*'):len()
      -- Only add highlights if the text in the quickfix matches the source line
      if item.text == src_line:sub(src_space + 1) then
        local offset = text_space - src_space
        local ok, hls = pcall(buf_get_ts_highlights, item.bufnr, item.lnum)
        if ok then
          for _, hl in ipairs(hls) do
            local start_col, end_col, hl_group = hl[1], hl[2], hl[3]
            if end_col == -1 then
              end_col = src_line:len()
            end
            vim.hl.range(qfbufnr, qfim_namespace, hl_group, { i, start_col + offset }, { i, end_col + offset })
          end
          vim.defer_fn(function()
            hl_line(items, i + 1, stop)
          end, 10)
          return
        end
      end
    end
  end
  vim.hl.range(qfbufnr, qfim_namespace, default_hl, { i, text_space }, { i, vim.o.columns })
  hl_line(items, i + 1, stop)
end

function _G.quickfixtextfunc(info)
  local listType = info.quickfix == 1 and 'c' or 'l'
  local list = getList(listType, nil, info.winid)
  if list.context == '' and last_cmd ~= '' then
    setList(listType, {
      context = { last_cmd = last_cmd },
    }, 'a')
  end
  qfbufnr = list.qfbufnr
  local diffs
  local isDiff = isDiffTool(list)
  if isDiff then
    diffs = vim.system({ 'git', 'diff', '--numstat' }, { text = true }):wait()
    diffs = vim.split(diffs.stdout, '\n')
    diffs = vim.iter(diffs):rskip(1):fold({}, function(acc, diff)
      diff = vim.split(diff, '\t')
      acc[vim.fn.bufnr(diff[3])] = { added = diff[1], removed = diff[2] }
      return acc
    end)
  end
  local validFmt = '  %s%s%s'
  list = list.items
  local ret = {}
  for i = info.start_idx, info.end_idx do
    local l = list[i]
    if not isDiff then
      list[i].text = vim.trim(l.text)
    elseif diffs and diffs[l.bufnr] then
      list[i].text = (GIT_STATUS_MAP[l.text:sub(1, 1)] or '')
        .. ' (+'
        .. diffs[l.bufnr].added
        .. '-'
        .. diffs[l.bufnr].removed
        .. ')'
    else
      list[i].text = GIT_STATUS_MAP[l.text:sub(1, 1)]
    end
    local icon = l.type == '' and '' or (signs[l.type] and signs[l.type] or signs.I)
    local lnum = l.lnum > 0 and tostring(l.lnum) .. ': ' or ''
    local str = validFmt:format(lnum, icon, l.text)
    table.insert(ret, str)
  end
  vim.defer_fn(function()
    vim.api.nvim_buf_clear_namespace(qfbufnr, qfim_namespace, 0, -1)
    add_virt_lines(list)
    hl_line(list, 0, vim.fn.has('win32') == 1)
  end, 10)
  return ret
end

vim.o.quickfixtextfunc = '{info -> v:lua._G.quickfixtextfunc(info)}'

--------------------------------------------------
-- Keymaps
--------------------------------------------------

local function document_symbols()
  vim.lsp.buf.document_symbol({
    on_list = function(options)
      local items = options.items

      local seen = {}
      local out = {}
      for _, item in ipairs(items) do
        local v = item.kind
        if v ~= nil and not seen[v] then
          seen[v] = true
          table.insert(out, v:lower())
        end
      end

      ---@diagnostic disable-next-line: unused-local
      function _G.qf_symbols_completion(cmdarg)
        return out
      end

      vim.ui.input(
        { prompt = 'File Search: ', completion = 'customlist,v:lua._G.qf_symbols_completion' },
        function(input)
          if not input then
            return
          end
          items = vim.tbl_filter(function(item)
            return input == string.lower(item.kind)
          end, items)
          if vim.tbl_isempty(items) then
            vim.notify('No ' .. input .. ' Symbols in the Document', vim.lsp.log_levels.WARN)
            return
          end
          items = vim.tbl_map(function(item)
            item.text = vim.fn.trim(vim.fn.getline(item.lnum))
            return item
          end, items)
          vim.fn.setloclist(0, {}, ' ', { title = 'Document Symbols: ' .. input:upper(), items = items })
          vim.schedule(function()
            vim.cmd('lopen')
          end)
        end
      )
    end,
  })
end

---@param listType ListType
---@param diagnostics? boolean
---@param severity? vim.diagnostic.SeverityFilter
---@param scope? string
local function list_toggle(listType, diagnostics, severity, scope)
  local list = getList(listType)
  if list.winid ~= 0 then
    vim.cmd(listType .. 'close')
  elseif diagnostics then
    last_cmd = ''
    severity = severity or vim.diagnostic.severity.HINT
    local diag_where = listType == 'l' and 0 or nil
    local diag_list = vim.diagnostic.get(diag_where, { severity = { min = severity } })
    if scope then
      diag_list = vim
        .iter(diag_list)
        :filter(function(v)
          return vim.startswith(vim.api.nvim_buf_get_name(v.bufnr), scope)
        end)
        :totable()
    end
    if #diag_list == 0 then
      vim.notify('List is Empty', vim.log.levels.INFO)
      return
    end
    local qf_diag_list = getDiagList(listType, severity)
    local action = ' '
    if qf_diag_list then
      -- NOTE: looks like a nvim bug that #chistory redraws the qf
      vim.cmd(('silent %s%shistory'):format(qf_diag_list.nr, listType))
      action = 'r'
    end
    local title = ('%s Diagnostics (%s)'):format(listType == 'c' and 'Workspace' or 'Local', severity)
    setList(listType, {
      title = title,
      items = vim.diagnostic.toqflist(diag_list),
      context = { qfim_diag = { type = listType, severity = severity, scope = scope } },
    }, action)
    vim.cmd(listType .. 'open')
  elseif list.size == 0 then
    vim.notify('List is Empty', vim.log.levels.INFO)
  else
    vim.cmd(listType .. 'open')
  end
end

---@param listType ListType
local function moveToList(listType)
  local list = getList(listType)
  local win = list.winid
  if vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_set_current_win(win)
  end
end

vim.keymap.set('n', '<leader>qq', function()
  list_toggle('c')
end, { desc = 'Toggle [Q]uickfix' })
vim.keymap.set('n', '<leader>qd', function()
  list_toggle('c', true)
end, { desc = '[Q]uickfix [D]iagnostics Toggle' })
vim.keymap.set('n', '<leader>qe', function()
  list_toggle('c', true, vim.diagnostic.severity.ERROR)
end, { desc = '[Q]uickfix [E]rror Toggle' })
vim.keymap.set('n', '<leader>qE', function()
  list_toggle('c', true, vim.diagnostic.severity.ERROR, vim.fn.expand('%:p:h'))
end, { desc = '[Q]uickfix [E]rror Toggle' })
vim.keymap.set('n', '<leader>qb', function()
  moveToList('c')
end, { desc = 'Move to [Q]uickfix [B]uffer' })

vim.keymap.set('n', '<leader>ll', function()
  list_toggle('l')
end, { desc = 'Toggle [L]ocation List' })
vim.keymap.set('n', '<leader>ld', function()
  list_toggle('l', true)
end, { desc = '[L]ocation List [D]iagnostics Toggle' })
vim.keymap.set('n', '<leader>ls', document_symbols, { desc = '[L]ocation List [S]ymbols' })
vim.keymap.set('n', '<leader>lb', function()
  moveToList('l')
end, { desc = 'Move to [L]ocation List [B]uffer' })

---@param listType? ListType
local function addToQuickfix(listType)
  listType = listType or 'c'
  local cursor_pos = vim.fn.getpos('.')
  local new_qf_item = {
    {
      bufnr = vim.api.nvim_get_current_buf(),
      lnum = cursor_pos[2],
      col = cursor_pos[3],
      text = vim.fn.getline('.'),
    },
  }
  setList(listType, { items = new_qf_item }, 'a')
  local list = getList(listType)
  if list.winid ~= 0 then
    vim.schedule(function()
      vim.cmd(listType .. 'open') -- needed to rerender highlights
      vim.cmd(list.size .. listType .. listType) -- don't know if if should enter or keep the same qfitem position
    end)
  end
end

vim.keymap.set('n', '<leader>qa', addToQuickfix, { desc = '[A]dd cursor position to [Q]uickfix List' })
vim.keymap.set('n', '<leader>la', function()
  addToQuickfix('l')
end, { desc = '[A]dd cursor position to [L]ocation List' })

-- NOTE: implement something similar to compare branches: https://gist.github.com/jmacadie/6f934282870f0d481599c8339ef61f64
-- and/or other commits: https://github.com/jecaro/fugitive-difftool.nvim
vim.keymap.set('n', '<leader>qg', function()
  vim.cmd('tabedit | Git difftool --name-status')
  -- vim.cmd('tabedit | Git difftool --numstat --raw')
  -- would be cool to have status and numstat in the same command, but looks like it's not possible
  -- git diff --numstat --summary is difficult to parse (renaming is a mess)
end, { desc = 'Open [Q]uickfix With [G]it Diff' })

--------------------------------------------------
-- Quickfix Options
--------------------------------------------------

---@return number
local function getHeight()
  local lines = vim.api.nvim_buf_get_lines(qfbufnr, 0, -1, false)
  local extmarks = vim.api.nvim_buf_get_extmarks(qfbufnr, qfim_file_namespace, 0, -1, { details = true })
  return math.max(math.min(#lines + #extmarks, 10), 5)
end

function _G.qffoldexprfunc()
  local extmarks = vim.api.nvim_buf_get_extmarks(qfbufnr, qfim_file_namespace, 0, -1, {})
  local line = vim.v.lnum
  for _, ext in ipairs(extmarks) do
    if line == ext[2] then
      return '<1'
    elseif line == ext[2] + 1 then
      return '>1'
    end
  end
  return '1'
end

function _G.qffoldtextfunc()
  local extmarks = vim.api.nvim_buf_get_extmarks(qfbufnr, qfim_file_namespace, 0, -1, { details = true })
  for _, ext in ipairs(extmarks) do
    if vim.v.foldstart == ext[2] + 1 then
      local virt_lines = ext[4].virt_lines[1]
      local lines = vim.v.foldend - vim.v.foldstart + 1
      table.insert(virt_lines, { ' [' .. lines .. (lines == 1 and ' line]' or ' lines]'), 'Label' })
      return virt_lines
    end
  end
end

vim.api.nvim_create_autocmd('BufWinEnter', {
  group = qf_group,
  pattern = 'quickfix',
  callback = function(args)
    -- NOTE: add an autcmd to autoclose preview window
    -- NOTE: no se puede usar args.buf porque aparentemente la ventana se abre varias veces ?
    vim.defer_fn(function()
      if not qfbufnr then
        return
      end
      local qfwinid = vim.fn.bufwinid(qfbufnr)
      if not vim.api.nvim_win_is_valid(qfwinid) then
        return
      end
      vim.cmd('wincmd J')
      vim.api.nvim_win_set_height(0, getHeight())
      vim.api.nvim_set_option_value('previewheight', 10, { scope = 'global' })
      vim.api.nvim_set_option_value('hidden', true, { scope = 'global' })
      vim.api.nvim_set_option_value('buflisted', false, { buf = args.buf, scope = 'local' })
      vim.api.nvim_set_option_value('winfixheight', true, { win = qfwinid, scope = 'local' })
      vim.api.nvim_set_option_value('winfixbuf', true, { win = qfwinid, scope = 'local' })
      vim.api.nvim_set_option_value('foldmethod', 'expr', { win = qfwinid, scope = 'local' })
      vim.api.nvim_set_option_value('foldminlines', 0, { win = qfwinid, scope = 'local' })
      vim.api.nvim_set_option_value('foldexpr', 'v:lua._G.qffoldexprfunc()', { win = qfwinid, scope = 'local' })
      vim.api.nvim_set_option_value('foldtext', 'v:lua._G.qffoldtextfunc()', { win = qfwinid, scope = 'local' })
      vim.api.nvim_set_option_value('signcolumn', 'no', { win = qfwinid, scope = 'local' })
      vim.api.nvim_set_option_value('statuscolumn', '', { win = qfwinid, scope = 'local' })
      vim.api.nvim_set_option_value('number', true, { win = qfwinid, scope = 'local' })
      vim.api.nvim_set_option_value('relativenumber', false, { win = qfwinid, scope = 'local' })
    end, 10)
  end,
  desc = 'Qf options',
})

--------------------------------------------------
-- Keymaps inside Quickfix
--------------------------------------------------

-- NOTE: take into account that this messes up with the error numbers
---@param file boolean remove all items in file
local function delete(file)
  local listType = getListType()
  if not listType then
    return
  end
  local list = getList(listType)
  local qfitems = list.items

  local mode = vim.api.nvim_get_mode().mode
  if mode == 'v' or mode == 'V' then
    local visual_start = vim.fn.getpos('v')
    local visual_end = vim.fn.getpos('.')
    for i = visual_start[2], visual_end[2] do
      qfitems[i] = vim.empty_dict()
    end
    qfitems = vim.tbl_filter(function(item)
      return not vim.tbl_isempty(item)
    end, qfitems)
    setList(listType, { items = qfitems }, 'r', list.filewinid)
    vim.api.nvim_input('<Esc>')
  else
    local cursor = vim.api.nvim_win_get_cursor(0)
    local line = cursor[1]
    if file then
      local bufnr = qfitems[line].bufnr
      qfitems = vim
        .iter(qfitems)
        :filter(function(item)
          return item.bufnr ~= bufnr
        end)
        :totable()
    else
      table.remove(qfitems, line)
    end
    setList(listType, { items = qfitems }, 'r', list.filewinid)
    local new_pos = line > #qfitems and #qfitems or line
    vim.api.nvim_win_set_cursor(0, { new_pos, 0 })
  end
end

local function getPreview()
  local wins = vim.api.nvim_list_wins()
  for _, win in ipairs(wins) do
    if vim.api.nvim_get_option_value('previewwindow', { win = win }) then
      return win
    end
  end
  return nil
end

local function openPreview()
  local qfLinenr = vim.fn.line('.')
  local list = getActiveList().items
  if qfLinenr > #list then
    vim.notify('Error retriving list items', vim.log.levels.WARN)
    return
  end
  local path = vim.fn.bufname(list[qfLinenr].bufnr)
  local line = list[qfLinenr].lnum
  vim.cmd('keepjumps aboveleft pedit +' .. line .. ' ' .. path)
  local preview_win = getPreview()
  if not preview_win then
    vim.notify('Error opening the preview window', vim.log.levels.WARN)
    return
  end
  local preview_buf = vim.api.nvim_win_get_buf(preview_win)
  vim.api.nvim_set_option_value('buflisted', false, { buf = preview_buf })
end

---@param direction 1 | -1
local function moveWithPreview(direction)
  local current_pos = vim.fn.getcurpos()
  local move_line = current_pos[2] + direction
  local list_size = getActiveList().size
  if move_line < 1 then
    move_line = list_size
  elseif move_line > list_size then
    move_line = 1
  end
  vim.api.nvim_win_set_cursor(0, { move_line, 0 })
  openPreview()
end

local function openAsDiff()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.startswith(vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win)), 'fugitive:') then
      vim.api.nvim_win_close(win, true)
    end
  end
  vim.cmd('. cc | Gvdiffsplit')
end

---@param winnr integer
---@return integer
local function get_prev_win(winnr)
  local prev_win = vim.fn.win_getid(vim.fn.winnr('#'))
  if prev_win <= 0 or vim.fn.win_gettype(prev_win) ~= '' then
    local tab = vim.fn.getwininfo(winnr)[1].tabnr
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
      if vim.fn.win_gettype(win) == '' then
        prev_win = win
        break
      end
    end
  end
  return prev_win
end

---@class SelectItemOpts
---@field keep_cursor? boolean false by default
---@field split? "v" | "h" nil by default
---@field close? boolean false by default

---@param selectItemOpts SelectItemOpts
local function selectItem(selectItemOpts)
  local opts = selectItemOpts or {}
  local qftype = getListType()
  if not qftype then
    return
  end
  local qflist = getList(qftype)
  if isDiffTool(qflist) then
    openAsDiff()
    return
  end
  local qfitempos = vim.fn.getpos('.')
  local preview = getPreview()
  if preview then
    vim.cmd('pclose')
  end
  if not opts.split then
    vim.cmd('.' .. qftype .. qftype)
  else
    local prev_win = qflist.filewinid or get_prev_win(qflist.winid)
    if prev_win and prev_win > 0 and vim.fn.win_gettype(prev_win) == '' then
      local item = qflist.items[qfitempos[2]]
      local split = vim.api.nvim_open_win(item.bufnr, false, { win = prev_win, vertical = opts.split == 'v' })
      vim.cmd('.' .. qftype .. qftype)
      if opts.keep_cursor then
        vim.api.nvim_set_current_win(qflist.winid)
      end
    end
  end
  vim.schedule(function()
    if opts.close then
      local listType = getActiveList().filewinid and 'l' or 'c'
      vim.cmd(listType .. 'close')
    elseif opts.keep_cursor and not opts.split then
      vim.api.nvim_set_current_win(qflist.winid)
    end
  end)
end

local function closeList()
  local listType = getListType()
  if not listType then
    return
  end
  local list = getList(listType)
  if isDiffTool(list) then
    pcall(vim.cmd.tabclose)
    return
  end
  local preview = getPreview()
  if preview then
    vim.cmd('pclose')
  end
  vim.cmd.close()
end

---@param direction 'older'|'newer'
local function listHistory(direction)
  local listType = getListType()
  if not listType then
    return
  end
  local listCount = getList(listType, '$').nr
  if listCount == 1 then
    vim.notify('There is only one list in the history', vim.log.levels.WARN)
    return
  end
  local listNr = getList(listType).nr
  if listNr == 1 and direction == 'older' then
    direction = 'newer ' .. (listCount - 1)
  elseif listNr >= listCount and direction == 'newer' then
    direction = 'older ' .. (listCount - 1)
  end
  vim.cmd(listType .. direction)
end

---@param what 'message' | 'file'
local function yank(what)
  local listType = getListType()
  if not listType then
    return
  end
  local list = getList(listType)
  local line = vim.api.nvim_win_get_cursor(0)
  local qfitem = list.items[line[1]]
  local text = what == 'message' and vim.trim(qfitem.text)
    or vim.fn.fnamemodify(vim.api.nvim_buf_get_name(qfitem.bufnr), ':.')
  vim.fn.setreg('', text)
end

local function refresh()
  local listType = getListType()
  if not listType then
    return
  end
  local list = getList(listType)
  if list.context == '' then
    return
  end
  if list.context.qfim_diag and list.context.qfim_diag.type == listType then
    local diag_where = listType == 'l' and 0 or nil
    local severity = list.context.qfim_diag.severity
    local scope = list.context.qfim_diag.scope
    local diag_list = vim.diagnostic.get(diag_where, { severity = { min = severity } })
    if scope then
      diag_list = vim
        .iter(diag_list)
        :filter(function(v)
          return vim.startswith(vim.api.nvim_buf_get_name(v.bufnr), scope)
        end)
        :totable()
    end
    setList(listType, {
      items = vim.diagnostic.toqflist(diag_list),
    }, 'r')
    if #diag_list == 0 then
      vim.notify('List is now Empty', vim.log.levels.INFO)
      vim.cmd(listType .. 'close')
    end
  elseif list.context.last_cmd then
    vim.cmd(list.context.last_cmd)
  end
end

local file_name
local function searchFileName(search)
  local curr_pos = vim.api.nvim_win_get_cursor(0)
  local extmarks =
    vim.api.nvim_buf_get_extmarks(0, qfim_file_namespace, curr_pos, -1, { details = true, type = 'virt_lines' })
  for _, extmark in ipairs(extmarks) do
    local text = extmark[4].virt_lines[1]
    for _, e in ipairs(text) do
      if e[1]:find(search) then
        vim.api.nvim_win_set_cursor(0, { extmark[2] + 1, 0 })
        file_name = search
        return
      end
    end
  end
  file_name = nil
end

local function searchFile()
  vim.ui.input({ prompt = 'File Search: ' }, function(input)
    if not input then
      return
    end
    searchFileName(input)
  end)
end

local function repeatSearchFileName()
  if not file_name then
    vim.notify('No text to search', vim.log.levels.INFO)
  end
  searchFileName(file_name)
end

---@param direction 'next'|'prev'
local function moveAdyacentFile(direction)
  local curr_pos = vim.api.nvim_win_get_cursor(0)
  local start = direction == 'next' and curr_pos or 0
  local end_ = direction == 'next' and -1 or curr_pos
  local extmarks = vim.api.nvim_buf_get_extmarks(0, qfim_file_namespace, start, end_, { type = 'virt_lines' })
  local extmarkPos = direction == 'next' and 1 or #extmarks - 1
  vim.api.nvim_win_set_cursor(0, { extmarks[extmarkPos][2] + 1, 0 })
end

vim.api.nvim_create_autocmd('BufWinEnter', {
  group = qf_group,
  pattern = 'quickfix',
  callback = function()
    vim.keymap.set('n', 'q', closeList, { buffer = 0, desc = 'Close QF list' })
    vim.keymap.set('n', '<CR>', selectItem, { buffer = 0, desc = 'Open QF item' })
    vim.keymap.set('n', '<C-s>', function()
      selectItem({ split = 'h' })
    end, { buffer = 0, desc = 'Open QF Item in Horizontal [S]plit' })
    vim.keymap.set('n', '<C-v>', function()
      selectItem({ split = 'v' })
    end, { buffer = 0, desc = 'Open QF Item in [V]ertical Split' })
    vim.keymap.set('n', 'o', function()
      selectItem({ close = true })
    end, { buffer = 0, desc = 'Open and Close QF' })
    vim.keymap.set('n', 'O', function()
      selectItem({ keep_cursor = true })
    end, { buffer = 0, desc = 'Open and Stay in QF' })
    vim.keymap.set('n', '<C-n>', function()
      moveWithPreview(1)
    end, { buffer = 0, desc = 'Move and Preview Next QF Item' })
    vim.keymap.set('n', '<C-p>', function()
      moveWithPreview(-1)
    end, { buffer = 0, desc = 'Move and Preview Previous QF Item' })
    vim.keymap.set('n', ']]', function()
      moveAdyacentFile('next')
    end, { buffer = 0, desc = 'Move to QF Item in Next File' })
    vim.keymap.set('n', '[[', function()
      moveAdyacentFile('prev')
    end, { buffer = 0, desc = 'Move to QF Item in Previous File' })
    vim.keymap.set('n', '<C-o>', function()
      listHistory('older')
    end, { buffer = 0, desc = 'Open Older List' })
    vim.keymap.set('n', '<C-i>', function()
      listHistory('newer')
    end, { buffer = 0, desc = 'Open Newer List' })
    vim.keymap.set('n', 'p', openPreview, { buffer = 0, desc = 'Open and Close QF' })
    vim.keymap.set('n', 'dd', delete, { buffer = 0, desc = 'Delete QF Item' })
    vim.keymap.set('n', 'D', function()
      delete(true)
    end, { buffer = 0, desc = 'Delete QF Items in Same Buffer' })
    vim.keymap.set('x', 'd', delete, { buffer = 0, desc = 'Delete QF Item' })
    vim.keymap.set('n', 'yf', function()
      yank('file')
    end, { buffer = 0, desc = 'Yank Item File' })
    vim.keymap.set('n', 'ym', function()
      yank('message')
    end, { buffer = 0, desc = 'Yank Item Message' })
    vim.keymap.set('n', 'gd', openAsDiff, { buffer = 0, desc = '[G]it [D]iff' })
    vim.keymap.set('n', 'r', refresh, { buffer = 0, desc = '[R]eload List' })
    vim.keymap.set('n', 'g/', searchFile, { buffer = 0, desc = 'Search File Names' })
    vim.keymap.set('n', 'gn', repeatSearchFileName, { buffer = 0, desc = 'Search File Names Again' })
  end,
  desc = 'Keymaps inside quickfix window',
})

--------------------------------------------------
-- Extras
--------------------------------------------------

vim.api.nvim_create_autocmd('QuickFixCmdPost', {
  group = qf_group,
  callback = function(args)
    vim.schedule(function()
      local listType = vim.startswith(args.match, 'l') and 'l' or 'c'
      local list = getList(listType)
      if list.size == 0 then
        vim.notify('No results found', vim.log.levels.WARN)
      else
        vim.cmd(listType .. 'open')
      end
    end)
  end,
  desc = 'Open List Windows automatically',
})

vim.api.nvim_create_autocmd('WinEnter', {
  group = qf_group,
  callback = function()
    if vim.bo.filetype == 'qf' and vim.fn.winnr('$') == 1 then
      vim.cmd('quit')
    end
  end,
  desc = 'Close Neovim if the last window is a quickfix window',
})

vim.api.nvim_create_autocmd('WinClosed', {
  group = qf_group,
  callback = function(opt)
    local loclist = vim.fn.getloclist(tonumber(opt.file) or 0, { winid = 0 })
    if loclist and loclist.winid ~= 0 then
      vim.cmd('close ' .. loclist.winid)
    end
  end,
  desc = 'Close location list if parent window is closed',
})

--------------------------------------------------
-- Features
--------------------------------------------------

-- grep commands: Rg, LRg & <leader>rg
-- qf style
-- toggle qf/ll and diagnostics and list symbols (functions)
-- qf/ll next/prev item/file-item with wrapping
-- add cursor position to qf/ll
-- update diagnostics in qf and ll (for buffer errors)
-- folding
-- qf/ll options
-- preview, preview on move, preview on hover
-- open item, with splits, staying, moving and/or closing
-- delete item from qf
-- update qf list position on cursor move
-- close neovim if qf is the last window (check what happens on bdel)
-- close ll if parent window is closed
-- maybe open the qf window automatically after :make, :grep, :lvimgrep
--          and friends if there are valid locations/errors
-- decide in which window to open an item

--------------------------------------------------
-- Ideas to Implement
--------------------------------------------------

-- shorten filepaths for better legibility (qf.vim) -- don't like it, but can use pathshorten
-- have qf win ALWAYS on bottom, when opened in split or when creating new splits
-- make possible to undo deleted qf items
-- highlight messages (it is even possible?)
-- make it possible to have only one set of keymaps that understand if you want to use qf or loclist
--          (considering which list is open or which is not open and have a fallback just in case)
-- not sure about making qf editable like replacer.nvim
-- show definition, references, implementations, type definition and declarations from word under the cursor (trouble)
-- use buf_request_all for definitions/symbols/etc for async requests
-- use qf to list buffers and/or open buffers
-- use more the api and less cmd/vim.fn
-- use more keepjumps in cmd (https://github.com/ronakg/quickr-preview.vim/blob/master/after/ftplugin/qf.vim#L190)
-- https://yutkat.github.io/my-neovim-pluginlist/quickfix_location.html

-- location list
-- make every qf feature available for location windows too (qf.vim)

--------------------------------------------------
-- Credits
--------------------------------------------------
-- https://github.com/romainl/vim-qf (taken a lot of viml code of it)
-- https://github.com/yorickpeterse/nvim-pqf/tree/main (to make highlighting in lua)
-- https://github.com/ashfinal/qfview.nvim (for the folding code)
-- https://github.com/ten3roberts/qf.nvim (for some ideas)
-- https://github.com/folke/trouble.nvim (for the hover idea)
-- https://github.com/stevearc/qf_helper.nvim (sync qflist cursor position)
-- https://github.com/neovim/nvim-lspconfig/issues/69#issuecomment-1877781941 (diagnostics autoupdate)
-- https://github.com/stevearc/quicker.nvim/blob/master/lua/quicker/highlight.lua#L25 (ts highlighting)
-- https://github.com/glepnir/nvim/blob/main/lua/private/grep.lua (async grep)
