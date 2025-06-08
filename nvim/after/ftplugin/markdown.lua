-- NOTE: missing features: tables, mappings to create links & lists, increasing/decreasing headers, toggle todo
-- ideas to add todos: https://github.com/phux/.dotfiles/blob/master/roles/neovim/files/ftplugin/markdown.vim

if vim.o.buftype ~= '' then
  return
end

vim.bo.tabstop = 2
vim.bo.softtabstop = 2
vim.bo.shiftwidth = 2
vim.bo.expandtab = true
vim.bo.textwidth = 0
vim.wo.colorcolumn = '81'
vim.wo.wrap = true
vim.bo.wrapmargin = 0
vim.wo.linebreak = true
vim.wo.spell = true
vim.bo.spelllang = 'es,en'
-- automatically continue lists
vim.bo.formatoptions = vim.bo.formatoptions .. 'ro'
vim.bo.comments = 'b:-,b:+,b:*'

vim.keymap.set(
  'n',
  '<leader>mt',
  'i<!-- toc --><ESC><cmd>w<CR>',
  { desc = 'Add [M]arkdown [T]OC using markdown-toc', buffer = 0 }
)

function _G.MakeList()
  local starting = vim.api.nvim_buf_get_mark(0, '[')
  local ending = vim.api.nvim_buf_get_mark(0, ']')
  local line_start = starting[1]
  local line_end = ending[1]
  vim.cmd(line_start .. ',' .. line_end .. [[s/\v^(\s*)[^a-zA-Z]*(.*)/\1- \2]])
end

vim.keymap.set(
  { 'n', 'v' },
  'gl',
  _G.opfunc('_G.MakeList'),
  { desc = 'Make [L]ist', silent = true, expr = true, buffer = 0 }
)

vim.keymap.set('n', '<leader>x', function()
  local line = vim.api.nvim_get_current_line()
  if line:find('- [ ]', 1, true) then
    local new_line = line:gsub('- %b[]', '- [x]')
    vim.api.nvim_set_current_line(new_line)
  elseif line:find('- [x]', 1, true) then
    local new_line = line:gsub('- %b[]', '- [ ]')
    vim.api.nvim_set_current_line(new_line)
  end
end, { desc = 'Toggle TODO', buffer = 0 })

local oss = require('utils.os')
local notes_path = oss.joinpath(vim.env.HOME, 'notes', 'dev')
local curr_buf = oss.correct_separator(vim.api.nvim_buf_get_name(0))

if vim.startswith(curr_buf, notes_path) then
  local function select_link(text)
    local notes = vim.split(vim.fn.glob(notes_path .. '/*'), '\n', { trimempty = true })
    notes = vim.tbl_filter(function(note_buf)
      return note_buf ~= curr_buf
    end, notes)

    vim.ui.select(notes, {
      prompt = 'Select notes file:',
      format_item = function(item)
        return item
      end,
    }, function(choice)
      if not choice then
        if text then
          vim.api.nvim_put({ text }, 'c', true, true)
        end
        return
      end
      if text then
        vim.api.nvim_put({ '[' .. text .. '](' .. choice .. ')' }, 'c', true, true)
      else
        vim.api.nvim_put({ '[](' .. choice .. ')' }, 'c', true, true)
        vim.api.nvim_input('cil[')
      end
    end)
  end

  vim.keymap.set({ 'n', 'i' }, '<C-l>', function()
    vim.cmd.stopinsert()
    select_link()
  end, { desc = 'Add [L]ink', buffer = 0 })

  vim.keymap.set({ 'x' }, '<C-l>', function()
    local starting = vim.fn.getpos('v')
    local ending = vim.fn.getpos('.')
    if starting[2] > ending[2] or (starting[2] == ending[2] and starting[3] > ending[3]) then
      starting, ending = ending, starting
    end
    local text = vim.api.nvim_buf_get_text(0, starting[2] - 1, starting[3] - 1, ending[2] - 1, ending[3], {})
    vim.api.nvim_buf_set_text(0, starting[2] - 1, starting[3] - 1, ending[2] - 1, ending[3], { '' })
    select_link(text[1])
  end, { desc = 'Add [L]ink', buffer = 0 })

  vim.keymap.set('n', 'gf', function()
    local node = vim.treesitter.get_node({ ignore_injections = false })
    if not node then
      return
    end
    if node:type() == 'link_text' then
      node = node:next_named_sibling()
    elseif node:type() == 'inline_link' then
      node = node:named_child(1)
    end
    if not node or node:type() ~= 'link_destination' then
      vim.notify('Not a valid file path', vim.log.levels.INFO)
      return
    end
    local link = vim.treesitter.get_node_text(node, 0, {})
    if not vim.startswith(link, '/') and not link:find('^%w:') then
      link = vim.fn.expand('%:p:h') .. [[/]] .. link
    end
    vim.cmd.edit(link)
  end, { desc = 'Open link under the cursor', buffer = 0 })

  vim.b.undo_ftplugin = (vim.b.undo_ftplugin or '')
    .. '\n '
    .. 'sil! nunmap <buffer> <C-l>'
    .. ' | sil! xunmap <buffer> <C-l>'
    .. ' | sil! iunmap <buffer> <C-l>'
    .. ' | sil! nunmap <buffer> gf'
end

vim.b.undo_ftplugin = (vim.b.undo_ftplugin or '')
  .. '\n '
  .. 'setlocal tabstop< softtabstop< shiftwidth< expandtab< textwidth< colorcolumn< wrap< wrapmargin< linebreak< spell< spelllang< comments< formatoptions< '
  .. ' | sil! nunmap <buffer> gO'
  .. ' | sil! nunmap <buffer> <leader>mt'
  .. ' | sil! nunmap <buffer> gl'
  .. ' | sil! vunmap <buffer> gl'
  .. ' | sil! nunmap <buffer> <leader>x'
