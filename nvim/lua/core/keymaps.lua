-- Keymaps for better default experience
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Execute q macro
vim.keymap.set('n', 'Q', '@q')

local function delete_all()
  local current_bufnr = vim.api.nvim_win_get_buf(0)
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) and bufnr ~= current_bufnr then
      vim.api.nvim_set_option_value('buflisted', false, { buf = bufnr })
    end
  end
end
-- Return to basics: manage open buffers
vim.keymap.set('n', 'gbb', '<cmd>ls<CR>:b<space>', { desc = 'Change Open [B]uffer' })
vim.keymap.set('n', 'gbn', '<cmd>bnext<CR>', { desc = '[N]ext Open Buffer' })
vim.keymap.set('n', 'gbp', '<cmd>bprevious<CR>', { desc = '[P]revious Open Buffer' })
vim.keymap.set('n', 'gbd', '<cmd>set nobuflisted | silent! bnext<CR>', { desc = '[D]elete Open Buffer' })
-- not using :bdel as it removes the file from diagnostics
vim.keymap.set('n', 'gbo', delete_all, { desc = 'Make [O]nly Buffer' })

-- Remap Escape
vim.keymap.set('i', 'jk', '<Esc>')

-- Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

--Move things around when in visual mode
vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv")
vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv")

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
vim.keymap.set('n', '%', '%zz')
vim.keymap.set('n', '*', '*zz')
vim.keymap.set('n', '#', '#zz')

-- Stay in indent mode
vim.keymap.set('v', '<', '<gv')
vim.keymap.set('v', '>', '>gv')

-- Invert comments line by line
vim.keymap.set('x', 'gci', ':normal gcc<CR>', { desc = 'Invert comments' })

-- gX: Web search
vim.keymap.set('n', 'gX', function()
  vim.ui.open(('https://google.com/search?q=%s'):format(vim.fn.expand('<cword>')))
end)
vim.keymap.set('x', 'gX', function()
  vim.ui.open(
    ('https://google.com/search?q=%s'):format(
      vim.trim(table.concat(vim.fn.getregion(vim.fn.getpos('.'), vim.fn.getpos('v'), { type = vim.fn.mode() }), ' '))
    )
  )
  vim.api.nvim_input('<esc>')
end)

-- Terminal
---@class term
---@field buf_num number
---@field win_id number
---@field is_hidden number

---@type term[]
local terms = {}
---@param num 1|2
local function toggle_term(num)
  local term = terms[num]
  if term.win_id ~= -1 and not vim.list_contains(vim.api.nvim_list_wins(), term.win_id) then
    if vim.list_contains(vim.api.nvim_list_bufs(), term.buf_num) then
      vim.api.nvim_buf_delete(term.buf_num, { force = true })
    end
    term = { buf_num = -1, win_id = -1, is_hidden = -1 }
  end
  if term.buf_num == -1 then
    vim.cmd('vsplit | vertical resize 50 | term')
    term.buf_num = vim.fn.bufnr()
    term.win_id = vim.fn.win_getid()
    term.is_hidden = 0
  elseif term.is_hidden == 1 then
    vim.cmd('vsplit | vertical resize 50 | b' .. term.buf_num)
    term.win_id = vim.fn.win_getid()
    term.is_hidden = 0
  else
    vim.api.nvim_win_close(term.win_id, true)
    term.is_hidden = 1
  end
  terms[num] = term
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

-- window management (NOTE: Check what to do with these keymaps)
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
vim.keymap.set('n', '<C-r>', '<C-w><C-r>', { desc = 'Window [R]otate' })
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
    local wsl_pane = vim.uv.os_uname().release:find('WSL')
    if not wsl_pane and win == vim.api.nvim_get_current_win() then
      local pane_dir = nav[dir]
      vim.system({ 'wezterm', 'cli', 'activate-pane-direction', pane_dir }, { text = true }, function(p)
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
  vim.keymap.set('v', '<leader>' .. pair[1], function()
    if vim.fn.mode() == 'v' then
      return 'c' .. pair[1] .. '<C-r>"' .. pair[2] .. '<ESC>'
    elseif vim.fn.mode() == 'V' then
      return '<ESC>I' .. pair[1] .. '<ESC>A' .. pair[2] .. '<ESC>'
    end
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

-- notetaking
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

-- abbreviations
vim.keymap.set('ca', 'Wa', 'wa')
