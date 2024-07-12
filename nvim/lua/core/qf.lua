--------------------------------------------------
-- Types
--------------------------------------------------

---@alias ListType
---| '"c"' # quickfix list
---| '"l"' # location list

---@class qfitem
---@field bufnr number
---@field module string
---@field lnum number
---@field end_lnum number
---@field col number
---@field end_col number
---@field vcol 0 | 1
---@field nr number
---@field pattern string
---@field text string
---@field type string
---@field valid boolean
---@field user_data any

---@class qflist
---@field changedtick number
---@field context table | string
---@field id number
---@field idx number
---@field items qfitem[]
---@field nr number
---@field qfbufnr number
---@field quickfixtextfunc string
---@field size number
---@field title string
---@field winid number
---@field filewinid? number

--------------------------------------------------
-- "Global" variables in this file
--------------------------------------------------

local signs = {
  E = ' ',
  W = ' ',
  H = '',
  I = ' ',
}

local highlights = {
  E = 'DiagnosticError',
  W = 'DiagnosticWarn',
  H = 'DiagnosticHint',
  I = 'DiagnosticInfo',
}

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

---@return number[], number[]
local function getListsWin()
  local current_win = vim.api.nvim_get_current_win()
  local current_tab = vim.fn.getwininfo(current_win)[1].tabnr
  local qfwin, llwin = {}, {}
  for _, win_data in ipairs(vim.fn.getwininfo()) do
    if win_data.tabnr == current_tab and win_data.quickfix == 1 then
      if win_data.loclist == 1 then
        table.insert(qfwin, win_data.winid)
      else
        table.insert(llwin, win_data.winid)
      end
    end
  end
  return qfwin, llwin
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
  winid = winid or 0
  if listType == 'c' then
    return vim.fn.getqflist({ nr = nr, all = 0 })
  else
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
---@param title string
---@return qflist | nil
local function getListByTitle(listType, title)
  local size
  if listType == 'c' then
    size = vim.fn.getqflist({ nr = '$' }).nr
  else
    size = vim.fn.getloclist(0, { nr = '$' }).nr
  end
  for i = size, 1, -1 do
    local list = getList(listType, i)
    if list.title == title then
      return list
    end
  end
  return nil
end

--------------------------------------------------
-- Better Grep
--------------------------------------------------

vim.opt.grepprg = 'rg --vimgrep --smart-case'
vim.opt.grepformat = '%f:%l:%c:%m'

vim.api.nvim_create_user_command('Rg', function(opts)
  vim.cmd('silent grep! "' .. opts.args .. '"')
end, { nargs = 1 })

vim.api.nvim_create_user_command('LRg', function(opts)
  vim.cmd('silent lgrep! "' .. opts.args .. '" %')
end, { nargs = 1 })

-- https://github.com/oncomouse/dotfiles/blob/5abf79588d28379aa071fc7767dda46b9d90fb74/conf/vim/init.lua#L190-L205
local function grep_or_filter()
  if vim.opt.buftype:get() == 'quickfix' then
    vim.cmd([[packadd cfilter]])
    local input = vim.fn.input('QFGrep/')
    if #input > 0 then
      local prefix = vim.fn.getwininfo(vim.fn.win_getid())[1].loclist == 1 and 'L' or 'C'
      vim.cmd(prefix .. 'filter /' .. input .. '/')
    end
  else
    local input = vim.fn.input('Grep/')
    if #input > 0 then
      vim.cmd('silent! grep! "' .. input .. '"')
      vim.cmd('copen')
    end
  end
end

vim.keymap.set('n', '<leader>rg', grep_or_filter, { desc = '[R]ip[G]rep' })

--------------------------------------------------
-- Better Quickfix Window Style
--------------------------------------------------

local qfim_namespace = vim.api.nvim_create_namespace('qfim')

function _G.qftf(info)
  local list
  local ret = {}
  local local_diag = {}
  if info.quickfix == 1 then
    list = vim.fn.getqflist({ id = info.id, items = 1, qfbufnr = 1, winid = 1, lnum = 1 })
  else
    list = vim.fn.getloclist(info.winid, { id = info.id, items = 1, qfbufnr = 1, winid = 1, lnum = 1 })
    -- local_diag = vim.fn.getloclist(
    --   info.winid,
    --   { context = { qfim = { type = 'loc_diag' } }, id = info.id, items = 1, qfbufnr = 1, winid = 1, lnum = 1 }
    -- )
  end
  local qfwinid = list.winid
  vim.api.nvim_set_option_value('foldmethod', 'expr', { win = qfwinid, scope = 'local' })
  -- vim.api.nvim_set_option_value("fillchars", "eob: ,fold: ", { win = qfwinid })
  vim.api.nvim_set_option_value('foldexpr', 'v:lua._G.qffoldexprfunc()', { win = qfwinid, scope = 'local' })
  vim.api.nvim_set_option_value('foldtext', 'v:lua._G.qffoldtextfunc()', { win = qfwinid, scope = 'local' })
  local qfbufnr = list.qfbufnr
  local is_loc_diag = info.quickfix ~= 1 and local_diag.context ~= ''
  list = list.items
  local items = {}
  local limit = 0
  for i = info.start_idx, info.end_idx do
    local e = list[i]
    local item = { name = ' ', path = '', message = vim.fn.trim(e.text), type = e.type }
    if is_loc_diag then
      item.name = tostring(e.lnum)
      limit = #item.name > limit - 1 and #item.name - 1 or limit
    elseif e.valid == 1 and e.bufnr > 0 then
      local fname = vim.fn.bufname(e.bufnr)
      if fname ~= '' then
        fname = vim.fn.fnamemodify(fname, ':p:~:.')
        item.name = vim.fn.fnamemodify(fname, ':p:t')
        item.path = vim.fn.fnamemodify(fname, ':h')
        if item.path == '.' then
          item.path = ''
        end
        if #item.name + #item.path > limit then
          limit = #item.name + #item.path
        end
      end
    end
    table.insert(items, item)
  end
  limit = math.floor(math.min(limit + 1, vim.o.columns / 2))
  local formatLong, pathFmt, validFmt = '…%s', '%s%s%s', '%s%s │ %s%s'
  local highlighting = {}
  for i, item in ipairs(items) do
    if #item.name > limit then
      item.name = formatLong:format(item.name:sub(1 - limit))
      item.path = ''
    elseif #item.path > 0 and #item.path + #item.name + 1 > limit then
      item.path = formatLong:format(item.path:sub(2 - limit + #item.name))
    end
    local type = item.type == '' and '' or (signs[item.type] and signs[item.type] or signs.I)
    local path = pathFmt:format(item.name, item.path == '' and '' or ' ', item.path)
    local str = validFmt:format(path, (' '):rep(limit - #path), type, item.message)
    vim.list_extend(highlighting, {
      {
        group = 'Directory',
        line = i - 1,
        col = 0,
        end_col = #item.name,
      },
      {
        group = 'Comment',
        line = i - 1,
        col = #item.name + 1,
        end_col = limit + 4,
      },
      {
        group = highlights[item.type] or 'FloatTitle',
        line = i - 1,
        col = limit + 4,
        end_col = vim.o.columns,
      },
    })
    table.insert(ret, str)
  end
  vim.schedule(function()
    -- NOTE: this is needed because somehow diagnostics toggle runs 3 times with incomplete data after a [L]Rg command
    vim.api.nvim_buf_clear_namespace(qfbufnr, qfim_namespace, 0, -1)
    for _, hl in ipairs(highlighting) do
      vim.highlight.range(qfbufnr, qfim_namespace, hl.group, { hl.line, hl.col }, { hl.line, hl.end_col })
    end
  end)
  return ret
end

vim.o.qftf = '{info -> v:lua._G.qftf(info)}'

--------------------------------------------------
-- Keymaps
--------------------------------------------------

--- @param symbols? string[]
local function document_symbols(symbols)
  symbols = symbols or {}
  vim.lsp.buf.document_symbol({
    on_list = function(options)
      local items = options.items
      if not vim.tbl_isempty(symbols) then
        items = vim.tbl_filter(function(item)
          return vim.tbl_contains(symbols, string.lower(item.kind))
        end, items)
        if vim.tbl_isempty(items) then
          ---@diagnostic disable-next-line: param-type-mismatch
          vim.notify('No Symbols in the Document', vim.lsp.log_levels.WARN)
          return
        end
      end
      items = vim.tbl_map(function(item)
        item.text = string.format('[%s] %s', item.kind, vim.fn.trim(vim.fn.getline(item.lnum)))
        return item
      end, items)
      local title = vim.tbl_isempty(symbols) and 'All' or vim.fn.join(symbols, ', ')
      vim.fn.setloclist(0, {}, ' ', { title = 'Document Symbols: ' .. title, items = items })
      vim.schedule(function()
        vim.cmd('lopen')
      end)
    end,
  })
end

---@param listType ListType
---@param diagnostics? boolean
local function list_toggle(listType, diagnostics)
  local list = getList(listType)
  if list.winid ~= 0 then
    vim.cmd(listType .. 'close')
  elseif
    (not diagnostics and list.size == 0)
    or (listType == 'l' and diagnostics and #vim.diagnostic.get(0) == 0)
    or (listType == 'c' and diagnostics and #vim.diagnostic.get() == 0)
  then
    vim.notify('List is Empty', vim.log.levels.WARN)
  else
    if not diagnostics then
      vim.cmd(listType .. 'open')
    elseif listType == 'c' then
      local clist = getListByTitle('c', 'All Diagnostics')
      if not clist then
        vim.diagnostic.setqflist({ title = 'All Diagnostics' })
      else
        vim.cmd(clist.nr .. 'chistory | copen')
      end
    else
      local llist = getListByTitle('l', 'Local Diagnostics')
      if not llist then
        local local_diagnostics = vim.diagnostic.get(0)
        local ll_items = vim.diagnostic.toqflist(local_diagnostics)
        vim.fn.setloclist(0, {}, ' ', {
          title = 'Local Diagnostics',
          items = ll_items,
          context = { qfim = { type = 'loc_diag' } },
        })
        vim.cmd('lopen')
      else
        vim.cmd(llist.nr .. 'lhistory | lopen')
      end
    end
  end
end

vim.keymap.set('n', '<leader>tq', function()
  list_toggle('c')
end, { desc = '[T]oggle [Q]uickfix' })
vim.keymap.set('n', '<leader>qd', function()
  list_toggle('c', true)
end, { desc = '[Q]uickfix [D]iagnostics Toggle' })
vim.keymap.set('n', '<leader>qr', vim.lsp.buf.references, { desc = '[Q]uickfix [R]eferences' })
vim.keymap.set('n', '<leader>qi', vim.lsp.buf.implementation, { desc = '[Q]uickfix [I]mplementation' })

vim.keymap.set('n', '<leader>tl', function()
  list_toggle('l')
end, { desc = '[T]oggle [L]ocation List' })
vim.keymap.set('n', '<leader>ld', function()
  list_toggle('l', true)
end, { desc = '[L]ocation List [D]iagnostics Toggle' })
vim.keymap.set('n', '<leader>ls', function()
  document_symbols({ 'function' })
end, { desc = '[L]ocation List [S]ymbols' })

---@param listType ListType
---@param direction "next" | "prev"
---@param file boolean
local function move(listType, direction, file)
  ---@diagnostic disable-next-line: param-type-mismatch
  local ok, _ = pcall(vim.cmd, file and listType .. direction .. 'f' or listType .. direction)
  if not ok then
    vim.cmd(listType .. (direction == 'next' and 'first' or 'last'))
  end
end

vim.keymap.set('n', ']q', function()
  move('c', 'next', false)
end, { desc = 'Next [Q]uickfix Item Wrapping' })
vim.keymap.set('n', '[q', function()
  move('c', 'prev', false)
end, { desc = 'Previous [Q]uickfix Item Wrapping' })

vim.keymap.set('n', ']Q', function()
  move('c', 'next', true)
end, { desc = 'Next [Q]uickfix File Wrapping' })
vim.keymap.set('n', '[Q', function()
  move('c', 'prev', true)
end, { desc = 'Previous [Q]uickfix File Wrapping' })

vim.keymap.set('n', ']l', function()
  move('l', 'next', false)
end, { desc = 'Next [L]ocation List Item Wrapping' })
vim.keymap.set('n', '[l', function()
  move('l', 'prev', false)
end, { desc = 'Previous [L]ocation List Item Wrapping' })

vim.keymap.set('n', ']L', function()
  move('l', 'next', true)
end, { desc = 'Next [L]ocation List File Wrapping' })
vim.keymap.set('n', '[L', function()
  move('l', 'prev', true)
end, { desc = 'Previous [L]ocation List File Wrapping' })

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

--------------------------------------------------
-- Quickfix Autocmds
--------------------------------------------------

local qf_group = vim.api.nvim_create_augroup('qflist', { clear = true })

-- https://github.com/neovim/nvim-lspconfig/issues/69#issuecomment-1877781941
-- NOTE: extend to update location list too
vim.api.nvim_create_autocmd({ 'DiagnosticChanged' }, {
  group = vim.api.nvim_create_augroup('user_diagnostic_qflist', {}),
  callback = function()
    local diag_qf = getListByTitle('c', 'All Diagnostics')
    if not diag_qf then
      return
    end
    if vim.o.filetype == 'lazy' then
      return
    end
    local diagnostics = vim.diagnostic.get()
    if #diagnostics == 0 then
      vim.cmd('cclose')
    end
    local qf_items = vim.diagnostic.toqflist(diagnostics)
    vim.schedule(function()
      vim.fn.setqflist({}, 'r', {
        nr = diag_qf.nr,
        items = qf_items,
      })
    end)
  end,
})

---@return number
local function getHeight()
  local size = getActiveList().size
  return math.max(math.min(size, 10), 5)
end

function _G.qffoldexprfunc()
  local list = getActiveList().items
  local line = vim.fn.bufname(list[vim.v.lnum].bufnr)
  local next_line = #list < (vim.v.lnum + 1) and '' or vim.fn.bufname(list[vim.v.lnum + 1].bufnr)
  if line == next_line then
    return '1'
  else
    return '<1'
  end
end

function _G.qffoldtextfunc()
  local line = vim.fn.getline(vim.v.foldstart)
  local splitted = vim.split(line, '│')
  local path = vim.split(splitted[1], ' ')
  local whitespace = #path[2] ~= 0 and #splitted[1] - #vim.trim(splitted[1])
    or #splitted[1] - #vim.trim(splitted[1]) - 1
  local highlighting = {
    { path[1] .. ' ', 'DiagnosticInfo' },
    { path[2] .. (' '):rep(whitespace), 'Comment' },
    { '│', 'Comment' },
    { '⎯⎯ ' .. vim.v.foldend - vim.v.foldstart + 1 .. ' lines', 'DiagnosticInfo' },
    { ('⎯'):rep(vim.o.columns), 'DiagnosticInfo' },
  }
  return highlighting
end

vim.api.nvim_create_autocmd('BufWinEnter', {
  group = qf_group,
  pattern = 'quickfix',
  callback = function()
    vim.cmd('wincmd J')
    vim.opt.number = true
    vim.opt_local.relativenumber = false
    vim.opt_local.statuscolumn = ''
    vim.opt_local.hidden = true
    vim.bo.buflisted = false
    vim.wo.winfixheight = true
    vim.wo.winfixbuf = true
    vim.api.nvim_win_set_height(0, getHeight())
    vim.o.previewheight = 10
  end,
  desc = 'Qf syntax + options',
})

--------------------------------------------------
-- Keymaps inside Quickfix
--------------------------------------------------

---@param line string
local function getMessage(line)
  local path, _ = line:gsub('^.*│', '')
  return path
end

-- NOTE: take into account that this messes up with the error numbers
local function delete()
  local listType = getListType()
  if not listType then
    return
  end
  local list = getList(listType)
  local qfitems = list.items

  local mode = vim.fn.mode()
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
    local line = vim.api.nvim_win_get_cursor(0)
    table.remove(qfitems, line[1])
    setList(listType, { items = qfitems }, 'r', list.filewinid)
    local new_pos = line[1] > #qfitems and #qfitems or line[1]
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
  vim.cmd('pclose')
  vim.cmd('keepjumps aboveleft pedit +' .. line .. ' ' .. path)
  vim.api.nvim_win_set_cursor(0, { qfLinenr, 0 })
  local preview_win = getPreview()
  if not preview_win then
    vim.notify('Error opening the preview window', vim.log.levels.WARN)
    return
  end
  local preview_buf = vim.api.nvim_win_get_buf(preview_win)
  local is_preview_dup = false
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if win ~= preview_win and preview_buf == vim.api.nvim_win_get_buf(win) then
      is_preview_dup = true
      break
    end
  end
  if not is_preview_dup then
    vim.api.nvim_set_option_value('buflisted', false, { buf = preview_buf })
  end
end

-- NOTE: Should show lines or diagnostics in diagnostics qf?
local function previewHover()
  local line = vim.fn.getpos('.')
  local list = getActiveList().items[line[2]]
  if not vim.api.nvim_buf_is_loaded(list.bufnr) then
    vim.fn.bufload(list.bufnr)
  end
  -- NOTE: Take into account it doesn't show more lines that space has in the window
  local message = vim.api.nvim_buf_get_lines(list.bufnr, list.lnum - 2, list.lnum + 2, false)
  if #message == 0 then
    -- NOTE: I don't think this is necessary now, there should be always a message
    message = vim.split(vim.trim(getMessage(vim.fn.getline('.'))), '\n')
  end
  -- NOTE: idk what syntax to use, for example svelte files are tricky, markdown is easiest, filetype is nicer
  --      Can I get the real syntax?
  local filetype = vim.api.nvim_get_option_value('filetype', { buf = list.bufnr })
  vim.lsp.util.open_floating_preview(
    message,
    filetype,
    { title = vim.fn.bufname(list.bufnr), border = 'rounded', height = 10, focusable = true }
  )
end

---@param direction "n" | "p"
local function moveWithPreview(direction)
  local current_pos = vim.fn.getcurpos()
  local move_line = direction == 'n' and current_pos[2] + 1 or current_pos[2] - 1
  local list_size = getActiveList().size
  if move_line < 1 then
    move_line = list_size
  elseif move_line > list_size then
    move_line = 1
  end
  vim.api.nvim_win_set_cursor(0, { move_line, 0 })
  openPreview()
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
      local split =
        vim.api.nvim_open_win(item.bufnr, not opts.keep_cursor, { win = prev_win, vertical = opts.split == 'v' })
      vim.api.nvim_win_set_cursor(split, { item.lnum, item.col - 1 })
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
  local preview = getPreview()
  if preview then
    vim.cmd('pclose')
  end
  vim.cmd.close()
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
      moveWithPreview('n')
    end, { buffer = 0, desc = 'Move and Preview Next QF Item' })
    vim.keymap.set('n', '<C-p>', function()
      moveWithPreview('p')
    end, { buffer = 0, desc = 'Move and Preview Previous QF Item' })
    vim.keymap.set('n', 'p', openPreview, { buffer = 0, desc = 'Open and Close QF' })
    vim.keymap.set('n', 'K', previewHover, { buffer = 0, desc = 'Show Message on Hover' })
    vim.keymap.set('n', 'dd', delete, { buffer = 0, desc = 'Delete QF Item' })
    vim.keymap.set({ 'x' }, 'd', delete, { buffer = 0, desc = 'Delete QF Item' })
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

-- NOTE: return early in an horizontal move maybe caching line and buffer
vim.api.nvim_create_autocmd('CursorMoved', {
  group = qf_group,
  callback = function()
    local list = getActiveList()
    if list.winid == 0 or vim.bo.buftype ~= '' then
      return
    end
    local bufnr = vim.api.nvim_get_current_buf()
    local qf_pos = 0
    local buf_list = vim.tbl_filter(
      function(item)
        return item.valid == 1 and item.bufnr == bufnr and item.lnum > 0
      end,
      vim.tbl_map(function(item)
        qf_pos = qf_pos + 1
        return vim.tbl_extend('force', item, { qf_pos = qf_pos })
      end, list.items)
    )
    if vim.tbl_isempty(buf_list) then
      return
    end
    local cursor = vim.api.nvim_win_get_cursor(0)
    local prev_lnum = -1
    local prev_col = -1
    local pos = buf_list[1].qf_pos
    for _, entry in ipairs(buf_list) do
      -- If we detect that the list isn't sorted, bail.
      if prev_lnum == -1 then
      -- pass
      elseif entry.lnum < prev_lnum then
        return
      elseif entry.lnum == prev_lnum and entry.col <= prev_col then
        return
      end

      if cursor[1] > entry.lnum or (cursor[1] == entry.lnum and cursor[2] + 1 >= entry.col) then
        pos = entry.qf_pos
      end
      prev_lnum = entry.lnum
      prev_col = entry.col
    end
    if list.winid then
      vim.api.nvim_win_set_cursor(list.winid, { pos, 0 })
      vim.api.nvim_set_option_value('cursorline', true, { scope = 'local', win = list.winid })
    end
  end,
  desc = 'Update location in quickfix window',
})

vim.api.nvim_create_autocmd('WinEnter', {
  group = qf_group,
  callback = function()
    if vim.bo.filetype == 'qf' and vim.tbl_count(vim.api.nvim_list_wins()) == 1 then
      vim.cmd('quit')
    end
  end,
  desc = 'Close Neovim if the last window is a quickfix window',
})

vim.api.nvim_create_autocmd('WinClosed', {
  group = qf_group,
  callback = function(opt)
    local loclist = vim.fn.getloclist(opt.file, { winid = 0 })
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
-- update diagnostics in qf
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
