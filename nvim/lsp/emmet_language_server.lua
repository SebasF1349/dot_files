return {
  cmd = { 'emmet-language-server', '--stdio' },
  filetypes = {
    'css',
    'eruby',
    'html',
    'htmldjango',
    'javascriptreact',
    'less',
    'pug',
    'sass',
    'scss',
    'typescriptreact',
    'htmlangular',
    'svelte',
    'php',
  },
  root_dir = function(fname)
    return vim.fs.dirname(vim.fs.find('.git', { path = fname, upward = true })[1])
  end,
  single_file_support = true,
  init_options = {
    includeLanguages = {
      php = 'html',
    },
    showAbbreviationSuggestions = true,
    showExpandedAbbreviation = 'always',
    showSuggestionsAsSnippets = true,
  },
}
