local general = vim.api.nvim_create_augroup('General Settings', { clear = true })

vim.api.nvim_create_autocmd({ 'BufReadPost' }, {
  pattern = '*',
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    if mark[1] > 1 and mark[1] <= vim.api.nvim_buf_line_count(0) and not vim.wo.diff then
      vim.api.nvim_win_set_cursor(0, mark)
    end
  end,
  group = general,
  desc = 'Open file at the last position it was edited earlier',
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
    if vim.o.filetype ~= 'markdown' and vim.o.filetype ~= 'gitcommit' then
      vim.opt.formatoptions:remove({ 'c', 'r', 'o' })
    end
  end,
  group = general,
  desc = "Don't auto comment after pressing enter in comment",
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

vim.api.nvim_create_autocmd({ 'WinEnter' }, {
  callback = function()
    vim.wo.cursorline = true
  end,
  group = general,
  desc = 'Show cursorline',
})
vim.api.nvim_create_autocmd({ 'WinLeave' }, {
  callback = function()
    vim.wo.cursorline = false
  end,
  group = general,
  desc = 'Hide cursorline when leaving window',
})

vim.api.nvim_create_autocmd({ 'CmdlineChanged' }, {
  pattern = ':',
  callback = function()
    local ok1, cmdline = pcall(vim.fn.getcmdline)
    if not ok1 then return end
    local ok, cmd = pcall(vim.api.nvim_parse_cmd, cmdline, {})
    if not ok then return end
    if #cmd.args == 0 then return end
    if cmd.cmd == 'find' or cmd.cmd == 'sfind' then
      vim.fn.wildtrigger()
    end
  end,
  group = general,
  desc = 'Autocompletion in cmdline `:`',
})

local function set_path()
  local dirs = vim.system({'fd', '.', '--type', 'd', '--hidden', '--absolute-path', '--exclude', '.git', '--exclude', 'node_modules', '--exclude', 'target', '--exclude', 'vendor'}):wait()
  if not dirs.stdout then
    return '.,,**'
  else
    return '.,,' .. dirs.stdout:gsub('\n', ','):gsub('%./', '')
  end
end

local files_list
---@param cmdarg string
function FindFunc(cmdarg, _)
  if not files_list then
    local cmd = { 'fd', '--type', 'file', '--relative-path', '--color', 'never', '--hidden', '.'}
    local files = vim.system(cmd, { text = true }):wait()
    if not files.stdout then
      return {}
    end
    files_list = vim.split(vim.trim(files.stdout), '\n')
  end
  return vim.fn.matchfuzzy(files_list, cmdarg)
end

vim.api.nvim_create_autocmd({ 'VimEnter' }, {
  callback = function()
    vim.o.path = set_path()
    vim.o.findfunc = 'v:lua.FindFunc'
  end,
  group = general,
})

vim.api.nvim_create_autocmd({ 'CmdlineLeave' }, {
  callback = function()
    files_list = nil
  end,
  group = general,
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
