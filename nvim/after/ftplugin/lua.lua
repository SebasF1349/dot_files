local snip = require('utils.snippets')

vim.b.contextStatus = { 'function_declaration' }

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
  .. ' | setlocal keywordprg< omnifunc<'
