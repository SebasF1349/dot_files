--------------------------------------------------
-- Basics
--------------------------------------------------

vim.keymap.set({ 'n', 'x' }, 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true })
vim.keymap.set({ 'n', 'x' }, 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true })

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

vim.keymap.set({ 'n', 'x' }, 'gy', '"+y', { desc = 'Copy to system clipboard' })
vim.keymap.set('n', 'yc', '"yy".v:count1."gcc\']p"', { desc = 'Make a Copy Commentted out', remap = true, expr = true })
vim.keymap.set('x', 'yc', "ygvgc']p", { desc = 'Make a Copy Commentted out', remap = true })
vim.keymap.set('n', '[p', '<cmd>exe "iput! " . v:register<CR>', { desc = 'Paste Linewise Above' })
vim.keymap.set('n', ']p', '<cmd>exe "iput "  . v:register<CR>', { desc = 'Paste Linewise Below' })

vim.keymap.set('o', '*', '"<esc>*g``".v:operator."gn"', { desc = 'Repeteable word text-object edit', expr = true })

vim.keymap.set('n', '-', '<Plug>(nvim-dir-up)', { desc = 'Open dir.lua' })

--------------------------------------------------
-- Window Management
--------------------------------------------------

local wezterm = require('utils.wezterm')

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
      wezterm.cli({ 'activate-pane-direction', nav[dir] }, 'Failed to move to pane ' .. nav[dir])
    end
  end
end

for key, direction in pairs(nav) do
  vim.keymap.set({ 'n', 't' }, '<A-' .. key .. '>', navigate(key), { desc = 'Move to Window ' .. direction })
end

local resize_dir = {
  h = { key = '<', dir = 'Left', nv_key = '<LT>', inverted = 'l', desc = 'Resize Window [<]Smaller Horizontally' }, -- can't use < with nvim_input
  l = { key = '>', dir = 'Right', nv_key = '>', inverted = 'h', desc = 'Resize Window [>]Bigger Horizontally' },
  k = { key = ',', dir = 'Up', nv_key = '-', inverted = 'j', desc = 'Resize Window [<]Smaller Vertically' },
  j = { key = '.', dir = 'Down', nv_key = '+', inverted = 'k', desc = 'Resize Window [<]Bigger Vertically' },
}

---@param dir 'h' | 'j' | 'k' | 'l'
---@return boolean # True if the window have neighbor to 'dir'.
local function have_neighbor_to(dir)
  return vim.fn.winnr(dir) ~= vim.fn.winnr()
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
      wezterm.cli({ 'adjust-pane-size', resize_dir[dir].dir }, 'Failed to resize pane ' .. resize_dir[dir].dir)
    end
  end
end

for dir, content in pairs(resize_dir) do
  vim.keymap.set({ 'n', 't' }, '<A-' .. content.key .. '>', resize(dir), { desc = content.desc })
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

---@param params? notes -- use index or project local
local function open_notes(params)
  params = params or {}
  local ext = params.extension or 'md'

  local dir = vim.fs.joinpath(vim.env.HOME, 'notes', 'dev')
  vim.fs.mkdir(dir, { parents = true })

  local file_name
  if params.index then
    file_name = 'index.md'
  else
    local res = vim.system({ 'git', 'rev-parse', '--show-toplevel' }, { text = true }):wait()
    local root = res.code == 0 and vim.trim(res.stdout) or vim.uv.cwd()
    assert(root, 'Cannot determine cwd')
    file_name = vim.fs.slug(root) .. '.' .. ext
  end

  local buf = vim.fn.bufadd(vim.fs.joinpath(dir, file_name))
  vim.bo[buf].swapfile = false -- must be set BEFORE the buffer is loaded
  vim.fn.bufload(buf)
  vim.bo[buf].buflisted = true

  local tab = vim.api.nvim_get_current_tabpage()
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    if vim.api.nvim_win_get_tabpage(win) == tab then
      vim.api.nvim_buf_call(buf, function()
        vim.cmd('silent! update')
      end)
      vim.api.nvim_win_hide(win)
      return
    end
  end

  vim.api.nvim_open_win(buf, true, {
    split = 'right',
    width = math.floor(vim.o.columns / 2),
  })
end

vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter' }, {
  callback = function()
    if vim.fn.mode() ~= 'c' then
      vim.cmd('silent! checktime')
    end
  end,
  desc = 'Reload files changed outside this instance',
})

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

-- stylua: ignore
local replace_chars = {
  a = 'á', e = 'é', i = 'í', o = 'ó', u = 'ú',
  A = 'Á', E = 'É', I = 'Í', O = 'Ó', U = 'Ú',
  n = 'ñ', N = 'Ñ',
}
local reverse_chars = {}
for k, v in pairs(replace_chars) do
  reverse_chars[v] = k
end

vim.keymap.set('n', "g'", function()
  local line, col = vim.api.nvim_get_current_line(), vim.api.nvim_win_get_cursor(0)[2] + 1
  local char = line:sub(col, col + vim.str_utf_end(line, col))
  if replace_chars[char] then
    return 'r' .. replace_chars[char]
  elseif reverse_chars[char] then
    return 'r' .. reverse_chars[char]
  end
end, { desc = 'Add tilde to letters', expr = true })

vim.keymap.set('n', '<A-;>', 'mzA;`z', { desc = 'Add [;] at the end of the line' })
