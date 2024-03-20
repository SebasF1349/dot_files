local servers = {
  rust_analyzer = {
    settings = {
      diagnostics = {
        enable = true,
      },
      inlayHints = {
        enable = true,
        showParameterNames = true,
        parameterHintsPrefix = "<- ",
        otherHintsPrefix = "=> ",
      },
      imports = {
        granularity = {
          group = "module",
        },
        prefix = "self",
      },
      cargo = {
        features = { "all" }, -- does it do something?
        allFeatures = true,
        buildScripts = {
          enable = true,
        },
      },
      procMacro = {
        enable = true,
        ignored = {
          ["async-trait"] = { "async_trait" },
          ["napi-derive"] = { "napi" },
          ["async-recursion"] = { "async_recursion" },
        },
      },
      command = {
        "cargo",
        "clippy",
      },
      checkOnSave = {
        command = "clippy",
      },
    },
  },

  tsserver = {
    settings = {
      typescript = {
        inlayHints = {
          includeInlayParameterNameHints = "all",
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
          includeInlayParameterNameHints = "all",
          includeInlayParameterNameHintsWhenArgumentMatchesName = true,
          includeInlayFunctionParameterTypeHints = true,
          includeInlayVariableTypeHints = true,
          includeInlayPropertyDeclarationTypeHints = true,
          includeInlayFunctionLikeReturnTypeHints = true,
          includeInlayEnumMemberValueHints = true,
        },
      },
    },
  },

  html = {
    filetypes = { "html", "twig", "hbs" },
    settings = {
      opts = {
        settings = {
          html = {
            format = {
              templating = true,
              wrapLineLength = 120,
              wrapAttributes = "auto",
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
      if vim.loop.fs_stat(path .. "/.luarc.json") or vim.loop.fs_stat(path .. "/.luarc.jsonc") then
        return
      end

      client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua, {
        runtime = { version = "LuaJIT" },
        -- Make the server aware of Neovim runtime files
        workspace = {
          checkThirdParty = false,
          library = {
            "${3rd}/luv/library",
            unpack(vim.api.nvim_get_runtime_file("", true)),
          },
        },
        completion = { callSnippet = "Replace" },
        hint = { enable = true, arrayIndex = "Disable" },
        telemetry = { enable = false },
      })
    end,
    settings = {
      Lua = {},
    },
  },

  svelte = {},

  cssls = {},

  tailwindcss = {
    hovers = true,
    suggestions = true,
    root_dir = function(fname)
      local root_pattern = require("lspconfig").util.root_pattern("tailwind.config.cjs", "tailwind.config.js", "tailwind.config.ts", "postcss.config.js")
      return root_pattern(fname)
    end,
  },

  emmet_ls = {
    settings = {
      filetypes = { "html", "typescriptreact", "javascriptreact", "css", "sass", "scss", "less", "svelte" },
    },
  },

  bashls = {},

  jdtls = {},
}

return {
  "williamboman/mason-lspconfig.nvim",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    {
      "williamboman/mason.nvim",
      event = { "BufReadPre", "BufNewFile" },
      config = function()
        require("mason").setup({
          registries = {
            "github:nvim-java/mason-registry",
            "github:mason-org/mason-registry",
          },
          ui = {
            icons = {
              package_installed = "✓",
              package_pending = "➜",
              package_uninstalled = "✗",
            },
            border = "rounded",
          },
        })
      end,
    },
    "neovim/nvim-lspconfig",
    "hrsh7th/cmp-nvim-lsp",
    {
      "j-hui/fidget.nvim",
      opts = {
        progress = {
          ignore_empty_message = true,
        },
        notification = {
          window = {
            normal_hl = "CursorLineNr",
            winblend = 0,
          },
        },
      },
    },
    "nvim-telescope/telescope.nvim",
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    "artemave/workspace-diagnostics.nvim",
    { "dmmulroy/ts-error-translator.nvim", opts = {} },
    {
      "nvim-java/nvim-java",
      dependencies = {
        "nvim-java/lua-async-await",
        "nvim-java/nvim-java-core",
        "nvim-java/nvim-java-test",
        "nvim-java/nvim-java-dap",
        "MunifTanjim/nui.nvim",
        "mfussenegger/nvim-dap",
      },
    },
  },
  config = function()
    -- add border to the floating windows
    require("lspconfig.ui.windows").default_options = {
      border = "single",
    }

    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
      callback = function(event)
        local client = vim.lsp.get_client_by_id(event.data.client_id)

        local nmap = function(keys, func, desc)
          vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
        end

        vim.lsp.inlay_hint.enable(event.buf, true)
        nmap("<leader>ti", function()
          vim.lsp.inlay_hint.enable(event.buf, not vim.lsp.inlay_hint.is_enabled())
        end, "[T]oggle [I]nlay Hints")

        nmap("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
        nmap("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")
        nmap("K", vim.lsp.buf.hover, "Hover Documentation")

        -- java doesn't support the same gd that telescope uses, this should be fixed soon
        if client and client.supports_method("textDocument/definition") then
          nmap("gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")
        end

        nmap("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")

        nmap("<leader>s", vim.lsp.buf.signature_help, "[S]ignature Documentation")

        require("workspace-diagnostics").populate_workspace_diagnostics(client, event.buf)

        if client and client.server_capabilities.documentHighlightProvider then
          -- Highlight references of the word under your cursor
          vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
            buffer = event.buf,
            callback = vim.lsp.buf.document_highlight,
          })

          -- When you move your cursor, the highlights will be cleared
          vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
            buffer = event.buf,
            callback = vim.lsp.buf.clear_references,
          })
        end
      end,
    })

    local ensure_installed = vim.tbl_keys(servers or {})
    vim.list_extend(ensure_installed, {
      -- web
      "eslint_d",
      "prettier",

      -- markdown
      "markdownlint",

      -- lua
      "stylua", -- formatter

      -- shell
      "shellcheck", -- linter
      "shfmt", -- formatter

      -- "yamllint", -- linter
      "yamlfmt", -- formatter

      -- json
      "jsonlint", -- linter

      -- text
      "vale", -- linter

      -- sql
      -- "sqlfluff", -- linter
    })
    require("mason-tool-installer").setup({
      ensure_installed = ensure_installed,
      run_on_start = false,
    })

    -- used to enable autocompletion (assign to every lsp server config)
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities()) or {}

    require("java").setup()

    require("mason-lspconfig").setup({
      automatic_installation = true, -- not the same as ensure_installed

      handlers = {
        function(server_name)
          local server = servers[server_name] or {}
          server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
          require("lspconfig")[server_name].setup(server)
        end,
      },
    })
  end,
}
