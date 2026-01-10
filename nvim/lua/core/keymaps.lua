--------------------------------------------------
-- Basics
--------------------------------------------------

vim.keymap.set({ 'n', 'x' }, 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true })
vim.keymap.set({ 'n', 'x' }, 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true })

vim.keymap.set('n', 'U', '<Nop>', { desc = 'Redo' })

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

vim.keymap.set('n', 'dd', function()
  return vim.fn.getline('.') == '' and '"_dd' or 'dd'
end, { desc = 'Send blank lines to black hole', expr = true })

vim.keymap.set('x', 'r', 'y`mp', { desc = 'Yank and Paste [R]emotely to the m mark' })
vim.keymap.set({ 'n', 'x' }, 'gy', '"+y', { desc = 'Copy to system clipboard' })
vim.keymap.set('n', 'yc', '"yy".v:count1."gcc\']p"', { desc = 'Make a Copy Commentted out', remap = true, expr = true })
vim.keymap.set('x', 'yc', "ygvgc']p", { desc = 'Make a Copy Commentted out', remap = true })
vim.keymap.set('n', '[p', '<cmd>exe "put! " . v:register<CR>', { desc = 'Paste Linewise Above' })
vim.keymap.set('n', ']p', '<cmd>exe "put "  . v:register<CR>', { desc = 'Paste Linewise Below' })

vim.keymap.set({ 'n', 'x' }, '<leader>x', function()
  local esc = vim.keycode('<esc>')
  vim.api.nvim_feedkeys(esc, 'n', false)
  local is_visual = vim.fn.mode():match('[vV\22]')
  local range = is_visual and "'<,'>" or '%'
  vim.cmd(string.format('%ss/\\r//ge | %ss/\\s\\+$//ge | %ss/\\n\\n\\n\\+/\\r\\r/ge', range, range, range))
  if is_visual then
    vim.api.nvim_feedkeys(esc, 'n', false)
  end -- \27 is ESC
end, { desc = 'Cleaning' })

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

vim.keymap.set('n', '/', 'ms/\\V', { desc = 'Add Very Nomagic to Forward Seach and add s Mark' })
vim.keymap.set('x', '/', 'ms<Esc>/\\%V', { desc = 'Search on Selection with Forward Seach and add s Mark' })
vim.keymap.set('n', '?', 'ms?\\V', { desc = 'Add Very Nomagic to Backwards Search and add s Mark' })
vim.keymap.set('x', '?', 'ms<Esc>?\\%V', { desc = 'Search on Selection with Backward Search and add s Mark' })

vim.keymap.set('o', '*', '"<esc>*g``".v:operator."gn"', { desc = 'Repeteable word text-object edit', expr = true })

--------------------------------------------------
-- Window Management
--------------------------------------------------

vim.keymap.set('n', '<C-q>', '<cmd>close<CR>', { desc = 'Window [Q]uit' })

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

---@class notes
---@field index? boolean
---@field extension? 'md'|'curl'

local notes_cache = {}
---@param params? notes -- use index or project local
local function open_notes(params)
  params = params or {}
  local project_dir = params.index and 'index' or vim.fn.getcwd()
  local ext = params.extension or 'md'
  if not notes_cache[project_dir] then
    notes_cache[project_dir] = {}
  end
  local curr_project = notes_cache[project_dir][ext]
  if not curr_project then
    local oss = require('utils.os')
    local projects_notes_directory = oss.joinpath(vim.env.HOME, 'notes', 'dev')
    if vim.fn.isdirectory(projects_notes_directory) == 0 then
      os.execute('mkdir -p ' .. projects_notes_directory)
    end
    local project_file_name
    if params.index then
      project_file_name = 'index.md'
    else
      local git_cmd = vim.system({ 'git', 'rev-parse', '--show-toplevel' }):wait()
      project_file_name = git_cmd.code == 0 and git_cmd.stdout or project_dir
      project_file_name = project_file_name
        :gsub('%s+', '') -- remove spaces in the name
        :gsub(vim.env.HOME, '')
        :gsub('^%w:', '') -- remove disk name in windows
        :gsub('/', '__') -- it can be any separator because windows is a mess
        :gsub('\\', '__')
        .. '.'
        .. ext
    end
    local note_file_path = vim.fs.normalize(oss.joinpath(projects_notes_directory, project_file_name))
    if vim.tbl_isempty(vim.fs.find(project_file_name, { type = 'file', path = projects_notes_directory })) then
      os.execute('touch ' .. note_file_path)
    end
    local note_buf = vim.api.nvim_create_buf(true, false)
    local note_win = vim.api.nvim_open_win(note_buf, true, { split = 'right', width = math.floor(vim.o.columns / 2) })
    vim.cmd.edit(note_file_path)
    notes_cache[project_dir][ext] = { buf = note_buf, win = note_win, file_path = note_file_path }
  elseif curr_project.win and vim.api.nvim_win_is_valid(curr_project.win) then
    vim.cmd('w')
    vim.api.nvim_win_hide(curr_project.win)
    notes_cache[project_dir][ext].win = nil
  else
    local note_buf = vim.api.nvim_buf_is_valid(curr_project.buf) and curr_project.buf
      or vim.api.nvim_create_buf(true, false)
    local note_win = vim.api.nvim_open_win(note_buf, true, { split = 'right', width = math.floor(vim.o.columns / 2) })
    vim.cmd.edit(curr_project.file_path)
    notes_cache[project_dir][ext].buf = note_buf
    notes_cache[project_dir][ext].win = note_win
  end
end

vim.keymap.set('n', '<leader>on', open_notes, { desc = '[O]pen [N]otes' })
vim.keymap.set('n', '<leader>oi', function()
  open_notes({ index = true })
end, { desc = '[O]pen Notes [I]ndex' })
vim.keymap.set('n', '<leader>oc', function()
  open_notes({ extension = 'curl' })
end, { desc = '[O]pen Notes [C]url' })

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

local replace_chars = {
  a = 'á',
  e = 'é',
  i = 'í',
  o = 'ó',
  u = 'ú',
  A = 'Á',
  E = 'É',
  I = 'Í',
  O = 'Ó',
  U = 'Ú',
  n = 'ñ',
  N = 'Ñ',
}
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

vim.keymap.set('n', '<A-;>', 'mzA;`z', { desc = 'Add [;] at the end of the line' })
