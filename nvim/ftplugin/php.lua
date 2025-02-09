vim.b.friendlyManual = 'http://php.net/manual-lookup.php?pattern=%s'

vim.b.surroundPair = {
  ['-'] = { '<?php ', ' ?>' },
  ['='] = { '<?= ', ' ?>' },
}

local function phpTextObject(type)
  local curr = vim.api.nvim_win_get_cursor(0)
  local o = vim.fn.search('<?', 'bWc')
  if o == 0 then
    return
  end
  local opening = vim.api.nvim_win_get_cursor(0)
  local e = vim.fn.search('?>', 'eWc')
  local _end = vim.api.nvim_win_get_cursor(0)
  if e ~= 0 and (_end[1] < curr[1] or (_end[1] == curr[1] and _end[2] < curr[2])) then
    vim.api.nvim_win_set_cursor(0, curr)
    return
  end
  if e == 0 then
    local last_line = vim.fn.getpos('$')[2]
    local last_col = vim.fn.col({ last_line, '$' })
    _end = { last_line, last_col }
  end

  vim.api.nvim_win_set_cursor(0, opening)
  if type == 'i' then
    vim.cmd.normal({ 'E', bang = true })
    vim.fn.search('\\_.')
  end
  if vim.api.nvim_get_mode().mode:find('v') then
    vim.cmd.normal({ 'o', bang = true })
  else
    vim.cmd.normal({ 'v', bang = true })
  end
  vim.api.nvim_win_set_cursor(0, _end)
  if type == 'i' and e ~= 0 then
    vim.cmd.normal({ 'B', bang = true })
    vim.fn.search('\\_.', 'b')
  end
end

vim.keymap.set({ 'x', 'o' }, 'i=', function()
  phpTextObject('i')
end, { desc = 'PHP Block Text-Object', silent = true })
vim.keymap.set({ 'x', 'o' }, 'a=', function()
  phpTextObject('a')
end, { desc = 'PHP Block Text-Object', silent = true })

vim.b.undo_ftplugin = (vim.b.undo_ftplugin or '')
  .. '\n '
  .. 'unlet! b:friendlyManual b:surroundPair'
  .. ' | sil! vunmap <buffer> i='
  .. ' | sil! ounmap <buffer> i='
  .. ' | sil! vunmap <buffer> a='
  .. ' | sil! ounmap <buffer> a='
