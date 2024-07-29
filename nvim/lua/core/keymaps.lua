--------------------------------------------------
-- Basics
--------------------------------------------------

-- Remap Escape
vim.keymap.set('i', 'jk', '<Esc>')

-- Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

--Move things around when in visual mode
vim.keymap.set('x', 'J', ":m '>+1<CR>gv=gv")
vim.keymap.set('x', 'K', ":m '<-2<CR>gv=gv")

-- Press 'U' for redo
vim.keymap.set('n', 'U', '<C-r>')

-- Add empty lines before and after cursor line
vim.keymap.set(
  'n',
  'gO',
  "<cmd>call append(line('.') - 1, repeat([''], v:count1))<CR>",
  { desc = 'Create new line above' }
)
vim.keymap.set(
  'n',
  'go',
  "<cmd>call append(line('.'),     repeat([''], v:count1))<CR>",
  { desc = 'Create new line below' }
)

-- Center buffer while navigating
vim.keymap.set('n', 'n', 'nzzzv')
vim.keymap.set('n', 'N', 'Nzzzv')
vim.keymap.set('n', '<C-u>', '<C-u>zz')
vim.keymap.set('n', '<C-d>', '<C-d>zz')
vim.keymap.set('n', '{', '{zz')
vim.keymap.set('n', '}', '}zz')
vim.keymap.set('n', 'G', 'Gzz')
vim.keymap.set('n', 'gg', 'ggzz')
vim.keymap.set('n', '<C-i>', '<C-i>zz')
vim.keymap.set('n', '<C-o>', '<C-o>zz')
vim.keymap.set('n', '*', '*zz')
vim.keymap.set('n', '#', '#zz')

-- Stay in indent mode
vim.keymap.set('x', '<', '<gv')
vim.keymap.set('x', '>', '>gv')

-- better default movements
-- based on https://www.reddit.com/r/neovim/comments/181bsu8/comment/kadbhj9
vim.keymap.set('n', 'w', [[<cmd>call search('^[''" ]*\zs.\|\s\+[''"]*\zs.\|\<')<CR>]], { desc = 'Next Word' })
vim.keymap.set('n', 'b', [[<cmd>call search('^[''" ]*\zs.\|\s\+[''"]*\zs.\|\<', 'b')<CR>]], { desc = 'Previous Word' })
vim.keymap.set('n', 'e', [[l<cmd>call search('[''",]\+$\|\>')<CR>h]], { desc = 'End Next word' })
vim.keymap.set('n', 'ge', [[l<cmd>call search('[''",]\+$\|\>', 'b')<CR>h]], { desc = 'End Previous word' })
vim.keymap.set('n', '{', [[<cmd>call search('\(\n\n\|\%^\)\s*\zs\S', 'b')<CR>]], { desc = 'Start Previous Paragraph' })
vim.keymap.set('n', '}', [[<cmd>call search('\n\n\s*\zs\S')<CR>]], { desc = 'Start Next Paragraph' })

vim.keymap.set('n', "'", '`', { desc = "Swap ` with ' because is a better way to jump to marks" })
vim.keymap.set('n', '`', "'", { desc = "Swap ` with ' because is a better way to jump to marks" })

vim.keymap.set('x', 'gci', ':normal gcc<CR>', { desc = 'Invert comments line by line' })

-- registers
vim.keymap.set('n', 'dd', function()
  return vim.fn.getline('.') == '' and '"_dd' or 'dd'
end, { desc = 'Send blank lines to black hole', expr = true })
vim.keymap.set('n', 'dl', '0d$', { desc = '[D]elete [L]ine without newline' })

-- better cmdline history
vim.keymap.set('c', '<C-n>', function()
  return vim.fn.wildmenumode() == 1 and '<C-n>' or '<down>'
end, { desc = 'Move Through Cmdline History', expr = true })
vim.keymap.set('c', '<C-p>', function()
  return vim.fn.wildmenumode() == 1 and '<C-p>' or '<up>'
end, { desc = 'Move Through Cmdline History', expr = true })

--------------------------------------------------
-- Terminal
--------------------------------------------------

---@class term
---@field buf_num number
---@field win_id number

---@param term term
local function check_term_data(term)
  if term.win_id ~= -1 and not vim.list_contains(vim.api.nvim_list_wins(), term.win_id) then
    term.win_id = -1
    if not vim.list_contains(vim.api.nvim_list_bufs(), term.buf_num) then
      term.buf_num = -1
    end
  end
end

---@type term[]
local terms = {}
---@param num 1|2
local function toggle_term(num)
  local term = terms[num]
  check_term_data(term)
  if term.buf_num == -1 then
    vim.cmd('vsplit | vertical resize 50 | term')
    term.buf_num = vim.api.nvim_get_current_buf()
    term.win_id = vim.api.nvim_get_current_win()
  elseif term.win_id == -1 then
    vim.cmd('vsplit | vertical resize 50 | b' .. term.buf_num)
    term.win_id = vim.api.nvim_get_current_win()
  else
    vim.api.nvim_win_close(term.win_id, true)
    term.win_id = -1
  end
end

for pos = 1, 2 do
  terms[pos] = { buf_num = -1, win_id = -1, is_hidden = -1 }
  vim.keymap.set({ 'n', 't' }, 't' .. pos, function()
    toggle_term(pos)
  end, { desc = 'Toggle [T]erminal [' .. pos .. ']' })
end
vim.keymap.set({ 'n', 't' }, 'tt', function()
  toggle_term(1)
end, { desc = '[T]oggle [T]erminal 1' })

vim.keymap.set('t', 'jk', '<C-\\><C-n>', { desc = 'Escape Terminal Mode' })

local function scroll_to_end(bufnr, winid)
  vim.api.nvim_buf_call(bufnr, function()
    local target_line = vim.tbl_count(vim.api.nvim_buf_get_lines(bufnr, 0, -1, true))
    vim.api.nvim_win_set_cursor(winid, { target_line, 0 })
  end)
end

---@param cmd string
local function run_term_command(cmd)
  local term = terms[1]
  check_term_data(term)
  if term.win_id == -1 then
    toggle_term(1)
  end
  scroll_to_end(term.buf_num, term.win_id)
  local terminal_job_id = (vim.api.nvim_buf_get_var(term.buf_num, 'terminal_job_id'))
  local cr = string.char(13)
  vim.api.nvim_chan_send(terminal_job_id, cmd .. cr)
end

vim.keymap.set('n', 'crb', function()
  local build = { jdtls = 'mvn spring-boot:run' }
  for _, client in ipairs(vim.lsp.get_clients()) do
    if build[client.name] then
      run_term_command(build[client.name])
      return
    end
  end
  vim.notify('No Build command for attached lsps', vim.log.levels.INFO)
end, { desc = '[C]ode [R]unner [B]uild' })

vim.keymap.set('n', 'crt', function()
  local test = { jdtls = 'mvn test' }
  for _, client in ipairs(vim.lsp.get_clients()) do
    if test[client.name] then
      run_term_command(test[client.name])
      return
    end
  end
  vim.notify('No Test command for attached lsps', vim.log.levels.INFO)
end, { desc = '[C]ode [R]unner [T]est' })

--------------------------------------------------
-- Searching
--------------------------------------------------

vim.api.nvim_create_user_command('GSearch', function(opts)
  vim.api.nvim_input(':g<C-v>/\\V' .. opts.args .. '/#<CR>:')
end, {
  nargs = '*',
  complete = function(ArgLead, _, _)
    -- https://vi.stackexchange.com/a/25005
    local content = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    content = vim.fn.join(content, ' ')
    content = vim.fn.split(content, "[ \t~!@#$%^&*+=()<>{}[\\];:|,?\"\\\\/'']\\+")
    content = vim.tbl_filter(function(str)
      return #str > 2
        and vim.fn.match(str, '^[a-zA-Z_]\\+') > -1
        and vim.fn.match(str, '^' .. ArgLead) > -1 -- so it starts with the word
        and vim.fn.match(str, ArgLead) > -1 -- so it only cointains the word?
    end, content)
    content = vim.fn.sort(content)
    return vim.fn.uniq(content)
  end,
})
vim.keymap.set('n', 'g/', ':GSearch ', { desc = 'Search with [G]lobal' })

-- stylua: ignore
vim.keymap.set({ 'n', 'x' }, '/', 'ms/\\V', { desc = 'Add Very Nomagic to Forward Seach and add s Mark for easier return' })
-- stylua: ignore
vim.keymap.set({ 'n', 'x' }, '?', 'ms?\\V', { desc = 'Add Very Nomagic to Backwards Search and add s Mark for easier return' })

vim.keymap.set('c', '/', function()
  if vim.fn.getcmdtype() ~= ':' then
    return '/'
  end
  local cmd_line = vim.fn.getcmdline()
  local cmds = { 's', 'g', 'v' }
  for _, cmd in ipairs(cmds) do
    -- find better regex for various ranges (https://github.com/wincent/loupe/blob/9189e7fa2d9dd54f4f0211c5edfdd6260252fe4b/autoload/loupe/private.vim#L67)
    if cmd_line == cmd or cmd_line == '%' .. cmd or cmd_line == "'<,'>" .. cmd then
      return '/\\v'
    end
  end
  return '/'
end, { desc = 'Add Very Magic to Cmdline Patterns', expr = true })

vim.keymap.set('c', '<space>', function()
  local mode = vim.fn.getcmdtype()
  local cmd_line = vim.fn.getcmdline()
  if mode == '?' or mode == '/' then
    if cmd_line:match('\\V') then
      return '\\.\\*'
    else
      return '.*'
    end
  elseif mode == ':' then
    if
      vim.startswith(cmd_line, 'edit')
      or vim.startswith(cmd_line, 'split')
      or vim.startswith(cmd_line, 'vsplit')
      or vim.startswith(cmd_line, 'find')
      or vim.startswith(cmd_line, 'sfind')
    then
      local cmd_pos = vim.fn.getcmdpos()
      return (cmd_line:sub(cmd_pos - 2, cmd_pos - 1) == '**') and '/*' or '*'
    elseif cmd_line:match('\\V') then
      return '\\.\\*'
    elseif cmd_line:match('\\v') then
      return '.*'
    else
      return ' '
    end
  else
    return ' '
  end
end, { desc = 'Use <space> to "Fuzzy Find"', expr = true })

-- NOTE: maybe use these two instead of ge and gE?
vim.keymap.set('c', '*', function()
  local cmd_line = vim.fn.getcmdline()
  local cmd_pos = vim.fn.getcmdpos()
  return (cmd_line:sub(cmd_pos - 2, cmd_pos - 1) == '**') and '/*' or '*'
end, { desc = 'Expand *** to **/*', expr = true })

vim.keymap.set('c', '%', function()
  local cmd_line = vim.fn.getcmdline()
  local cmd_pos = vim.fn.getcmdpos()
  return cmd_line:sub(cmd_pos - 1, cmd_pos - 1) == '%' and ('<C-h>' .. vim.fn.expand('%:p:h') .. '/') or '%'
end, { desc = 'Expand %% to File Directory', expr = true })

--------------------------------------------------
-- Open Buffers
--------------------------------------------------

local edit_buffer = {
  w = { cmd = ':edit ', desc = '[W]indow' },
  s = { cmd = ':split ', desc = '[S]plit' },
  v = { cmd = ':vsplit ', desc = '[V]ertical split' },
}

for key, opts in pairs(edit_buffer) do
  -- vim.keymap.set('n', 'ge' .. key, opts.cmd .. '**/*', { desc = '[E]dit Buffer in ' .. opts.desc })
  vim.keymap.set('n', 'gE' .. key, function()
    return opts.cmd .. vim.fn.expand('%:p:h') .. '/'
  end, { desc = '[E]dit Buffer in Current Directory in ' .. opts.desc, expr = true })
  -- vim.keymap.set('n', 'gs' .. key, function()
  --   return opts.cmd .. '**/* | set nobuflisted' .. ('<left>'):rep(18)
  -- end, { desc = 'Open [S]cratch Buffer in ' .. opts.desc, expr = true })
  vim.keymap.set('n', 'ga' .. key, function()
    local current_path = vim.fn.expand('%:p')
    local alternative_path
    if vim.o.filetype == 'java' then
      if current_path:find('test') then
        alternative_path = current_path:gsub('/test/', '/main/'):gsub('Test', '')
      else
        alternative_path = current_path:gsub('/main/', '/test/'):gsub('%.java', 'Test.java')
      end
    end
    return opts.cmd .. alternative_path .. '<CR>'
  end, { desc = 'Edit [A]lternative File in ' .. opts.desc, expr = true })
end

local find_buffer = {
  w = { cmd = ':find ', desc = '[W]indow' },
  s = { cmd = ':sfind ', desc = '[S]plit' },
  v = { cmd = ':vsplit | find ', desc = '[V]ertical split' },
}

for key, opts in pairs(find_buffer) do
  vim.keymap.set('n', 'ge' .. key, opts.cmd, { desc = '[E]dit Buffer in ' .. opts.desc })
  vim.keymap.set('n', 'gs' .. key, function()
    return opts.cmd .. ' | set nobuflisted' .. ('<left>'):rep(18)
  end, { desc = 'Open [S]cratch Buffer in ' .. opts.desc, expr = true })
end

--------------------------------------------------
-- Buffer Management
--------------------------------------------------
-- NOTE: maybe use a custom list as arglist misses a good API and buflist is clunky
-- deleting a buf is an extra keymap
-- change gb prefix for \ ?

local function delete_buf()
  vim.api.nvim_set_option_value('buflisted', false, { buf = 0 })
  local alternative_buffer = vim.fn.expand('#:p')
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if
      vim.api.nvim_buf_is_loaded(bufnr)
      and vim.api.nvim_get_option_value('buflisted', { buf = bufnr })
      and vim.api.nvim_buf_get_name(bufnr) == alternative_buffer
    then
      return '<cmd>edit #<CR>'
    end
  end
  return '<cmd>silent! bnext<CR>'
end

local function delete_all_other_bufs()
  local current_bufnr = vim.api.nvim_win_get_buf(0)
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) and bufnr ~= current_bufnr then
      vim.api.nvim_set_option_value('buflisted', false, { buf = bufnr })
    end
  end
end

vim.api.nvim_create_user_command('CleanBuflist', function(opts)
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.list_contains(opts.fargs, tostring(bufnr)) ~= opts.bang then
      vim.api.nvim_set_option_value('buflisted', false, { buf = bufnr })
    end
  end
  if not vim.api.nvim_get_option_value('buflisted', { buf = 0 }) then
    vim.cmd('silent! bnext')
  end
end, { nargs = '*', bang = true })

vim.keymap.set('n', 'gbb', '<cmd>ls<CR>:b<space>', { desc = 'Change Open [B]uffer' })
vim.keymap.set('n', ']b', '<cmd>bnext<CR>', { desc = 'Next Open Buffer' })
vim.keymap.set('n', '[b', '<cmd>bprevious<CR>', { desc = 'Previous Open Buffer' })
-- maybe add keymap for `:b#` that's easier than C-^
vim.keymap.set('n', 'gba', '<cmd>set buflisted<CR>', { desc = '[A]dd Open Buffer' })
vim.keymap.set('n', 'gbd', delete_buf, { desc = '[D]elete Open Buffer', expr = true })
-- not using :bdel as it removes the file from diagnostics
vim.keymap.set('n', 'gbc', '<cmd>ls<CR>:CleanBuflist ', { desc = '[C]lean Open Buffer' })
vim.keymap.set('n', 'gbo', delete_all_other_bufs, { desc = 'Make [O]nly Buffer' })

--------------------------------------------------
-- Window Management
--------------------------------------------------

-- Basics (NOTE: Check what to do with these keymaps)
vim.keymap.set('n', '<C-\\>', '<C-w>v', { desc = 'Split Window [|]Vertically' })
vim.keymap.set('n', '<CR>', '<C-w>s', { desc = 'Split Window [-]Horizontally' }) -- <C--> and <CR> map to the same key in the terminal
vim.keymap.set('n', '<C-=>', '<C-w>=', { desc = 'Window [=]Equal Size' })
vim.keymap.set('n', '<C-q>', '<cmd>close<CR>', { desc = 'Window [Q]uit' })
-- Resize window
vim.keymap.set('n', '<C-<>', '5<C-w><', { desc = 'Resize Window [<]Smaller Vertically' })
vim.keymap.set('n', '<C->>', '5<C-w>>', { desc = 'Resize Window [>]Bigger Vertically' })
vim.keymap.set('n', '<C-,>', '5<C-w>-', { desc = 'Resize Window [<]Smaller Horizontally' })
vim.keymap.set('n', '<C-.>', '5<C-w>+', { desc = 'Resize Window [<]Bigger Horizontally' })
-- Move (rotate) window on row
vim.keymap.set('n', '<C-r>', '<C-w><C-w>', { desc = 'Move A[R]ound Windows' })
-- Move split to main position
vim.keymap.set('n', '<C-H>', '<C-w>H', { desc = 'Move Window [h]Left' })
vim.keymap.set('n', '<C-K>', '<C-w>K', { desc = 'Move Window [k]Up' })
vim.keymap.set('n', '<C-J>', '<C-w>J', { desc = 'Move Window [j]Down' })
vim.keymap.set('n', '<C-L>', '<C-w>L', { desc = 'Move Window [l]right' })

local nav = {
  h = 'Left',
  j = 'Down',
  k = 'Up',
  l = 'Right',
}

---@param dir "h"|"j"|"k"|"l"
---@return function
local function navigate(dir)
  return function()
    local win = vim.api.nvim_get_current_win()
    vim.cmd.wincmd(dir)
    if win == vim.api.nvim_get_current_win() then
      local cmd = vim.uv.os_uname().release:find('WSL') and 'wezterm.exe' or 'wezterm'
      local pane_dir = nav[dir]
      vim.system({ cmd, 'cli', 'activate-pane-direction', pane_dir }, { text = true }, function(p)
        if p.code ~= 0 then
          vim.notify(
            'Failed to move to pane ' .. pane_dir .. '\n' .. p.stderr,
            vim.log.levels.ERROR,
            { title = 'Wezterm' }
          )
        end
      end)
    end
  end
end

-- Move to window using the movement keys
for key, _ in pairs(nav) do
  vim.keymap.set({ 'n', 't' }, '<C-' .. key .. '>', navigate(key))
end

--------------------------------------------------
-- Surround
--------------------------------------------------

local surround = {
  { '(', ')' },
  { '[', ']' },
  { '{', '}' },
  { "'", "'" },
  { '"', '"' },
  { '`', '`' },
  { '<', '>' },
  { '*', '*' },
  { '_', '_' },
}
for _, pair in ipairs(surround) do
  vim.keymap.set('n', 'ys' .. pair[1], function()
    local word = vim.fn.expand('<cword>') -- to avoid populating registers
    return '"_ciw' .. pair[1] .. word .. pair[2] .. '<ESC>'
  end, { desc = '[Y]ou [S]urround with [' .. pair[1] .. ']', expr = true })

  vim.keymap.set('x', 'S' .. pair[1], function()
    return ':s/\\v%V(\\s*)(.*)%V/\\1' .. pair[1] .. '\\2' .. pair[2] .. '<CR>'
  end, { desc = '[Y]ou [S]urround with [' .. pair[1] .. ']', expr = true })

  vim.keymap.set(
    'n',
    'ds' .. pair[1],
    'di' .. pair[1] .. 'vhP',
    { desc = '[D]elete [S]urrounding [' .. pair[1] .. ']' }
  )

  for _, replace in ipairs(surround) do
    vim.keymap.set(
      'n',
      'cs' .. pair[1] .. replace[1],
      'di' .. pair[1] .. 'vh"_c' .. replace[1] .. '<C-r>"' .. replace[2],
      { desc = '[C]hange [S]urround [' .. pair[1] .. '] with [' .. replace[1] .. ']' }
    )
  end
end

--------------------------------------------------
-- Notetaking
--------------------------------------------------

local notes_cache = {}
local function open_notes()
  if not notes_cache.file_path then
    local projects_notes_directory = vim.env.HOME .. '/notes/projects'
    if vim.fn.isdirectory(projects_notes_directory) == 0 then
      os.execute('mkdir -p ' .. projects_notes_directory)
    end
    local project_dir = vim.fn.system('git rev-parse --show-toplevel')
    if project_dir:match('fatal:') then
      project_dir = vim.fn.getcwd()
    end
    local project_file_name = project_dir:gsub('%s+', ''):gsub(vim.env.HOME, ''):gsub('/', '__') .. '.md'
    local note_file_path = vim.fs.normalize(projects_notes_directory .. '/' .. project_file_name)
    if vim.tbl_isempty(vim.fs.find(project_file_name, { type = 'file', path = projects_notes_directory })) then
      os.execute('touch ' .. note_file_path)
    end
    local note_buf = vim.api.nvim_create_buf(false, false)
    vim.api.nvim_open_win(note_buf, true, { split = 'right' })
    vim.cmd.edit(note_file_path)
    notes_cache = { buf = note_buf, is_open = true, file_path = note_file_path }
  elseif notes_cache.is_open then
    vim.cmd('w')
    vim.api.nvim_buf_delete(notes_cache.buf, {})
    notes_cache.is_open = false
  else
    local note_buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_open_win(note_buf, true, { split = 'right' })
    vim.cmd.edit(notes_cache.file_path)
    notes_cache.buf = note_buf
    notes_cache.is_open = true
  end
end
vim.keymap.set('n', '<leader>tn', open_notes, { desc = '[T]oggle [N]otes' })

--------------------------------------------------
-- Spell
--------------------------------------------------

-- https://github.com/neovim/neovim/pull/25833/files
-- Change default implementation of z= for spell checking
local spell_on_choice = vim.schedule_wrap(function(_, idx)
  if type(idx) == 'number' then
    vim.cmd.normal({ idx .. 'z=', bang = true })
  end
end)
local spell_select = function()
  if vim.v.count > 0 then
    spell_on_choice(nil, vim.v.count)
    return
  end
  local cword = vim.fn.expand('<cword>')
  vim.ui.select(vim.fn.spellsuggest(cword, vim.o.lines), { prompt = 'Change ' .. cword .. ' to:' }, spell_on_choice)
end
vim.keymap.set('n', 'z=', spell_select, { desc = 'Shows spelling suggestions' })

--------------------------------------------------
-- Abbreviations
--------------------------------------------------

vim.keymap.set('ca', 'Wa', 'wa')
