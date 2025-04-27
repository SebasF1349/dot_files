vim.b.contextStatus = { 'function_declaration' }

vim.bo.keywordprg = ':help'
vim.bo.omnifunc = 'v:lua.vim.lua_omnifunc'

local snippets = {
  fn = [[local function ${1:FunctionName}(${2:})
{
    ${0}
}]],
  p = [[vim.print($0);]],
}

for key, snippet in pairs(snippets) do
  _G.addSnippet(key, snippet)
end

vim.b.undo_ftplugin = (vim.b.undo_ftplugin or '')
  .. '\n '
  .. 'unlet! b:contextStatus'
  .. ' | setlocal keywordprg< omnifunc<'
