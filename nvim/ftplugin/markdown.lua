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

local function show_toc()
  local bufname = vim.api.nvim_buf_get_name(0)
  local info = vim.fn.getloclist(0, { winid = 1 })
  if vim.tbl_isempty(info) and vim.api.nvim_get_option_value('qf_toc', { win = info.winid }) == #bufname then
    vim.cmd('lopen')
    return
  end
  local list = vim
    .iter(ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)))
    :filter(function(_, line)
      return line:match('^#+')
    end)
    :map(function(lnum, line)
      return { bufnr = vim.fn.bufnr('%'), lnum = lnum, text = line }
    end)
    :totable()
  vim.fn.setloclist(0, list, ' ')
  vim.cmd('lopen')
  vim.w.qf_toc = bufname
end

-- NOTE: this may not be needed when https://github.com/neovim/neovim/pull/32282 gets merged
vim.keymap.set('n', 'gO', show_toc, { desc = 'Show TOC', buffer = 0 })

vim.keymap.set('n', '<leader>mt', 'i<!-- toc --><ESC><cmd>w<CR>', { desc = 'Add [M]arkdown [T]OC using markdown-toc' })

function _G.MakeList()
  local starting = vim.api.nvim_buf_get_mark(0, '[')
  local ending = vim.api.nvim_buf_get_mark(0, ']')
  local line_start = starting[1]
  local line_end = ending[1]
  vim.cmd(line_start .. ',' .. line_end .. [[s/\v^(\s*)[^a-zA-Z]*(.*)/\1- \2]])
end

vim.keymap.set({ 'n', 'v' }, 'gl', _G.opfunc('_G.MakeList'), { desc = 'Make [L]ist', silent = true, expr = true })

vim.keymap.set('n', '<leader>x', function()
  local line = vim.api.nvim_get_current_line()
  if line:find('- [ ]', 1, true) then
    local new_line = line:gsub('- %b[]', '- [x]')
    vim.api.nvim_set_current_line(new_line)
  elseif line:find('- [x]', 1, true) then
    local new_line = line:gsub('- %b[]', '- [ ]')
    vim.api.nvim_set_current_line(new_line)
  end
end, { desc = 'Toggle TODO' })

vim.b.undo_ftplugin = (vim.b.undo_ftplugin or '')
  .. '\n '
  .. 'setlocal tabstop< softtabstop< shiftwidth< expandtab< textwidth< colorcolumn< wrap< wrapmargin< linebreak< spell< spelllang< '
  .. ' | sil! nunmap <buffer> gO'
  .. ' | sil! nunmap <buffer> <leader>mt'
  .. ' | sil! nunmap <buffer> gl'
  .. ' | sil! vunmap <buffer> gl'
  .. ' | sil! nunmap <buffer> <leader>x'
