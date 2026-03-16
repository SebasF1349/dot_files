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

vim.b.contextStatus = { method_declaration = 'name', class_declaration = 'name', function_definition = 'name' }

vim.b.surroundPair = {
  ['-'] = { { '<?php ' }, { ' ?>' } },
  ['_'] = { { '<?php', '' }, { '', '?>' } },
  ['='] = { { '<?= ' }, { ' ?>' } },
  ['+'] = { { '<?=', '' }, { '', '?>' } },
  ['p'] = { { 'var_dump(' }, { ');exit;' } },
}

vim.b.runners = {
  ['8.4'] = 'php8.4',
  ['7.0'] = 'php7.0',
  default = 'php',
  prefix = '<?php',
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

--- Text-object for php blocks (<?= and <?php)
-- NOTE: it doesn't handle blocks at the end of the file
---@param type 'a' | 'i'
local function phpTextObject(type)
  local curr = vim.api.nvim_win_get_cursor(0)

  ---@type [integer,integer]
  local _end = vim.fn.searchpos('?>', 'eWc')
  if _end[1] == 0 and _end[2] == 0 then
    vim.api.nvim_win_set_cursor(0, curr)
    return
  end

  ---@type [integer,integer,integer]
  local opening = vim.fn.searchpos('\\(<?php\\)\\|\\(<?=\\)', 'bcp')
  if opening[1] == 0 and opening[2] == 0 then
    vim.api.nvim_win_set_cursor(0, curr)
    return
  end

  -- normalization
  opening[2] = opening[2] - 1
  _end[2] = _end[2] - 1

  if type == 'i' then
    local block_start = opening[3] == 2 and '<?php' or '<?='
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

  vim.api.nvim_win_set_cursor(0, { opening[1], opening[2] })
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
  local root = vim.fs.root(0, 'controllers')
  if not root then
    return
  end
  File.__base_dir = (root:gsub('[/\\]', separator) .. separator) or ''

  ---@type string
  local fpath = vim.fn.expand('%:.')
  if string.find(fpath, 'controllers') then
    File.__type = 'controller'
    local controller = fpath:match('[\\/](%a*)Controller.php')
    File.__controller = PascalToKebab(controller)
  elseif fpath:find('views') then
    File.__type = 'view'
    local controller = vim.fn.expand('%:p:h'):match('([^\\/]+)$')
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

local function contains_return(list, candidate)
  for _, v in ipairs(list) do
    if v.args == candidate.args and v.method == candidate.method then
      return true
    end
  end
  return false
end

local function get_returns()
  local bufnr = vim.api.nvim_get_current_buf()
  local curr_line = vim.api.nvim_win_get_cursor(0)
  local method_node = vim.treesitter.get_node({ pos = { curr_line[1] - 1, 0 } })
  while method_node and method_node:type() ~= 'method_declaration' do
    method_node = method_node:parent()
  end
  if not method_node then
    return
  end

  local q = [[
(
  return_statement
    (member_call_expression
      object: (variable_name) @obj
        (#eq? @obj "$this")
      name: (name) @method
        (#any-of? @method "redirect" "render")
      arguments: (arguments
        (argument)) @args
    ) @call
)
]]
  local query = vim.treesitter.query.parse('php', q)
  local str_query = vim.treesitter.query.parse('php', '(string_content) @str_content')
  local return_nodes = {}
  for _, match, _ in query:iter_matches(method_node, bufnr) do
    local rn = {}
    for id, n in ipairs(match) do
      local name = query.captures[id]
      local text = ''
      local node = n[1]
      if name == 'args' then
        local arg_node = nil
        for i = 0, node:child_count() - 1 do
          local child = node:child(i)
          if child and child:type() == 'argument' then
            arg_node = child
            break
          end
        end
        if arg_node then
          for _, argn in str_query:iter_captures(arg_node, bufnr) do
            text = vim.treesitter.get_node_text(argn, bufnr)
            break
          end
          if text == '' then
            text = vim.treesitter.get_node_text(arg_node, bufnr)
          end
        end
      else
        text = vim.treesitter.get_node_text(node, bufnr)
      end
      rn[name] = text
    end
    if next(match) ~= nil and not contains_return(return_nodes, rn) then
      table.insert(return_nodes, rn)
    end
  end
  return return_nodes
end

---@param target string
---@param action? string
---@param action2? string
local function move(target, action, action2)
  if vim.fn.filereadable(target) ~= 1 then
    vim.notify('"' .. target .. '" not found', vim.log.levels.INFO)
    return
  end

  vim.cmd('edit ' .. target)
  if not action then
    return
  end

  action2 = action2 or ''
  local action_query = string.format(
    [[
(
method_declaration
  (visibility_modifier)?
  name: (name) @method_name
    (#any-of? @method_name %s %s)
)
]],
    action,
    action2
  )

  local parser = vim.treesitter.get_parser(0, 'php')
  if not parser then
    return
  end
  local tree = parser:parse()[1]
  local root = tree:root()
  local query = vim.treesitter.query.parse('php', action_query)
  for _, match, _ in query:iter_matches(root, 0) do
    if match[1] then
      local method_node = match[1][1]
      local start_row, start_col = method_node:range()
      local bufnr = vim.api.nvim_get_current_buf()
      local text = vim.treesitter.get_node_text(method_node, bufnr)
      if text == action or text == action2 then
        vim.api.nvim_win_set_cursor(0, { start_row + 1, start_col })
        return
      end
    end
  end
  vim.notify('Action "' .. action .. '" not found', vim.log.levels.INFO)
end

vim.keymap.set('n', 'gf', function()
  local fileObj = File:new()
  if not fileObj then
    vim.notify('Controller directory not found', vim.log.levels.INFO)
    return
  end
  local target, action, action2, method
  if fileObj:getType() == 'controller' then
    local returns = get_returns()
    if not returns or #returns == 0 then
      vim.notify('No target to jump to', vim.log.levels.INFO)
      return
    end
    vim.ui.select(returns, {
      prompt = 'Returns: ',
      format_item = function(item)
        return ('%s -> %s'):format(item.method, item.args)
      end,
    }, function(choice)
      if not choice then
        return
      end
      local controller, file = choice.args:match('^([^/\\]+)[/\\](.+)$')
      if not controller then
        controller, file = fileObj:getController(), choice.args
      end

      if choice.method == 'render' then
        target = fileObj:getViewPath(controller, file)
      elseif choice.method == 'redirect' or not method then
        target = fileObj:getControllerPath(controller)
        action = 'action' .. kebab_to_pascal(file)
      end
      if target then
        move(target, action)
      end
    end)
  elseif fileObj:getType() == 'view' then
    local cfile = vim.fn.expand('<cfile>')
    local controller, file = cfile:match('([^/\\]+)[/\\]([^/\\]+)')
    if not controller then
      controller, file = fileObj:getController(), cfile:gsub('[^%w]', '')
    end
    target = fileObj:getControllerPath(controller)
    action = 'action' .. kebab_to_pascal(file)
    action2 = 'action' .. kebab_to_pascal(vim.fn.expand('%:t:r'))
    move(target, action, action2)
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
