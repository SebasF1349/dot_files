return {
  cmd = { 'emmet-language-server', '--stdio' },
  filetypes = {
    'css',
    'html',
    'scss',
    'svelte',
    'php',
  },
  root_markers = { '.git' },
  init_options = {
    includeLanguages = {
      php = 'html',
    },
    showAbbreviationSuggestions = true,
    showExpandedAbbreviation = 'always',
    showSuggestionsAsSnippets = true,
  },
}
