return {
  cmd = { 'intelephense', '--stdio' },
  filetypes = { 'php' },
  root_markers = { 'composer.root', 'composer.json', '.git' },
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
