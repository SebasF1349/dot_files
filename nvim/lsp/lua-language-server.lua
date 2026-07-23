return {
  cmd = { 'lua-language-server' },
  filetypes = { 'lua' },
  root_markers = {
    '.luarc.json',
    '.luarc.jsonc',
    '.luacheckrc',
    '.stylua.toml',
    'stylua.toml',
    '.git',
  },
  log_level = vim.lsp.protocol.MessageType.Warning,
  settings = {
    Lua = {
      codeLens = { enable = true },
      format = { enable = false },
      completion = { callSnippet = 'Replace' },
      hint = { enable = true, arrayIndex = 'Disable' },
      telemetry = { enable = false },
      diagnostics = {
        enable = true,
        neededFileStatus = {
          ['type-check'] = 'Any',
          ['strict-type-check'] = 'Any',
        },
        groupSeverity = {
          strong = 'Warning',
          strict = 'Warning',
        },
        unusedLocalExclude = { '_*' },
      },
    },
  },
}
