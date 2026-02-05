local opt, api, fn, map = vim.o, vim.api, vim.fn, vim.keymap.set
local cmdline_autocmds = api.nvim_create_augroup('cmdline_autocmds', { clear = true })

--------------------------------------------------
-- General Options
--------------------------------------------------

require('vim._core.ui2').enable({})

opt.showmode = false
opt.showcmd = false
opt.shortmess = 'aoOstTWIcCF'

--------------------------------------------------
-- Autocompletion
--------------------------------------------------

opt.wildoptions = 'pum,fuzzy'
opt.wildmode = 'noselect:lastused,full'

api.nvim_create_autocmd({ 'CmdlineChanged' }, {
  pattern = '*',
  callback = function()
    fn.wildtrigger()
  end,
  group = cmdline_autocmds,
  desc = 'Autocompletion in cmdline',
})

--------------------------------------------------
-- Search
--------------------------------------------------

vim.cmd('packadd nohlsearch')
opt.incsearch = true
opt.inccommand = 'split'
opt.ignorecase = true
opt.smartcase = true

--------------------------------------------------
-- Finder
--------------------------------------------------

map('n', '<leader>w', ':find ', { desc = 'Find Buffer in [W]indow' })
map('n', '<leader>s', ':sfind ', { desc = 'Find Buffer in [S]plit' })
map('n', '<leader>v', ':vsplit | find ', { desc = 'Find Buffer in [V]ertical Split' })

local function set_path()
  local dirs = vim.system({ 'fd', '.', '--type', 'd', '--hidden', '--absolute-path' }):wait()
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
    local fd_cmd = { 'fd', '.', '--type', 'file', '--relative-path', '--color', 'never', '--hidden' }
    local files = vim.system(fd_cmd, { text = true }):wait()
    if not files.stdout then
      return {}
    end
    files_list = vim.split(vim.trim(files.stdout), '\n')
  end
  return fn.matchfuzzy(files_list, cmdarg)
end

opt.path = set_path()
opt.findfunc = 'v:lua.FindFunc'

api.nvim_create_autocmd({ 'CmdlineLeave' }, {
  callback = function()
    files_list = nil
  end,
  group = cmdline_autocmds,
})

local function add_magic(cmd_line, cmd_pos)
  local ok, cmd_parsed = pcall(api.nvim_parse_cmd, cmd_line, {})
  if not ok then
    return '/'
  end
  local next_cmd_pos = cmd_line:find('|')
  if next_cmd_pos and cmd_pos > next_cmd_pos then
    return add_magic(cmd_line:sub(next_cmd_pos + 1), cmd_pos - next_cmd_pos)
  end
  local cmds = { 'substitute', 'global', 'vglobal' }
  if vim.list_contains(cmds, cmd_parsed.cmd) and #cmd_parsed.args == 0 then
    return '/\\v'
  end
  return '/'
end

map('c', '/', function()
  if fn.getcmdtype() ~= ':' then
    return '/'
  end
  local cmd_line = fn.getcmdline()
  local cmd_pos = fn.getcmdpos()
  return add_magic(cmd_line, cmd_pos)
end, { desc = 'Add Very Magic to Cmdline Patterns', expr = true })

local function get_fuzzy(cmd_line)
  local closed_fuzzy_block
  local very_nomagic_pos = cmd_line:find('\\V')
  local very_magic_pos = cmd_line:find('\\v')
  local is_magic = very_nomagic_pos or very_magic_pos
  if is_magic and is_magic ~= 1 then -- is_magic == 1 means I'm searching with / or ?
    local divider = cmd_line:sub(is_magic - 1, is_magic - 1)
    closed_fuzzy_block = cmd_line:find(divider, is_magic)
  end
  if closed_fuzzy_block or not is_magic then
    return '<c-]><space>'
  elseif very_nomagic_pos then
    return '\\.\\{-}'
  elseif very_magic_pos then
    return '.{-}'
  end
end

local function fuzzy_find(cmd_line, cmd_pos)
  local ok, cmd_parsed = pcall(api.nvim_parse_cmd, cmd_line, {})
  if not ok then
    return '<c-]><space>'
  end
  local next_cmd_pos = cmd_line:find('|')
  if #cmd_parsed.args == 0 and (cmd_parsed.nextcmd == '' or cmd_pos <= next_cmd_pos) then
    return '<c-]><space>'
  end
  if next_cmd_pos and cmd_pos > next_cmd_pos then
    return fuzzy_find(cmd_line:sub(next_cmd_pos + 1), cmd_pos - next_cmd_pos)
  end
  local edit_cmds = { 'edit', 'split', 'vsplit' }
  if vim.list_contains(edit_cmds, cmd_parsed.cmd) then
    return (cmd_line:sub(cmd_pos - 2, cmd_pos - 1) == '**') and '/*' or '*'
  elseif cmd_parsed.cmd == 'help' then
    return '*'
  else
    return get_fuzzy(cmd_line)
  end
end

map('c', '<space>', function()
  local mode = fn.getcmdtype()
  local cmd_line = fn.getcmdline()
  if mode == '?' or mode == '/' then
    return get_fuzzy(cmd_line)
  elseif mode == ':' then
    local cmd_pos = fn.getcmdpos()
    return fuzzy_find(cmd_line, cmd_pos)
  else
    return '<c-]><space>'
  end
end, { desc = 'Use <space> to "Fuzzy Find"', expr = true })

map('c', '<C-space>', '<space>', { desc = 'Easier Space' })

--------------------------------------------------
-- Misc Keymaps
--------------------------------------------------

map('c', '<C-n>', function()
  return fn.wildmenumode() == 1 and '<C-n>' or '<down>'
end, { desc = 'Move Through Cmdline History', expr = true })
map('c', '<C-p>', function()
  return fn.wildmenumode() == 1 and '<C-p>' or '<up>'
end, { desc = 'Move Through Cmdline History', expr = true })

map('c', '*', function()
  local cmd_line = fn.getcmdline()
  local cmd_pos = fn.getcmdpos()
  return (cmd_line:sub(cmd_pos - 2, cmd_pos - 1) == '**') and '/*' or '*'
end, { desc = 'Expand *** to **/*', expr = true })

map('c', '%', function()
  local cmd_line = fn.getcmdline()
  local cmd_pos = fn.getcmdpos()
  return cmd_line:sub(cmd_pos - 1, cmd_pos - 1) == '%' and ('<C-h>' .. fn.expand('%:p:h') .. '/') or '%'
end, { desc = 'Expand %% to File Directory', expr = true })

--------------------------------------------------
-- Abbreviations
--------------------------------------------------

local cmds_typos = { 'W', 'Wa', 'WA', 'X', 'Xa', 'XA', 'H', 'Mes', 'Mess' }
for _, cmd_typo in ipairs(cmds_typos) do
  map('ca', cmd_typo, cmd_typo:lower())
end

local custom_cmds_typos = { 'RG', 'LA', 'MAson' }
for _, cmd_typo in ipairs(custom_cmds_typos) do
  map('ca', cmd_typo, cmd_typo:sub(1, 1):upper() .. cmd_typo:sub(2):lower())
end
