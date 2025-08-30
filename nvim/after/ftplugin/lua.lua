local snip = require('utils.snippets')

vim.bo.tabstop = 2
vim.bo.softtabstop = 2
vim.bo.shiftwidth = 2

vim.b.contextStatus = { function_declaration = 'name' }

local snippets = {
  fn = [[local function ${1:FunctionName}(${2:})
{
  ${0}
}]],
  p = [[vim.print($0);]],
}

for key, snippet in pairs(snippets) do
  snip.addSnippet(key, snippet)
end


vim.b.undo_ftplugin = (vim.b.undo_ftplugin or '')
  .. '\n '
  .. 'unlet! b:contextStatus'
  .. ' | setlocal tabstop< softtabstop< shiftwidth< '
