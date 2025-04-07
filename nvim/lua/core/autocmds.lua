local general = vim.api.nvim_create_augroup('General Settings', { clear = true })

vim.api.nvim_create_autocmd({ 'BufReadPost' }, {
  pattern = '*',
  -- command = 'silent! normal! g`"zv',
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    if mark[1] > 1 and mark[1] <= vim.api.nvim_buf_line_count(0) then
      vim.api.nvim_win_set_cursor(0, mark)
    end
  end,
  group = general,
  desc = 'Open file at the last position it was edited earlier',
})

vim.api.nvim_create_autocmd({ 'BufLeave', 'FocusGained' }, {
  callback = function(args)
    if vim.bo.filetype ~= '' and vim.bo.buftype == '' and vim.bo.modified and not vim.bo.readonly then
      require('conform').format({ bufnr = args.buf })
      -- idk why the auto-sort command doesn't work, even with `:w`
      if vim.fn.exists(':TailwindSort') > 0 then
        vim.cmd('TailwindSort')
      end
      vim.cmd('silent! wa')
    end
  end,
  group = general,
  desc = 'Auto Save',
})

vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    vim.hl.on_yank()
  end,
  group = general,
  desc = 'Highlight on yank',
})

-- This is needed as the formatoptions are set in ft files in neovim core
vim.api.nvim_create_autocmd({ 'BufWinEnter' }, {
  callback = function()
    vim.opt.formatoptions:remove({ 'c', 'r', 'o' })
  end,
  group = general,
  desc = "Don't auto comment after pressing enter in comment",
})

vim.api.nvim_create_autocmd({ 'FileType' }, {
  pattern = {
    'query',
    'checkhealth',
    'git',
    'help',
    'tsplayground',
    '',
  },
  callback = function(event)
    vim.opt.statuscolumn = ' '
    vim.opt.signcolumn = 'yes'
    vim.bo.buflisted = false
    vim.bo.bufhidden = 'wipe'
    vim.keymap.set('n', 'q', '<cmd>close<cr>', { buffer = event.buf, silent = true })
  end,
  group = general,
  desc = "Close with 'q' in some windows",
})

vim.api.nvim_create_autocmd({ 'VimResized' }, {
  callback = function()
    vim.cmd('tabdo wincmd =')
  end,
  group = general,
  desc = 'Resize splits after resizing nvim',
})

vim.api.nvim_create_autocmd({ 'BufEnter' }, {
  callback = function()
    vim.schedule(function()
      if vim.o.buftype == '' then
        vim.fn.matchadd('ColorColumn', '\\%101v', 100)
      end
    end)
  end,
  group = general,
  desc = 'Show when lines are longer than 100 chars',
})

vim.api.nvim_create_autocmd({ 'BufWritePre' }, {
  callback = function(event)
    if event.match:match('^%w%w+://') then
      return
    end
    local file = vim.uv.fs_realpath(event.match) or event.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ':p:h'), 'p')
  end,
  group = general,
  desc = 'Create dir when saving a file when an intermediate directory is missing.',
})

-- based in https://new.reddit.com/r/neovim/comments/szjysg/switching_back_to_last_accessed_window_on_closing/
vim.api.nvim_create_autocmd({ 'WinEnter' }, {
  callback = function()
    if vim.api.nvim_win_get_config(0).relative ~= '' then
      return
    end

    if nil == vim.t.winid_rec then
      vim.t.winid_rec = { prev = vim.fn.win_getid(), current = vim.fn.win_getid() }
    else
      vim.t.winid_rec = { prev = vim.t.winid_rec.current, current = vim.fn.win_getid() }
    end

    vim.t.winid_rec = { prev = vim.t.winid_rec.current, current = vim.fn.win_getid() }

    if vim.api.nvim_win_is_valid(vim.t.winid_rec.prev) then
      return -- previous window wasn't closed
    end

    vim.cmd('wincmd p')
  end,
  group = general,
  desc = 'Return to previous window when closing another one',
})

vim.api.nvim_create_autocmd({ 'WinEnter' }, {
  callback = function()
    vim.wo.cursorline = true
  end,
  group = general,
  desc = 'Show cursorline',
})
vim.api.nvim_create_autocmd({ 'WinLeave' }, {
  callback = function()
    vim.lsp.buf.clear_references()
    vim.wo.cursorline = false
  end,
  group = general,
  desc = 'Hide cursorline when leaving window',
})

-- https://www.reddit.com/r/neovim/comments/1fbxxuo/comment/lm4scjx/
vim.api.nvim_create_autocmd('FocusGained', {
  pattern = '*',
  callback = function()
    vim.o.cursorlineopt = 'both'
    vim.cmd('redraw')
    vim.defer_fn(function()
      vim.o.cursorlineopt = 'number'
      vim.cmd('redraw')
    end, 300)
  end,
  group = general,
  desc = 'Show where the cursor is',
})

local cmd_range_ns = vim.api.nvim_create_namespace('cmd-range')
local win_state = nil
local peek_cursor = nil

-- https://github.com/nacro90/numb.nvim/blob/7f564e638d3ba367abf1ec91181965b9882dd509/lua/numb/init.lua#L110
local function parse_num_str(str)
  str = str:gsub('([%+%-])([%+%-])', '%11%2') -- turn input into a mathematical equation by adding a 1 between a plus or minus
  str = str:gsub('([%+%-])([%+%-])', '%11%2') -- a sign that was matched as $2 was not yet matched as $1
  if str:find('[%+%-]$') then -- also catch last character
    str = str .. 1
  end
  if str:find('^[%+%-]') then
    local current_line, _ = unpack(vim.api.nvim_win_get_cursor(0))
    str = current_line .. str
  end
  return load('return ' .. str)()
end

local function unpeek(stay)
  if not win_state then
    return
  end

  vim.api.nvim_win_set_cursor(0, win_state.cursor)

  if stay then
    if peek_cursor ~= nil then
      vim.api.nvim_win_set_cursor(0, peek_cursor)
      peek_cursor = nil
    end
    vim.cmd('normal! zz')
  else
    vim.fn.winrestview({ topline = win_state.topline })
  end
  vim.o.cursorlineopt = 'number'
  win_state = nil
end

local function peek(linenr)
  local bufnr = vim.api.nvim_win_get_buf(0)
  local n_buf_lines = vim.api.nvim_buf_line_count(bufnr)
  linenr = math.min(linenr, n_buf_lines)
  linenr = math.max(linenr, 1)

  if not win_state then
    vim.o.cursorlineopt = 'both'
    win_state = {
      cursor = vim.api.nvim_win_get_cursor(0),
      topline = vim.fn.winsaveview().topline,
    }
  end

  peek_cursor = { linenr, win_state.cursor[2] }
  vim.api.nvim_win_set_cursor(0, peek_cursor)
  vim.cmd('normal! zt')
end

vim.api.nvim_create_autocmd('CmdlineChanged', {
  callback = function()
    if vim.fn.getcmdtype() ~= ':' then
      return
    end
    vim.api.nvim_buf_clear_namespace(0, cmd_range_ns, 0, -1)
    local cmd_line = vim.fn.getcmdline()
    local ok, cmd = pcall(vim.api.nvim_parse_cmd, cmd_line, {})
    if not ok then
      local num_str = cmd_line:match('^([%+%-%d]+)')
      if num_str then
        unpeek(false)
        peek(parse_num_str(num_str))
        vim.cmd('redraw')
      end
      return
    end
    local range = cmd.range
    if not range or vim.tbl_isempty(range) then
      return
    end
    local first_line, last_line = range[1] - 1, range[2] and range[2] - 1 or range[1] - 1
    peek(first_line)
    vim.hl.range(0, cmd_range_ns, 'ColorColumn', { first_line, 0 }, { last_line, 0 }, { regtype = 'V' })
  end,
  group = general,
  desc = 'Peek or show cmdline ranges',
})
vim.api.nvim_create_autocmd('CmdlineLeave', {
  callback = function()
    vim.api.nvim_buf_clear_namespace(0, cmd_range_ns, 0, -1)
    if not win_state then
      return
    end
    local event = vim.api.nvim_get_vvar('event')
    local stay = not event.abort
    unpeek(stay)
  end,
  group = general,
  desc = 'Remove ranges highlights and unpeek',
})

local function set_path()
  local is_git = require('utils.is-git')()
  if not is_git then
    return '.,,'
      .. table
        .concat(
          vim.fn.systemlist(
            'fd . --type d --hidden --exclude .git --exclude node_modules --exclude target --absolute-path'
          ),
          ','
        )
        :gsub('%./', '')
  else
    return ',,' .. table.concat(vim.fn.systemlist('fd . --type d --absolute-path'), ',')
  end
end
vim.api.nvim_create_autocmd('CmdlineEnter', {
  callback = function()
    vim.o.path = set_path()
  end,
  once = true,
  group = general,
  desc = 'Lazyload setting path',
})

---@param cmdarg string
function FindFunc(cmdarg, _)
  cmdarg = vim.fn.escape(cmdarg, '\\')
  local cmd = { 'fd', '--type', 'file', '--full-path', '--color', 'never', cmdarg }
  local files = vim.system(cmd, { text = true }):wait()
  if not files.stdout then
    return {}
  end
  return vim.split(vim.trim(files.stdout), '\n')
end

vim.api.nvim_create_autocmd({ 'UIEnter' }, {
  callback = function()
    vim.o.findfunc = 'v:lua.FindFunc'
  end,
  group = general,
})

vim.opt.messagesopt = 'wait:500,history:1000'
vim.api.nvim_create_autocmd({ 'CmdlineEnter' }, {
  callback = function()
    vim.opt.messagesopt = 'hit-enter,history:1000'
    vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorMoved' }, {
      callback = function()
        vim.opt.messagesopt = 'wait:500,history:1000'
      end,
      once = true,
      group = general,
    })
  end,
  group = general,
  desc = 'Only show Cmdline message when triggered',
})

local function open_external_file()
  local prev_buf = vim.fn.bufnr('%')
  local fn = vim.fn.expand('%:p')
  -- Open the file using xdg-open
  -- vim.fn.jobstart('xdg-open "' .. fn .. '"')
  vim.ui.open(fn)

  vim.notify(string.format('Opening file: %s', fn))

  if vim.fn.buflisted(prev_buf) == 1 then
    vim.api.nvim_set_current_buf(prev_buf)
  end

  vim.api.nvim_buf_delete(0, { force = true })
end

local file_types = { 'pdf', 'jpg', 'jpeg', 'webp', 'png', 'mp3', 'mp4', 'xls', 'xlsx', 'xopp', 'gif', 'doc', 'docx' }

local bin_files = vim.api.nvim_create_augroup('binFiles', { clear = true })
for _, ext in ipairs(file_types) do
  vim.api.nvim_create_autocmd({ 'BufReadCmd' }, {
    pattern = '*.' .. ext,
    group = bin_files,
    callback = open_external_file,
  })
end
