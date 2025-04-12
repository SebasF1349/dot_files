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
local formatopts = vim.bo.formatoptions
vim.bo.formatoptions = formatopts .. 'cro'
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

vim.b.undo_ftplugin = (vim.b.undo_ftplugin or '')
  .. '\n '
  .. 'setlocal tabstop< softtabstop< shiftwidth< expandtab< textwidth< colorcolumn< wrap< wrapmargin< linebreak< spell< spelllang< comments< formatoptions< '
  .. ' | sil! nunmap <buffer> gO'
  .. ' | sil! nunmap <buffer> <leader>mt'
  .. ' | sil! nunmap <buffer> gl'
  .. ' | sil! vunmap <buffer> gl'
  .. ' | sil! nunmap <buffer> <leader>x'
