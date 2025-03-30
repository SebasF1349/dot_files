--------------------------------------------------
-- Index
--------------------------------------------------

-- LEADER
--- a (alternative files)
--- b (buffer-git)
--- c (code)
---- cf (format)
---- cl (lint)
---- cb (build)
---- ct (test)
--- d (debug)
--- f (telescope)
--- h (hunks)
--- j (splitjoin)
--- l (location list)
--- m (markdown)
--- n (neotest-java)
--- q (quickfix)
--- r (refactoring)
--- s (open in split)
--- t (terminal)
--- v (open in vertical split)
--- w (open in window)

-- g
--- a (arglist)
--- d (generate docs/annotations)
--- r (lsp)

--------------------------------------------------
-- Basics
--------------------------------------------------

vim.keymap.set({ 'i', 'v', 'c' }, 'jk', function()
  if vim.snippet then
    vim.snippet.stop()
  end
  return '<ESC>'
end, { desc = 'Return to normal mode in every mode', expr = true })

vim.keymap.set({ 'n', 'x' }, 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set({ 'n', 'x' }, 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

vim.keymap.set('x', 'J', ":m '>+1<CR>gv=gv")
vim.keymap.set('x', 'K', ":m '<-2<CR>gv=gv")

vim.keymap.set('n', 'U', '<C-r>', { desc = 'Redo' })

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

vim.keymap.set('x', 'I', function()
  return vim.fn.mode() == 'V' and '^<C-v>I' or 'I'
end, { desc = 'Insert on multiple lines', expr = true })
vim.keymap.set('x', 'A', function()
  return vim.fn.mode() == 'V' and '$<C-v>A' or 'A'
end, { desc = 'Append on multiple lines', expr = true })

-- BASH-style movement in cmd and insert mode
vim.keymap.set({ 'i', 'c' }, '<C-a>', '<Home>', { desc = 'Move to start of line' })
vim.keymap.set({ 'i' }, '<C-e>', function()
  if vim.fn.pumvisible() ~= 0 then
    return '<C-e>'
  else
    return '<End>'
  end
end, { desc = 'Move to end of line when no pum', expr = true })
vim.keymap.set({ 'i', 'c' }, '<C-b>', '<Left>', { desc = 'Move to the left' })
vim.keymap.set({ 'c' }, '<C-f>', function()
  local c = vim.fn.getcmdpos()
  return vim.fn.getcmdline():sub(c, c) == '' and '<C-f>' or '<Right>'
end, { desc = 'Move to the right if not in last column', expr = true })
vim.keymap.set({ 'i', 'c' }, '<C-h>', '<BS>', { desc = 'Delete char before' })
vim.keymap.set({ 'i' }, '<C-d>', function()
  local cur = vim.api.nvim_win_get_cursor(0)
  local line = vim.api.nvim_get_current_line()
  if cur[2] >= #line then
    return '<C-d>'
  else
    return '<Delete>'
  end
end, { desc = 'Delete char after if not in last columne', expr = true })
vim.keymap.set({ 'c' }, '<C-d>', '<Delete>', { desc = 'Delete char after' })
vim.keymap.set({ 'i', 'c' }, '<A-b>', '<S-Left>', { desc = 'Move one word to the left' })
vim.keymap.set({ 'i', 'c' }, '<A-f>', '<S-Right>', { desc = 'Move one word to the right' })

vim.keymap.set('x', 'r', 'y`mp', { desc = 'Yank and Paste [R]emotely to the m mark' })

vim.keymap.set({ 'n', 'x' }, 'gy', '"+y', { desc = 'Copy to system clipboard' })
vim.keymap.set('n', 'gp', '"+p', { desc = 'Paste from system clipboard' })
vim.keymap.set('x', 'gp', '"+P', { desc = 'Paste from system clipboard' })

vim.keymap.set('i', '<C-=>', '<C-r>+', { desc = 'Paste from system clipboard in insert mode' })
vim.keymap.set('i', "<C-'>", '<C-r>"', { desc = 'Paste in insertmode' })
vim.keymap.set('i', '<C-0>', '<C-r>0', { desc = 'Paste yanked text in insertmode' })

vim.keymap.set('n', 'dd', function()
  return vim.fn.getline('.') == '' and '"_dd' or 'dd'
end, { desc = 'Send blank lines to black hole', expr = true })

vim.keymap.set('n', 'yc', 'yygccp', { desc = 'Make a Copy Commentted out', remap = true })
vim.keymap.set('v', 'yc', 'ygvgcP', { desc = 'Make a Copy Commentted out', remap = true })

-- better cmdline history
vim.keymap.set('c', '<C-n>', function()
  return vim.fn.wildmenumode() == 1 and '<C-n>' or '<down>'
end, { desc = 'Move Through Cmdline History', expr = true })
vim.keymap.set('c', '<C-p>', function()
  return vim.fn.wildmenumode() == 1 and '<C-p>' or '<up>'
end, { desc = 'Move Through Cmdline History', expr = true })

--------------------------------------------------
-- Searching
--------------------------------------------------

-- NOTE: doesn't work if search results count are larger than screen (but who searches that way?)
vim.api.nvim_create_user_command('GSearch', function(opts)
  vim.api.nvim_input(':g<C-v>/\\V' .. opts.args .. '/#<CR>: ')
end, {
  nargs = '*',
  complete = function(ArgLead, _, _)
    -- https://vi.stackexchange.com/a/25005
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local lines_str = vim.fn.join(lines, ' ')
    local words = vim.fn.split(lines_str, "[ \t~!@#$%^&*+=()<>{}[\\];:|,?\"\\\\/'']\\+")
    words = vim
      .iter(words)
      :filter(function(v)
        return v:find(ArgLead, 1, true)
      end)
      :map(function(v)
        if not v:find('%.') then
          return v
        end
        local variations = {}
        local parts = vim.split(v, '%.')
        for i = 1, #parts do
          local part = table.concat(parts, '.', 1, i)
          if part:find(ArgLead, 1, true) then
            table.insert(variations, part)
          end
        end
        return variations
      end)
      :flatten()
      :totable()
    table.sort(words)
    return vim.fn.uniq(words)
  end,
})
vim.keymap.set('n', 'g/', ':GSearch ', { desc = 'Search with [G]lobal' })

-- stylua: ignore
vim.keymap.set({ 'n', 'x' }, '/', 'ms/\\V', { desc = 'Add Very Nomagic to Forward Seach and add s Mark for easier return' })
-- stylua: ignore
vim.keymap.set({ 'n', 'x' }, '?', 'ms?\\V', { desc = 'Add Very Nomagic to Backwards Search and add s Mark for easier return' })

local function add_magic(cmd_line, cmd_pos)
  local ok, cmd_parsed = pcall(vim.api.nvim_parse_cmd, cmd_line, {})
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

vim.keymap.set('c', '/', function()
  if vim.fn.getcmdtype() ~= ':' then
    return '/'
  end
  local cmd_line = vim.fn.getcmdline()
  local cmd_pos = vim.fn.getcmdpos()
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
    return ' '
  elseif very_nomagic_pos then
    return '\\.\\{-}'
  elseif very_magic_pos then
    return '.{-}'
  end
end

local function fuzzy_find(cmd_line, cmd_pos)
  local ok, cmd_parsed = pcall(vim.api.nvim_parse_cmd, cmd_line, {})
  if not ok then
    return ' '
  end
  local next_cmd_pos = cmd_line:find('|')
  if #cmd_parsed.args == 0 and (cmd_parsed.nextcmd == '' or cmd_pos <= next_cmd_pos) then
    return ' '
  end
  if next_cmd_pos and cmd_pos > next_cmd_pos then
    return fuzzy_find(cmd_line:sub(next_cmd_pos + 1), cmd_pos - next_cmd_pos)
  end
  local edit_cmds = { 'edit', 'split', 'vsplit' }
  local find_cmds = { 'find', 'sfind' }
  if vim.list_contains(edit_cmds, cmd_parsed.cmd) then
    return (cmd_line:sub(cmd_pos - 2, cmd_pos - 1) == '**') and '/*' or '*'
  elseif vim.list_contains(find_cmds, cmd_parsed.cmd) then
    return '.*'
  elseif cmd_parsed.cmd == 'help' then
    return '*'
  else
    return get_fuzzy(cmd_line)
  end
end

vim.keymap.set('c', '<space>', function()
  local mode = vim.fn.getcmdtype()
  local cmd_line = vim.fn.getcmdline()
  if mode == '?' or mode == '/' then
    return get_fuzzy(cmd_line)
  elseif mode == ':' then
    local cmd_pos = vim.fn.getcmdpos()
    return fuzzy_find(cmd_line, cmd_pos)
  else
    return ' '
  end
end, { desc = 'Use <space> to "Fuzzy Find"', expr = true })

vim.keymap.set('c', '<C-space>', '<space>', { desc = 'Easier Space' })

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

vim.keymap.set(
  'n',
  '<C-w>\\',
  [[<cmd>exe min([winheight('%'),line('$')]).'wincmd _'<CR>]],
  { desc = 'Set Height Equal to Buffer Height' }
)
vim.keymap.set(
  'x',
  '<C-w>\\',
  [[<esc><cmd>exe (line("'>") - line("'<") + 1).'wincmd _'<CR>]],
  { desc = 'Set Height Equal to Selection Height' }
)
vim.keymap.set(
  'n',
  '<C-w>|',
  [[<cmd>exe (col('$') + 7).'wincmd |'<bar>setlocal winfixwidth<CR>]],
  { desc = 'Set Width Equal to Line Width' }
)

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

  local diff
  if dir == 'h' or dir == 'k' then
    diff = have_neighbor_to(resize_dir[dir].inverted) and -amount or amount
  else
    diff = have_neighbor_to(dir) and amount or -amount
  end

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
-- Toggler
--------------------------------------------------

-- Based on https://github.com/Wansmer/nvim-config/blob/main/lua/modules/toggler.lua
-- Every key and value should be in lowercase
local opposites = {
  ['true'] = 'false',
  ['false'] = 'true',
  ['const'] = 'let',
  ['let'] = 'const',
  ['global'] = 'local',
  ['local'] = 'global',
  ['==='] = '!==',
  ['!=='] = '===',
  ['=='] = '!=',
  ['!='] = '<=',
  ['<='] = '<',
  ['<'] = '>',
  ['>'] = '>=',
  ['>='] = '==',
  ['&&'] = '||',
  ['||'] = '&&',
  ['and'] = 'or',
  ['or'] = 'and',
}

---Convert string's chars to same case like base string
---If base string length less than target string, other chars will convert to case
---like last char in base string.
---@param base string Base string
---@param str string String to convert
---@return string
local function to_same_register(base, str)
  local base_list = vim.split(base, '', { plain = true })
  local target_list = vim.split(str, '', { plain = true })

  for i, ch in ipairs(target_list) do
    local base_char = base_list[i] or base_list[#base_list]
    target_list[i] = base_char == base_char:lower() and string.lower(ch) or string.upper(ch)
  end

  return table.concat(target_list)
end

local function toggle_word()
  local ikw_orig = vim.opt.iskeyword:get()
  vim.opt.iskeyword:append({ '!', '=', '<', '>', '&', '|' })

  local text = vim.fn.expand('<cword>')

  -- Checking if the symbol under cursor is a part of received word
  -- (required to prevent wrong inserting, when cursor at punctuation and whitespace before the target word)
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1
  local char = vim.api.nvim_get_current_line():sub(col, col)
  local contains = string.find(tostring(text), char, 1, true) and true or false

  local opp = text and contains and opposites[string.lower(tostring(text))]

  if opp then
    vim.cmd('normal! "_ciw' .. to_same_register(tostring(text), opp))
  else
    vim.cmd('normal! ')
  end

  vim.opt.iskeyword = ikw_orig
end

vim.keymap.set('n', '<C-a>', toggle_word, { desc = 'Toggle keywords' })

--------------------------------------------------
-- Abbreviations
--------------------------------------------------

local cmds_typos = { 'W', 'Wa', 'WA', 'X', 'Xa', 'XA' }
for _, cmd in ipairs(cmds_typos) do
  vim.keymap.set('ca', cmd, cmd:lower())
end

local custom_cmds_typos = { 'ME', 'MEss', 'RG', 'LA', 'MAson' }
for _, cmd in ipairs(custom_cmds_typos) do
  vim.keymap.set('ca', cmd, cmd:sub(1, 1):upper() .. cmd:sub(2):lower())
end
