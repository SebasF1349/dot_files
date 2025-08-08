-- FIX: this seems to not be working: https://github.com/neovim/neovim/blob/master/runtime/ftplugin/php.vim#L76C7-L76C20
-- try this? https://github.com/neovim/neovim/blob/master/runtime/ftplugin/lua.vim
-- Tools to try:
--- pest (only for 7.3+)
--- phpmd (too harsh - for example all elses are errors)
--- rector (to update php)
--- php-cs-fixer or phpcbf (formatting - if it's even introduced at work)

local separator = require('utils.os').dir_separator
local snip = require('utils.snippets')

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
  snip.addSnippet(key, snippet)
end

local function is_inside_php_block(cursor_pos)
  local found_start = vim.fn.search('<?php\\|\\(<?=\\)', 'bcW')
  local start_pos = vim.api.nvim_win_get_cursor(0)
  local found_end = vim.fn.search('?>', 'ceW')
  local end_pos = vim.api.nvim_win_get_cursor(0)
  vim.api.nvim_win_set_cursor(0, cursor_pos)

  if found_start == 0 or found_end == 0 then
    return false
  end

  return (cursor_pos[1] > start_pos[1] or (cursor_pos[1] == start_pos[1] and cursor_pos[2] >= start_pos[2]))
    and (cursor_pos[1] < end_pos[1] or (cursor_pos[1] == end_pos[1] and cursor_pos[2] <= end_pos[2]))
end

--- Text-object for php blocks (<?= and <?php)
---@param type 'a' | 'i'
local function phpTextObject(type)
  local curr = vim.api.nvim_win_get_cursor(0)
  local flag = is_inside_php_block(curr) and 'bcp' or 'cpW'
  local o = vim.fn.search('<?php\\|\\(<?=\\)', flag)
  if o == 0 then
    return
  end
  local opening = vim.api.nvim_win_get_cursor(0)
  local e = vim.fn.search('?>', 'eWc')
  local _end = vim.api.nvim_win_get_cursor(0)
  -- <?php blocks may have no ending if it ends at the end of the file
  if e == 0 then
    local last_line = vim.fn.getpos('$')[2]
    local last_col = vim.fn.col({ last_line, '$' })
    _end = { last_line, last_col }
  end

  if type == 'i' then
    local block_start = o == 1 and '<?php' or '<?='
    if opening[2] + #block_start == #vim.api.nvim_buf_get_lines(0, opening[1], opening[1] + 1, false)[1] then
      opening[1] = opening[1] + 1
      opening[2] = 1
    else
      opening[2] = opening[2] + #block_start
    end

    if _end[2] == 1 then
      _end[1] = _end[1] - 1
      _end[2] = #vim.api.nvim_buf_get_lines(0, _end[1] - 1, _end[1], false)[1]
    else
      _end[2] = _end[2] - 2
    end
  end

  vim.api.nvim_win_set_cursor(0, opening)
  if vim.api.nvim_get_mode().mode:find('v') then
    vim.cmd.normal({ 'o', bang = true })
  else
    vim.cmd.normal({ 'v', bang = true })
  end
  vim.api.nvim_win_set_cursor(0, _end)
end

vim.keymap.set({ 'x', 'o' }, 'i=', function()
  phpTextObject('i')
end, { desc = 'PHP Block Text-Object', silent = true, buffer = 0 })
vim.keymap.set({ 'x', 'o' }, 'a=', function()
  phpTextObject('a')
end, { desc = 'PHP Block Text-Object', silent = true, buffer = 0 })

vim.keymap.set('n', 'L', 'f$l', { desc = 'Next variable', buffer = 0 })
vim.keymap.set('n', 'H', 'F$l', { desc = 'Previous variable', buffer = 0 })

-- YII2 keymaps
local function PascalToKebab(pascal)
  local res = pascal:gsub('%u', function(c)
    return '-' .. c:lower()
  end)
  return res:gsub('^%-', '')
end

local function kebab_to_pascal(kebab)
  return (kebab
    :gsub('(%-)(%a)', function(_, c)
      return c:upper()
    end)
    :gsub('^%l', string.upper))
end

local File = {}
File.__index = File

function File:new()
  File.__base_dir = (vim.fs.root(0, 'controllers'):gsub('[/\\]', separator) .. separator) or ''

  local fpath = vim.fn.expand('%:.')
  if fpath:find('controllers') then
    File.__type = 'controller'
    local controller = fpath:match(separator .. '(%a*)Controller.php')
    File.__controller = PascalToKebab(controller)
  elseif fpath:find('views') then
    File.__type = 'view'
    local escaped_view_path = (File.__base_dir .. 'views' .. separator):gsub('([^%w])', '%%%1')
    local controller = (vim.fn.expand('%:p:h')):gsub(escaped_view_path, '')
    File.__controller = kebab_to_pascal(controller)
  end

  File.__controller = File.__controller:gsub('[/\\]', separator)

  return self
end
function File:getBaseDir()
  return self.__base_dir
end
function File:getType()
  return self.__type
end
function File:getController()
  return self.__controller
end
function File:getControllerPath(controller)
  return ('%scontrollers%s%sController.php'):format(self.__base_dir, separator, kebab_to_pascal(controller))
end
function File:getViewPath(controller, file)
  return ('%sviews%s%s%s%s.php'):format(self.__base_dir, separator, controller, separator, file)
end


vim.keymap.set('n', 'gf', function()
  local fileObj = File:new()
  local target, action, action2, method, arg
  if fileObj:getType() == 'controller' then
    local line = vim.api.nvim_get_current_line()
    method, arg = line:match("%$this%->(render)%(%s*['\"]([^']+)['\"]")
    if not method then
      method, arg = line:match("%$this%->(redirect)%(%s*['\"]([^']+)['\"]")
      if not method then
        arg = vim.fn.expand('<cfile>')
      end
    end
    if not arg then
      return
    end

    local controller, file = arg:match('^([^/]+)/(.+)$')
    if not controller then
      controller, file = fileObj:getController(), arg
    end

    if method == 'render' then
      target = fileObj:getViewPath(controller, file)
    elseif method == 'redirect' or not method then
      target = fileObj:getControllerPath(controller)
      action = 'action' .. kebab_to_pascal(file)
    end
  elseif fileObj:getType() == 'view' then
    local cfile = vim.fn.expand('<cfile>')
    local controller, file = cfile:match('([^/]+)/([^/]+)')
    if not controller then
      controller, file = fileObj:getController(), cfile
    end
    controller = controller or fileObj:getController()
    target = fileObj:getControllerPath(controller)
    action = 'action' .. kebab_to_pascal(file)
    action2 = 'action' .. kebab_to_pascal(vim.fn.expand('%:t:r'))
  end

  if vim.fn.filereadable(target) ~= 1 then
    vim.notify('"' .. target .. '" not found', vim.log.levels.INFO)
    return
  end

  vim.cmd('edit ' .. target)
  if action then
    local linenr = vim.fn.search('\\<' .. action .. '\\>', 'nw')
    if action2 and linenr == 0 then
        linenr = vim.fn.search('\\<' .. action2 .. '\\>', 'nw')
    end
    if linenr == 0 then
      vim.notify('Action "' .. action .. '" not found', vim.log.levels.INFO)
      return
    end
    vim.api.nvim_win_set_cursor(0, { linenr, 0 })
  end
end, { desc = 'Improved gf for Yii2', buffer = 0 })

vim.b.undo_ftplugin = (vim.b.undo_ftplugin or '')
  .. '\n '
  .. 'unlet! b:friendlyManual b:surroundPair b:contextStatus'
  .. ' | setlocal commentstring< iskeyword< '
  .. ' | sil! nunmap <buffer> gf'
  .. ' | sil! vunmap <buffer> i='
  .. ' | sil! ounmap <buffer> i='
  .. ' | sil! vunmap <buffer> a='
  .. ' | sil! ounmap <buffer> a='
  .. ' | sil! nunmap <buffer> L'
  .. ' | sil! nunmap <buffer> H'
