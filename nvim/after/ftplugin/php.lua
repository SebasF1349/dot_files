-- FIX: this seems to not be working: https://github.com/neovim/neovim/blob/master/runtime/ftplugin/php.vim#L76C7-L76C20
-- try this? https://github.com/neovim/neovim/blob/master/runtime/ftplugin/lua.vim
-- Tools to try:
--- pest (only for 7.3+)
--- phpmd (too harsh - for example all elses are errors)
--- rector (to update php)
--- php-cs-fixer or phpcbf (formatting - if it's even introduced at work)

local separator = require('utils.os').dir_separator

vim.bo.commentstring = '// %s'
vim.cmd('setlocal iskeyword-=-')

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
end, { desc = 'PHP Block Text-Object', silent = true, buffer = 0 })
vim.keymap.set({ 'x', 'o' }, 'a=', function()
  phpTextObject('a')
end, { desc = 'PHP Block Text-Object', silent = true, buffer = 0 })

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
    ${0},
}]],
  this = [[\$this->$0;]],
  p = [[var_dump($0);]],
  pe = [[echo '<pre>'; var_export($0); echo '</pre>';exit;]],
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

vim.keymap.set('n', 'L', 'f$l', { desc = 'Next variable', buffer = 0 })
vim.keymap.set('n', 'H', 'F$l', { desc = 'Previous variable', buffer = 0 })

local function find_dir_space(fpath)
  for _, dir in ipairs({ 'frontend', 'backend', 'common' }) do
    if fpath:find(dir) then
      return dir
    end
  end
end

-- YII2 keymaps
vim.keymap.set('n', 'gf', function()
  local fpath = vim.fn.expand('%:.')
  local cfile = vim.fn.expand('<cfile>')
  if fpath:find('controllers') and not cfile:find('/') then
    local dirspace = find_dir_space(fpath) and find_dir_space(fpath) .. '/' or ''
    local controller = fpath:match(separator .. '(%a*)Controller.php')
    controller = controller:gsub('%u', function(c)
      return '-' .. c:lower()
    end)
    local vname = dirspace .. 'views/' .. controller:sub(2) .. '/' .. cfile .. '.php'
    if vim.fn.filereadable(vname) == 1 then
      vim.cmd('edit ' .. vname)
    else
      vim.notify('View "' .. vname .. '" not found', vim.log.levels.INFO)
    end
  elseif vim.startswith(cfile, separator) then
    local dirspace = find_dir_space(fpath) and find_dir_space(fpath) .. '/' or ''
    local vname = dirspace .. 'views/' .. cfile:sub(2) .. '.php'
    if vim.fn.filereadable(vname) == 1 then
      vim.cmd('edit ' .. vname)
    else
      vim.notify('View "' .. vname .. '" not found', vim.log.levels.INFO)
    end
  else
    vim.api.nvim_feedkeys('gf', 'n', true)
  end
end, { desc = 'Improved gf to move to views', buffer = 0 })

vim.keymap.set('n', '<leader>aa', function()
  local cfile = vim.fn.expand('<cfile>')
  local split = {}
  for str in string.gmatch(cfile, '([^/]+)') do
    table.insert(split, str)
  end

  local fpath = vim.fn.expand('%:.')
  local dirspace = find_dir_space(fpath) and find_dir_space(fpath) .. '/' or ''
  local cname = dirspace .. 'controllers/' .. split[1]:sub(1, 1):upper() .. split[1]:sub(2) .. 'Controller.php'
  if vim.fn.filereadable(cname) == 0 then
    vim.notify('Controller "' .. cname .. '" not found', vim.log.levels.INFO)
    return
  end
  vim.cmd('edit ' .. cname)

  local action = split[2]:gsub('-.', function(c)
    return c:sub(2, 2):upper()
  end)
  action = 'action' .. action:sub(1, 1):upper() .. action:sub(2)
  local linenr = vim.fn.search(action, 'nw')
  if linenr == 0 then
    vim.notify('Action "' .. action .. '" not found', vim.log.levels.INFO)
    return
  end
  vim.api.nvim_win_set_cursor(0, { linenr, 0 })
end, { desc = '[A]lternative: [A]ction', buffer = 0 })

vim.keymap.set('n', '<leader>ac', function()
  local fpath = vim.fn.expand('%:.')
  local dirspace = find_dir_space(fpath) and find_dir_space(fpath) .. separator or ''
  local controller, fname = fpath:match('views' .. separator .. '(.*)' .. separator .. '(.*).php')
  controller = controller:gsub('-.', function(c)
    return c:sub(2, 2):upper()
  end)
  local cpath = dirspace .. 'controllers/' .. controller:sub(1, 1):upper() .. controller:sub(2) .. 'Controller.php'
  if vim.fn.filereadable(cpath) == 1 then
    vim.fn.setreg('f', fname, 'v')
    vim.cmd('edit ' .. cpath)
  else
    vim.notify('Controller "' .. cpath .. '" not found', vim.log.levels.INFO)
  end
end, { desc = '[A]lternative: [C]ontroller', buffer = 0 })

vim.b.undo_ftplugin = (vim.b.undo_ftplugin or '')
  .. '\n '
  .. 'unlet! b:friendlyManual b:surroundPair b:contextStatus'
  .. ' | setlocal commentstring< iskeyword< '
  .. ' | sil! nunmap <buffer> gf'
  .. ' | sil! nunmap <buffer> <leader>aa'
  .. ' | sil! nunmap <buffer> <leader>ac'
  .. ' | sil! vunmap <buffer> i='
  .. ' | sil! ounmap <buffer> i='
  .. ' | sil! vunmap <buffer> a='
  .. ' | sil! ounmap <buffer> a='
  .. ' | sil! nunmap <buffer> L'
  .. ' | sil! nunmap <buffer> H'
