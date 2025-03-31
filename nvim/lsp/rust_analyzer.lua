return {
  cmd = { 'rust-analyzer' },
  filetypes = { 'rust' },
  single_file_support = true,
  root_markers = { 'Cargo.toml' },
  capabilities = {
    experimental = {
      serverStatusNotification = true,
    },
  },
  before_init = function(init_params, config)
    -- See https://github.com/rust-lang/rust-analyzer/blob/eb5da56d839ae0a9e9f50774fa3eb78eb0964550/docs/dev/lsp-extensions.md?plain=1#L26
    if config.settings and config.settings['rust-analyzer'] then
      init_params.initializationOptions = config.settings['rust-analyzer']
    end
  end,
  settings = {
    autoformat = true,
    ['rust-analyzer'] = {
      diagnostics = {
        enable = true,
      },
      inlayHints = {
        enable = true,
        showParameterNames = true,
        parameterHintsPrefix = '<- ',
        otherHintsPrefix = '=> ',
      },
      imports = {
        granularity = {
          group = 'module',
        },
        prefix = 'self',
      },
      cargo = {
        features = { 'all' }, -- does it do something?
        allFeatures = true,
        buildScripts = {
          enable = true,
        },
      },
      procMacro = {
        enable = true,
        ignored = {
          ['async-trait'] = { 'async_trait' },
          ['napi-derive'] = { 'napi' },
          ['async-recursion'] = { 'async_recursion' },
        },
      },
      check = {
        command = { 'cargo', 'clippy' },
      },
      checkOnSave = {
        command = 'clippy',
      },
    },
  },
}
