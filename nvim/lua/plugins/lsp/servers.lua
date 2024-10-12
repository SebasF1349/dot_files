local M = {}

local function organize_imports()
  local params = {
    command = '_typescript.organizeImports',
    arguments = { vim.api.nvim_buf_get_name(0) },
  }
  vim.lsp.buf.execute_command(params)
end

M = {
  rust_analyzer = {
    settings = {
      ['rust_analyzer'] = {
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
        command = {
          'cargo',
          'clippy',
        },
        checkOnSave = {
          command = 'clippy',
        },
      },
    },
  },

  ts_ls = {
    settings = {
      typescript = {
        inlayHints = {
          includeInlayParameterNameHints = 'all',
          includeInlayParameterNameHintsWhenArgumentMatchesName = true,
          includeInlayFunctionParameterTypeHints = true,
          includeInlayVariableTypeHints = true,
          includeInlayPropertyDeclarationTypeHints = true,
          includeInlayFunctionLikeReturnTypeHints = true,
          includeInlayEnumMemberValueHints = true,
        },
      },
      javascript = {
        inlayHints = {
          includeInlayParameterNameHints = 'all',
          includeInlayParameterNameHintsWhenArgumentMatchesName = true,
          includeInlayFunctionParameterTypeHints = true,
          includeInlayVariableTypeHints = true,
          includeInlayPropertyDeclarationTypeHints = true,
          includeInlayFunctionLikeReturnTypeHints = true,
          includeInlayEnumMemberValueHints = true,
        },
      },
    },
    commands = {
      OrganizeImports = {
        organize_imports,
        description = 'Organize Imports',
      },
    },
  },

  html = {
    filetypes = { 'html', 'twig', 'hbs' },
    settings = {
      opts = {
        settings = {
          html = {
            format = {
              templating = true,
              wrapLineLength = 120,
              wrapAttributes = 'auto',
            },
            hover = {
              documentation = true,
              references = true,
            },
          },
        },
      },
    },
  },

  lua_ls = {
    on_init = function(client)
      local path = client.workspace_folders[1].name
      if vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc') then
        return
      end

      client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
        runtime = { version = 'LuaJIT' },
        -- Make the server aware of Neovim runtime files
        workspace = {
          checkThirdParty = false,
          library = {
            '${3rd}/luv/library',
            vim.env.VIMRUNTIME, -- this apparently gives faster and better diagnostics than `unpack`
            -- unpack(vim.api.nvim_get_runtime_file("", true)),
          },
        },
      })
    end,
    settings = {
      Lua = {
        format = { enable = false },
        completion = { callSnippet = 'Replace' },
        hint = { enable = true, arrayIndex = 'Disable' },
        telemetry = { enable = false },
      },
    },
  },

  svelte = {},

  cssls = {},

  tailwindcss = {
    filetypes = {
      'astro',
      'astro-markdown',
      'ejs',
      'html',
      'css',
      'less',
      'postcss',
      'sass',
      'scss',
      'javascript',
      'javascriptreact',
      'typescript',
      'typescriptreact',
      'vue',
      'svelte',
    },
    hovers = true,
    suggestions = true,
    root_dir = function(fname)
      local root_pattern = require('lspconfig').util.root_pattern(
        'tailwind.config.cjs',
        'tailwind.config.js',
        'tailwind.config.ts',
        'postcss.config.js'
      )
      return root_pattern(fname)
    end,
  },

  emmet_language_server = {
    settings = {
      filetypes = { 'html', 'typescriptreact', 'javascriptreact', 'css', 'sass', 'scss', 'less', 'svelte' },
    },
  },

  bashls = {},

  jdtls = {},

  marksman = {},

  --work
  phpactor = {},
}

return M
