local lastRootPath = nil
local gomodpath = vim.trim(vim.fn.system('go env GOPATH')) .. '/pkg/mod'

return {
  cmd = { 'gopls' },
  filetypes = { 'go', 'gomod', 'gowork', 'gotmpl' },
  root_dir = function(bufnr, cb)
    -- see: https://github.com/neovim/nvim-lspconfig/issues/804
    local path
    local fullpath = vim.api.nvim_buf_get_name(bufnr)
    local root = vim.fs.root(0, { 'go.work', 'go.mod', '.git' })
    if string.find(fullpath, gomodpath) and lastRootPath ~= nil then
      path = lastRootPath
    elseif lastRootPath and fullpath:sub(1, #lastRootPath) == lastRootPath then
      local clients = vim.lsp.get_clients({ name = 'gopls' })
      if #clients > 0 then
        path = clients[#clients].config.root_dir
      end
    elseif root ~= nil then
      lastRootPath = root
      path = root
    end
    cb(path)
  end,
  single_file_support = true,
  settings = {
    gopls = {
      gofumpt = true,
      codelenses = {
        gc_details = false,
        generate = true,
        regenerate_cgo = true,
        run_govulncheck = true,
        test = true,
        tidy = true,
        upgrade_dependency = true,
        vendor = true,
      },
      hints = {
        assignVariableTypes = true,
        compositeLiteralFields = true,
        compositeLiteralTypes = true,
        constantValues = true,
        functionTypeParameters = true,
        parameterNames = true,
        rangeVariableTypes = true,
      },
      -- analyses = {
      --   fieldalignment = true,
      --   nilness = true,
      --   unusedparams = true,
      --   unusedwrite = true,
      --   useany = true,
      -- },
      usePlaceholders = true,
      completeUnimported = true,
      staticcheck = true,
      directoryFilters = { '-.git', '-.vscode', '-.idea', '-.vscode-test', '-node_modules' },
      semanticTokens = true,
    },
  },
}
