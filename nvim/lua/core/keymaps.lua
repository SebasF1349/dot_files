--------------------------------------------------
-- Basics
--------------------------------------------------

vim.keymap.set('i', 'jk', '<Esc>')

-- Remaps for dealing with word wrap
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
vim.keymap.set('n', 'e', [[<cmd>call search('.\ze\>')<CR>]], { desc = 'End Next word' })
vim.keymap.set('n', 'ge', [[<cmd>call search('.\ze\>', 'b')<CR>]], { desc = 'End Previous word' })
vim.keymap.set('n', '{', [[<cmd>call search('\(\n\n\|\%^\)\s*\zs\S', 'b')<CR>]], { desc = 'Start Previous Paragraph' })
vim.keymap.set('n', '}', [[<cmd>call search('\n\n\s*\zs\S')<CR>]], { desc = 'Start Next Paragraph' })

vim.keymap.set('n', "'", '`', { desc = "Swap ` with ' because is a better way to jump to marks" })
vim.keymap.set('n', '`', "'", { desc = "Swap ` with ' because is a better way to jump to marks" })

vim.keymap.set('x', '.', ':normal .<CR>', { desc = 'Use . to repeat last change in selection' })

vim.keymap.set('x', 'gci', ':normal gcc<CR>', { desc = 'Invert comments line by line' })

-- Add bash shortcuts for command line
vim.keymap.set('c', '<C-a>', '<Home>', { desc = 'Move to start of line in cmdline mode' })
vim.keymap.set('c', '<C-b>', '<Left>', { desc = 'Move to the left in cmdline mode' })
vim.keymap.set('c', '<C-f>', '<Right>', { desc = 'Move to the right in cmdline mode' })
vim.keymap.set('c', '<C-d>', '<Delete>', { desc = 'Delete char in cmdline mode' })
vim.keymap.set('c', '<M-b>', '<S-Left>', { desc = 'Move one word to the left in cmdline mode' })
vim.keymap.set('c', '<M-f>', '<S-Right>', { desc = 'Move one word to the right in cmdline mode' })

-- BASH-style movement in insert mode
vim.keymap.set('i', '<C-a>', '<C-o>^', { desc = 'Move to start of line in insert mode' })
vim.keymap.set('i', '<C-e>', '<C-o>$', { desc = 'Move to end of line in insert mode' })

vim.keymap.set('x', 'r', 'y`mp', { desc = 'Yank and Paste [R]emotely to the m mark' })

vim.keymap.set('n', 'dd', function()
  return vim.fn.getline('.') == '' and '"_dd' or 'dd'
end, { desc = 'Send blank lines to black hole', expr = true })
vim.keymap.set('n', 'dl', '0d$', { desc = '[D]elete [L]ine without newline' })
vim.keymap.set('n', 'yl', '0y$', { desc = '[Y]ank [L]ine without newline' })

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
    vim.cmd('botright vsplit | vertical resize 50 | set winfixwidth winfixheight | term')
    term.buf_num = vim.api.nvim_get_current_buf()
    term.win_id = vim.api.nvim_get_current_win()
    vim.api.nvim_set_option_value('winhighlight', 'Normal:TerminalNormal', { win = term.win_id, scope = 'local' })
  elseif term.win_id == -1 then
    vim.cmd('botright vsplit | vertical resize 50 | set winfixwidth winfixheight | b' .. term.buf_num)
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

vim.keymap.set({ 'n', 't' }, 'tb', function()
  local win = (terms[1].win_id and terms[1].win_id ~= -1) and terms[1].win_id or terms[2].win_id
  if win and win ~= -1 and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_set_current_win(win)
  end
end, { desc = 'Move to [T]erminal [B]uffer ' })

vim.keymap.set('t', 'jk', '<C-\\><C-n>', { desc = 'Escape Terminal Mode' })

local function scroll_to_end(bufnr, winid)
  vim.api.nvim_buf_call(bufnr, function()
    local target_line = vim.tbl_count(vim.api.nvim_buf_get_lines(bufnr, 0, -1, true))
    vim.api.nvim_win_set_cursor(winid, { target_line, 0 })
  end)
end

---@param cmd string
local function run_term_command(cmd)
  vim.cmd('wa')
  local term = terms[1]
  check_term_data(term)
  if term.win_id == -1 then
    toggle_term(1)
  end
  scroll_to_end(term.buf_num, term.win_id)
  local terminal_job_id = (vim.api.nvim_buf_get_var(term.buf_num, 'terminal_job_id'))
  vim.api.nvim_chan_send(terminal_job_id, '\n')
  vim.api.nvim_chan_send(terminal_job_id, cmd .. '\n')
end

-- NOTE: improve keymaps checking this plugin code: https://github.com/samharju/yeet.nvim/blob/master/lua/yeet/buffer.lua
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

-- maybe replace with https://github.com/yujinyuz/vms.nvim if needed (range aware)
vim.keymap.set('c', '/', function()
  if vim.fn.getcmdtype() ~= ':' then
    return '/'
  end
  local cmd_line = vim.fn.getcmdline()
  local cmds = { 's', 'g', 'v' }
  for _, cmd in ipairs(cmds) do
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
      if not cmd_line:find(' ') then
        return ' '
      end
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
-- Window Management
--------------------------------------------------

vim.keymap.set('n', '<C-q>', '<cmd>close<CR>', { desc = 'Window [Q]uit' })
vim.keymap.set('n', '<C-r>', '<C-w><C-w>', { desc = 'Move A[R]ound Windows' })

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

for key, direction in pairs(nav) do
  vim.keymap.set({ 'n', 't' }, '<C-' .. key .. '>', navigate(key), { desc = 'Move to Window ' .. direction })
end

local resize_dir = {
  h = { key = '<', dir = 'Left', nv_key = '<LT>', inverted = 'l', desc = 'Resize Window [<]Smaller Horizontally' }, -- can't use < with nvim_input
  l = { key = '>', dir = 'Right', nv_key = '>', inverted = 'h', desc = 'Resize Window [>]Bigger Horizontally' },
  k = { key = ',', dir = 'Up', nv_key = '-', inverted = 'j', desc = 'Resize Window [<]Smaller Vertically' },
  j = { key = '.', dir = 'Down', nv_key = '+', inverted = 'k', desc = 'Resize Window [<]Bigger Vertically' },
}

-- copied from https://github.com/pogyomo/winresize.nvim/blob/main/lua/winresize.lua#L24
---@param dir 'h' | 'j' | 'k' | 'l'
---@return boolean # True if the window have neighbor to 'dir'.
local function have_neighbor_to(dir)
  local neighbor = vim.api.nvim_win_call(0, function()
    vim.cmd.wincmd(dir)
    return vim.api.nvim_get_current_win()
  end)
  return vim.api.nvim_get_current_win() ~= neighbor
end

---@param dir 'h' | 'j' | 'k' | 'l'
local function resize_window(dir)
  local amount = 5
  local postfix = (dir == 'h' or dir == 'l') and 'width' or 'height'
  local setter = vim.api['nvim_win_set_' .. postfix]
  local getter = vim.api['nvim_win_get_' .. postfix]

  -- Prevent statusline moves.
  if postfix == 'height' and not have_neighbor_to('j') and not have_neighbor_to('k') then
    return
  end

  if dir == 'h' or dir == 'k' then
    dir = resize_dir[dir].inverted
  end

  local diff = have_neighbor_to(dir) and amount or -amount
  setter(0, getter(0) + diff)
end

---@param dir 'h' | 'j' | 'k' | 'l'
---@return function
local function resize(dir)
  return function()
    local win = vim.api.nvim_get_current_win()
    local height, width = vim.api.nvim_win_get_height(win), vim.api.nvim_win_get_width(win)
    resize_window(dir)
    local new_height, new_width = vim.api.nvim_win_get_height(win), vim.api.nvim_win_get_width(win)
    if height == new_height and width == new_width then
      local cmd = vim.uv.os_uname().release:find('WSL') and 'wezterm.exe' or 'wezterm'
      vim.system({ cmd, 'cli', 'adjust-pane-size', resize_dir[dir].dir }, { text = true }, function(p)
        if p.code ~= 0 then
          vim.notify(
            'Failed resize move to pane ' .. resize_dir[dir].dir .. '\n' .. p.stderr,
            vim.log.levels.ERROR,
            { title = 'Wezterm' }
          )
        end
      end)
    end
  end
end

for dir, content in pairs(resize_dir) do
  vim.keymap.set({ 'n', 't' }, '<C-' .. content.key .. '>', resize(dir), { desc = content.desc })
end

--------------------------------------------------
-- Zoom Window
--------------------------------------------------

-- lua translation from https://github.com/justinmk/config/blob/master/.config/nvim/plugin/winning.lua#L61C1-L80C56
local zoom_restore
local function zoom_toggle()
  if vim.fn.winnr('$') == 1 then
    return
  end
  if zoom_restore then
    vim.cmd(zoom_restore)
    zoom_restore = nil
  else
    zoom_restore = vim.fn.winrestcmd()
    vim.cmd.wincmd('|')
    vim.cmd.wincmd('_')
  end
end

vim.keymap.set('n', '+', zoom_toggle, { desc = 'Toggle Window Zoom' })

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
  vim.keymap.set(
    'n',
    'ys' .. pair[1],
    '"sciw' .. pair[1] .. '<C-r>s' .. pair[2] .. '<ESC>',
    { desc = '[Y]ou [S]urround with [' .. pair[1] .. ']' }
  )

  vim.keymap.set('x', 's', '<NOP>', { desc = 'Disable v_s to be able to use surround' })
  vim.keymap.set(
    'x',
    's' .. pair[1],
    '"sc' .. pair[1] .. '<C-r>s' .. pair[2] .. '<ESC>',
    { desc = '[S]urround with [' .. pair[1] .. ']' }
  )

  vim.keymap.set(
    'n',
    'ds' .. pair[1],
    '"sci' .. pair[1] .. '<BS><Del><C-r>s',
    { desc = '[D]elete [S]urrounding [' .. pair[1] .. ']' }
  )

  for _, replace in ipairs(surround) do
    vim.keymap.set(
      'n',
      'cs' .. pair[1] .. replace[1],
      '"sci' .. pair[1] .. '<BS><Del>' .. replace[1] .. '<C-r>s' .. replace[2],
      { desc = '[C]hange [S]urround [' .. pair[1] .. '] with [' .. replace[1] .. ']' }
    )
  end
end

--------------------------------------------------
-- Substitute
--------------------------------------------------

local function opfunc(func_name)
  return function()
    vim.o.operatorfunc = 'v:lua.' .. func_name
    return 'g@'
  end
end

-- based on https://www.reddit.com/r/neovim/comments/xrwo05/comment/ja7oyqy/
---@param mode "char"|"line"|"block"
function _G.Substitute(mode)
  local reg = vim.fn.getreg('"')
  local starting = vim.api.nvim_buf_get_mark(0, '[')
  local ending = vim.api.nvim_buf_get_mark(0, ']')
  if mode == 'char' then
    vim.api.nvim_buf_set_text(0, starting[1] - 1, starting[2], ending[1] - 1, ending[2] + 1, { reg })
  elseif mode == 'line' then
    vim.api.nvim_buf_set_lines(0, starting[1] - 1, ending[1], true, { reg })
  elseif mode == 'block' then
    for i = starting[1] - 1, ending[1] - 1 do
      vim.api.nvim_buf_set_text(0, i, starting[2], i, ending[2] + 1, { reg })
    end
  end
end

vim.keymap.set(
  { 'n', 'v' },
  'S',
  opfunc('_G.Substitute'),
  { desc = '[S]ubstitute Operator', silent = true, expr = true }
)

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

---@param move? 1 | -1
local spell_select = function(move)
  if not vim.o.spell then
    vim.notify('Spelling is OFF', vim.lsp.log_levels.WARN)
    return
  end

  local cursor_pos = vim.api.nvim_win_get_cursor(0)

  if move == 1 then
    vim.cmd.normal({ ']s', bang = true })
  elseif move == -1 then
    vim.cmd.normal({ '[s', bang = true })
  end

  local new_cursor_pos = vim.api.nvim_win_get_cursor(0)
  if move and cursor_pos[1] == new_cursor_pos[1] and cursor_pos[2] == new_cursor_pos[2] then
    vim.notify('No more words to fix', vim.lsp.log_levels.WARN)
    return
  end

  if vim.v.count > 0 then
    spell_on_choice(nil, vim.v.count)
    return
  end

  -- stealed from https://github.com/echasnovski/mini.cursorword/blob/7a9f1ec73c52124abc39f0309d332ababefc68b2/lua/mini/cursorword.lua#L246
  local current_word_pattern = [[\k*\%#\k*]]
  local match_id_current = vim.fn.matchadd('Underlined', current_word_pattern, -1)

  local cword = vim.fn.expand('<cword>')
  vim.ui.select(vim.fn.spellsuggest(cword, vim.o.lines), { prompt = 'Change ' .. cword .. ' to:' }, function(item, i)
    vim.fn.matchdelete(match_id_current)
    spell_on_choice(item, i)
  end)
end
vim.keymap.set('n', 'z=', spell_select, { desc = 'Shows spelling suggestions' })
vim.keymap.set('n', ']s', function()
  spell_select(1)
end, { desc = 'Shows next spelling suggestions' })
vim.keymap.set('n', '[s', function()
  spell_select(-1)
end, { desc = 'Shows previous spelling suggestions' })

local replace_chars =
  { a = 'á', e = 'é', i = 'í', o = 'ó', u = 'ú', A = 'Á', E = 'É', I = 'Í', O = 'Ó', U = 'Ú' }
vim.keymap.set('n', "g'", function()
  local line, col = vim.api.nvim_get_current_line(), vim.fn.col('.')
  local char = line:sub(col, col + vim.str_utf_end(line, col))
  for k1, k2 in pairs(replace_chars) do
    if char == k1 then
      return 'r' .. k2
    elseif char == k2 then
      return 'r' .. k1
    end
  end
end, { desc = 'Add tilde to letters', expr = true })

vim.keymap.set('n', '<leader>;', 'mzA;`z', { desc = 'Add [;] at the end of the line' })
--------------------------------------------------
-- Abbreviations
--------------------------------------------------

vim.keymap.set('ca', 'Wa', 'wa')
