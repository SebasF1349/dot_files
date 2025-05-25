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

vim.keymap.set({ 'n', 'x' }, 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set({ 'n', 'x' }, 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

vim.keymap.set('n', 'U', '<C-r>', { desc = 'Redo' })

-- Stay in indent mode
vim.keymap.set('x', '<', '<gv', { desc = 'Stay in visual mode after indenting' })
vim.keymap.set('x', '>', '>gv', { desc = 'Stay in visual mode after indenting' })

vim.keymap.set('n', "'", '`', { desc = "Swap ` with ' because is a better way to jump to marks" })
vim.keymap.set('n', '`', "'", { desc = "Swap ` with ' because is a better way to jump to marks" })

vim.keymap.set('x', '.', ':normal .<CR>', { desc = 'Use . to repeat last change in selection' })

vim.keymap.set('x', 'gci', ':normal gcc<CR>', { desc = 'Invert comments line by line' })

vim.keymap.set('x', 'I', function()
  return vim.api.nvim_get_mode().mode == 'V' and '^<C-v>I' or 'I'
end, { desc = 'Insert on multiple lines', expr = true })
vim.keymap.set('x', 'A', function()
  return vim.api.nvim_get_mode().mode == 'V' and '$<C-v>A' or 'A'
end, { desc = 'Append on multiple lines', expr = true })


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

vim.keymap.set('n', 'yc', '"yy".v:count1."gcc\']p"', { desc = 'Make a Copy Commentted out', remap = true, expr = true })
vim.keymap.set('v', 'yc', "ygvgc']p", { desc = 'Make a Copy Commentted out', remap = true })

-- better cmdline history
vim.keymap.set('c', '<C-n>', function()
  return vim.fn.wildmenumode() == 1 and '<C-n>' or '<down>'
end, { desc = 'Move Through Cmdline History', expr = true })
vim.keymap.set('c', '<C-p>', function()
  return vim.fn.wildmenumode() == 1 and '<C-p>' or '<up>'
end, { desc = 'Move Through Cmdline History', expr = true })

vim.keymap.set('i', '<C-l>', function()
  local curr_node = vim.treesitter.get_node({ ignore_injections = false })
  if not curr_node then
    return
  end
  local rowe, cole = curr_node:end_()
  if vim.fn.line('$') == rowe then
    return
  end
  vim.api.nvim_win_set_cursor(0, { rowe + 1, cole })
end, { desc = 'Escape TS Node in Insert Mode' })

--------------------------------------------------
-- Searching
--------------------------------------------------

vim.keymap.set({ 'n', 'x' }, '/', 'ms/\\V', { desc = 'Add Very Nomagic to Forward Seach and add s Mark' })
vim.keymap.set({ 'n', 'x' }, '?', 'ms?\\V', { desc = 'Add Very Nomagic to Backwards Search and add s Mark' })

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
    return '<c-]><space>'
  elseif very_nomagic_pos then
    return '\\.\\{-}'
  elseif very_magic_pos then
    return '.{-}'
  end
end

local function fuzzy_find(cmd_line, cmd_pos)
  local ok, cmd_parsed = pcall(vim.api.nvim_parse_cmd, cmd_line, {})
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
    return '<c-]><space>'
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

vim.keymap.set('n', '<C-;>', 'mzA;`z', { desc = 'Add [;] at the end of the line' })

--------------------------------------------------
-- Abbreviations
--------------------------------------------------

local cmds_typos = { 'W', 'Wa', 'WA', 'X', 'Xa', 'XA', 'H' }
for _, cmd in ipairs(cmds_typos) do
  vim.keymap.set('ca', cmd, cmd:lower())
end

local custom_cmds_typos = { 'ME', 'MEss', 'RG', 'LA', 'MAson' }
for _, cmd in ipairs(custom_cmds_typos) do
  vim.keymap.set('ca', cmd, cmd:sub(1, 1):upper() .. cmd:sub(2):lower())
end
