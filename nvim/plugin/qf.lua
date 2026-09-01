local qf_group = vim.api.nvim_create_augroup('qflist', { clear = true })

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
  local type = vim.fn.win_gettype(winid or 0)
  if type == 'quickfix' then
    return 'c'
  elseif type == 'loclist' then
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

---@param listType ListType
---@return qflist | nil
local function getDiagList(listType)
  local size = listType == 'c' and vim.fn.getqflist({ nr = '$' }).nr or vim.fn.getloclist(0, { nr = '$' }).nr
  for i = size, 1, -1 do
    local list = getList(listType, i)
    if
      type(list.context) == 'table'
      and list.context.qfim_diag
      and list.context.qfim_diag.type == listType
      and list.context.qfim_diag.diagnostics
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
-- Keymaps inside Quickfix
--------------------------------------------------

local function openAsDiff()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.startswith(vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win)), 'fugitive:') then
      vim.api.nvim_win_close(win, true)
    end
  end
  vim.cmd('pclose | . cc | Gvdiffsplit')
end

---@param winnr integer
---@return integer
local function get_prev_win(winnr)
  local prev_win = vim.fn.win_getid(vim.fn.winnr('#'))
  if prev_win <= 0 or vim.fn.win_gettype(prev_win) ~= '' then
    local info = vim.fn.getwininfo(winnr)
    if #info == 0 then
      return prev_win
    end
    local tab = info[1].tabnr
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
  local listType = getListType()
  assert(listType)
  local qflist = getList(listType)
  if isDiffTool(qflist) then
    openAsDiff()
    return
  end
  local qfitempos = vim.fn.getpos('.')
  if not opts.split then
    vim.cmd('.' .. listType .. listType)
  else
    local prev_win = qflist.filewinid or get_prev_win(qflist.winid)
    if prev_win and prev_win > 0 and vim.fn.win_gettype(prev_win) == '' then
      local item = qflist.items[qfitempos[2]]
      vim.api.nvim_open_win(item.bufnr, false, { win = prev_win, vertical = opts.split == 'v' })
      vim.cmd('.' .. listType .. listType)
      if opts.keep_cursor then
        vim.api.nvim_set_current_win(qflist.winid)
      end
    end
  end
  vim.schedule(function()
    if opts.close then
      vim.cmd(listType .. 'close')
    elseif opts.keep_cursor and not opts.split then
      vim.api.nvim_set_current_win(qflist.winid)
    end
  end)
end

local function closeList()
  local listType = getListType()
  assert(listType)
  local list = getList(listType)
  if isDiffTool(list) then
    pcall(vim.cmd.tabclose)
    return
  end
  vim.cmd.close()
end

---@param direction 'older'|'newer'
local function listHistory(direction)
  local listType = getListType()
  assert(listType)
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
  assert(listType)
  local list = getList(listType)
  local line = vim.api.nvim_win_get_cursor(0)
  local qfitem = list.items[line[1]]
  local bufname = vim.api.nvim_buf_get_name(qfitem.bufnr)
  local text = what == 'message' and vim.trim(qfitem.text) or (bufname ~= '' and vim.fs.relpath('.', bufname) or '')
  vim.fn.setreg('', text)
end

---@param direction 'next'|'prev'
local function moveAdyacentFile(direction)
  local qf = getList('c', 0)
  local items = qf.items
  local current_idx = qf.idx

  if #items == 0 or current_idx == 0 then
    vim.notify('Quickfix list is empty', vim.log.levels.INFO)
    return
  end

  local current_buf = items[current_idx].bufnr
  local step = direction == 'next' and 1 or -1
  local start_idx = current_idx + step
  local end_idx = direction == 'next' and #items or 1

  for i = start_idx, end_idx, step do
    if items[i].bufnr ~= current_buf and items[i].bufnr ~= 0 then
      vim.fn.setqflist({}, 'r', { idx = i })
      return
    end
  end

  vim.notify('No quickfix items in ' .. direction .. ' file', vim.log.levels.INFO)
end

local function setKeymaps()
  vim.keymap.set('n', 'q', closeList, { buf = 0, desc = 'Close QF list' })
  vim.keymap.set('n', '<CR>', selectItem, { buf = 0, desc = 'Open QF item' })
  vim.keymap.set('n', '<C-s>', function()
    selectItem({ split = 'h' })
  end, { buf = 0, desc = 'Open QF Item in Horizontal [S]plit' })
  vim.keymap.set('n', '<C-v>', function()
    selectItem({ split = 'v' })
  end, { buf = 0, desc = 'Open QF Item in [V]ertical Split' })
  vim.keymap.set('n', ']]', function()
    moveAdyacentFile('next')
  end, { buf = 0, desc = 'Move to QF Item in Next File' })
  vim.keymap.set('n', '[[', function()
    moveAdyacentFile('prev')
  end, { buf = 0, desc = 'Move to QF Item in Previous File' })
  vim.keymap.set('n', '<C-o>', function()
    listHistory('older')
  end, { buf = 0, desc = 'Open Older List' })
  vim.keymap.set('n', '<C-i>', function()
    listHistory('newer')
  end, { buf = 0, desc = 'Open Newer List' })
  vim.keymap.set('n', 'yf', function()
    yank('file')
  end, { buf = 0, desc = 'Yank Item File' })
  vim.keymap.set('n', 'ym', function()
    yank('message')
  end, { buf = 0, desc = 'Yank Item Message' })
  vim.keymap.set('n', 'gd', openAsDiff, { buf = 0, desc = '[G]it [D]iff' })
end

--------------------------------------------------
-- Better Grep
--------------------------------------------------

vim.o.grepprg = 'rg --vimgrep --smart-case --hidden'
vim.o.grepformat = '%f:%l:%c:%m'

vim.api.nvim_create_user_command('Rg', function(opts)
  vim.cmd('silent! grep! ' .. opts.args)
end, { nargs = '+' })

vim.api.nvim_create_user_command('LRg', function(opts)
  vim.cmd('silent lgrep! "' .. opts.args .. '" %')
end, { nargs = '+' })

vim.keymap.set('n', '<leader>rg', ':Rg ', { desc = '[R]efactor [G]rep' })

local function cf_preview(opts, preview_ns, _)
  local pattern = opts.args
  if pattern == '' then
    return
  end
  local ok, regex = pcall(vim.regex, pattern)
  if not ok then
    return
  end
  local qf_winid = vim.fn.getqflist({ winid = 0 }).winid
  if qf_winid == 0 then
    return
  end
  local qf_bufnr = vim.api.nvim_win_get_buf(qf_winid)
  local lines = vim.api.nvim_buf_get_lines(qf_bufnr, 0, -1, false)
  for lnum, line in ipairs(lines) do
    local col = 0
    while col < #line do
      local start, finish = regex:match_str(line:sub(col + 1))
      if not start then
        break
      end
      start = start + col
      finish = finish + col
      vim.hl.range(qf_bufnr, preview_ns, 'IncSearch', { lnum - 1, start }, { lnum - 1, finish })
      col = finish
    end
  end
  return 1
end

local function cf_execute(opts)
  vim.cmd.packadd('cfilter')
  local bang = opts.bang and '!' or ''
  local pattern = opts.args
  if pattern ~= '' then
    vim.cmd('Cfilter' .. bang .. ' /' .. pattern .. '/')
  end
end

vim.api.nvim_create_user_command('Cf', cf_execute, {
  nargs = '?',
  bang = true,
  preview = cf_preview,
  desc = '[Cf]ilter with live preview',
})

--------------------------------------------------
-- Keymaps to open diagnostics in qf
--------------------------------------------------

---@param listType ListType
local function dianostics_toggle(listType)
  local list = getList(listType)
  if list.winid ~= 0 then
    vim.cmd(listType .. 'close')
    return
  end
  local diag_where = listType == 'l' and 0 or nil
  local diag_list = vim.diagnostic.get(diag_where)
  if #diag_list == 0 then
    vim.notify('List is Empty', vim.log.levels.INFO)
    return
  end
  local qf_diag_list = getDiagList(listType)
  local action = ' '
  if qf_diag_list then
    -- NOTE: looks like a nvim bug that #chistory redraws the qf
    vim.cmd(('silent %s%shistory'):format(qf_diag_list.nr, listType))
    action = 'r'
  end
  local title = ('%s Diagnostics'):format(listType == 'c' and 'Workspace' or 'Local')
  setList(listType, {
    title = title,
    items = vim.diagnostic.toqflist(diag_list),
    context = { qfim_diag = { type = listType, diagnostics = true } },
  }, action)
  vim.schedule(function()
    vim.cmd(listType .. 'open')
  end)
end

vim.keymap.set('n', '<leader>Q', function()
  dianostics_toggle('c')
end, { desc = '[Q]uickfix [D]iagnostics Toggle' })

-- NOTE: implement something similar to compare branches: https://gist.github.com/jmacadie/6f934282870f0d481599c8339ef61f64
-- and/or other commits: https://github.com/jecaro/fugitive-difftool.nvim
vim.keymap.set('n', '<leader>qg', function()
  vim.cmd('tabedit | Git difftool --name-status | wincmd p')
  -- vim.cmd('tabedit | Git difftool --numstat --raw')
  -- would be cool to have status and numstat in the same command, but looks like it's not possible
  -- git diff --numstat --summary is difficult to parse (renaming is a mess)
end, { desc = 'Open [Q]uickfix With [G]it Diff' })

--------------------------------------------------
-- Set options and keymaps
--------------------------------------------------

vim.api.nvim_create_autocmd('BufWinEnter', {
  group = qf_group,
  pattern = 'quickfix',
  callback = function()
    setKeymaps()
  end,
  desc = 'Set qf keymaps',
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
    local loclist = vim.fn.getloclist(0, { winid = tonumber(opt.file) or 0 })
    if loclist and loclist.winid ~= 0 then
      vim.cmd('close ' .. loclist.winid)
    end
  end,
  desc = 'Close location list if parent window is closed',
})

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
-- https://github.com/neovim/neovim/issues/25410#issuecomment-3744609833 (Cf with preview)
