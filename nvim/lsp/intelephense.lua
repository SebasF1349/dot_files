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
      format = {
        enable = (vim.uv.cwd():find('telesalud') or vim.uv.cwd():find('xampp_plataforma') or vim.uv
          .cwd()
          :find('pasantia')) ~= nil,
      },
    },
  },
}
