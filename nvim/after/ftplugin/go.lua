local snip = require('utils.snippets')

vim.b.contextStatus = { function_declaration = 'name', method_declaration = 'name' }

local snippets = {
  e = [[if err != nil {
    ${0}
}]],
}

for key, snippet in pairs(snippets) do
  snip.addSnippet(key, snippet)
end

vim.b.undo_ftplugin = (vim.b.undo_ftplugin or '')
  .. '\n '
  .. 'unlet! b:contextStatus'
