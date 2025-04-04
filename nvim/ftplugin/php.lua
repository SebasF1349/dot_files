-- FIX: this seems to not be working: https://github.com/neovim/neovim/blob/master/runtime/ftplugin/php.vim#L76C7-L76C20
-- try this? https://github.com/neovim/neovim/blob/master/runtime/ftplugin/lua.vim

vim.b.friendlyManual = 'http://php.net/manual-lookup.php?pattern=%s'

vim.b.contextStatus = { 'method_declaration', 'class_declaration', 'function_declaration', 'function_definition' }

vim.b.surroundPair = {
  ['-'] = { { '<?php ' }, { ' ?>' } },
  ['_'] = { { '<?php', '' }, { '', '?>' } },
  ['='] = { { '<?= ' }, { ' ?>' } },
  ['+'] = { { '<?=', '' }, { '', '?>' } },
  ['p'] = { { 'var_dump(' }, { ');exit;' } },
}

--- Text-object for php blocks (<?= and <?php)
---@param type 'a' | 'i'
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
  -- <?php blocks may have no ending if it ends at the end of the file
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

local snippets = {
  fn = [[${1:public} function ${2:FunctionName}(${3:})
{
    ${0}
}]],
  ['if'] = [[if (${1:condition}) {
    ${0}
}]],
  ife = [[if (${1:condition}) {
    ${2}
} else {
    ${0}
}]],
  ['if?'] = [[${1} ? ${3:a} : ${4:b} ;]],
  ['else'] = [[else {
    ${0}
}]],
  ['elseif'] = [[elseif (${1}) {
    ${0}
}]],
  fore = [[foreach (\$${1:variable} as \$${2:key} ${3:key => value}) {
    "${0}",
}]],
  this = [[\$this->$0;]],
  p = [[var_dump($0);]],
  pe = [[var_dump($0);exit();]],
  ['-'] = [[<?php ${0} ?>]],
  ['_'] = [[<?php
    ${0}
?>]],
  ['='] = [[<?= ${0} ?>]],
  ['+'] = [[<?=
    ${0}
?>]],
}

-- NOTE: snippets are not added to the undo (maybe :una ?)
for key, snippet in pairs(snippets) do
  _G.addSnippet(key, snippet)
end

vim.keymap.set('n', 'L', 'f$', { desc = 'Next variable' })
vim.keymap.set('n', 'H', 'F$', { desc = 'Previous variable' })

vim.b.undo_ftplugin = (vim.b.undo_ftplugin or '')
  .. '\n '
  .. 'unlet! b:friendlyManual b:surroundPair b:contextStatus'
  .. ' | sil! vunmap <buffer> i='
  .. ' | sil! ounmap <buffer> i='
  .. ' | sil! vunmap <buffer> a='
  .. ' | sil! ounmap <buffer> a='
  .. ' | sil! nunmap <buffer> L'
  .. ' | sil! nunmap <buffer> H'
