return {
  cmd = { 'intelephense', '--stdio' },
  filetypes = { 'php' },
  root_markers = { 'composer.root', 'composer.json', '.git' },
  commands = {
    IntelephenseIndex = {
      function()
        local clients = vim.lsp.get_clients({ name = 'intelephense' })
        clients[1]:exec_cmd({ title = 'php_index_workspace', command = 'intelephense.index.workspace' })
      end,
    },
  },
  settings = {
    intelephense = {
      environment = { phpVersion = '7.0.33' },
      telemetry = { enabled = false },
      format = {
        enable = (vim.uv.cwd():find('telesalud') or vim.uv.cwd():find('xampp_plataforma') or vim.uv
          .cwd()
          :find('pasantia')) ~= nil,
      },
      completion = {
        triggerParameterHints = true,
        insertUseDeclaration = true,
        fullyQualifyGlobalConstantsAndFunctions = true,
      },
      files = {
        maxSize = 1000000,
        exclude = {
          '**/.git/**',
          '**/.svn/**',
          '**/.hg/**',
          '**/CVS/**',
          '**/.DS_Store/**',
          '**/node_modules/**',
          '**/bower_components/**',
          '**/vendor/**/{Test,test,Tests,tests}/**',
          '**/tests/**',
          '**/cache/**',
        },
      },
      trace = { server = 'messages' },
    },
  },
}
