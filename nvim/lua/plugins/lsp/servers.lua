local util = require('lspconfig.util')
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

  gopls = {
    capabilities = {
      textDocument = {
        completion = {
          completionItem = {
            commitCharactersSupport = true,
            deprecatedSupport = true,
            documentationFormat = { 'markdown', 'plaintext' },
            preselectSupport = true,
            insertReplaceSupport = true,
            labelDetailsSupport = true,
            snippetSupport = true,
            resolveSupport = {
              properties = {
                'documentation',
                'details',
                'additionalTextEdits',
              },
            },
          },
          contextSupport = true,
          dynamicRegistration = true,
        },
      },
    },
    filetypes = { 'go', 'gomod', 'gosum', 'gotmpl', 'gohtmltmpl', 'gotexttmpl' },
    message_level = vim.lsp.protocol.MessageType.Error,
    cmd = {
      'gopls', -- share the gopls instance if there is one already
      '-remote.debug=:0',
    },
    root_dir = function(fname)
      local has_lsp, lspconfig = pcall(require, 'lspconfig')
      if has_lsp then
        local util = lspconfig.util
        return util.root_pattern('go.work', 'go.mod')(fname)
          or util.root_pattern('.git')(fname)
          or util.path.dirname(fname)
      end
    end,
    flags = { allow_incremental_sync = true, debounce_text_changes = 500 },
    settings = {
      gopls = {
        -- more settings: https://github.com/golang/tools/blob/master/gopls/doc/settings.md
        -- not supported
        analyses = {
          unreachable = true,
          nilness = true,
          unusedparams = true,
          useany = true,
          unusedwrite = true,
          ST1003 = true,
          undeclaredname = true,
          fillreturns = true,
          nonewvars = true,
          fieldalignment = false,
          shadow = true,
        },
        codelenses = {
          generate = true, -- show the `go generate` lens.
          gc_details = true, -- Show a code lens toggling the display of gc's choices.
          test = true,
          tidy = true,
          vendor = true,
          regenerate_cgo = true,
          upgrade_dependency = true,
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
        usePlaceholders = true,
        completeUnimported = true,
        staticcheck = true,
        matcher = 'Fuzzy',
        diagnosticsDelay = '500ms',
        symbolMatcher = 'fuzzy',
        semanticTokens = true,
        noSemanticTokens = true, -- disable semantic string tokens so we can use treesitter highlight injection

        -- ['local'] = get_current_gomod(),
        gofumpt = true, -- _GO_NVIM_CFG.lsp_gofumpt or false, -- true|false, -- turn on for new repos, gofmpt is good but also create code turmoils
        buildFlags = { '-tags', 'integration' },
      },
    },
    -- NOTE: it is important to add handler to formatting handlers
    -- the async formatter will call these handlers when gopls responed
    -- without these handlers, the file will not be saved
    handlers = {
      range_format = function(...)
        vim.lsp.handlers.range_format(...)
        if vim.fn.getbufinfo('%')[1].changed == 1 then
          vim.cmd('noautocmd write')
        end
      end,
      formatting = function(...)
        vim.lsp.handlers.formatting(...)
        if vim.fn.getbufinfo('%')[1].changed == 1 then
          vim.cmd('noautocmd write')
        end
      end,
    },
  },

  --work
  intelephense = {
    root_dir = function(pattern)
      local cwd = vim.loop.cwd()
      local root = util.root_pattern('composer.root', 'composer.json', '.git')(pattern)
      return util.path.is_descendant(root, cwd) and root or cwd
    end,
    settings = {
      intelephense = {
        format = {
          enable = (vim.loop.cwd():find('telesalud') or vim.loop.cwd():find('xampp_plataforma') or vim.loop.cwd():find('pasantia')) ~= nil,
        },
      },
    },
  },
}

return M
