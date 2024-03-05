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
    settings = {
      Lua = {
        runtime = { version = "LuaJIT" },
        workspace = {
          checkThirdParty = false,
          -- Tells lua_ls where to find all the Lua files that you have loaded
          -- for your neovim configuration.
          library = {
            "${3rd}/luv/library",
            unpack(vim.api.nvim_get_runtime_file("", true)),
          },
          -- If lua_ls is really slow on your computer, you can try this instead:
          -- library = { vim.env.VIMRUNTIME },
        },
        completion = {
          callSnippet = "Replace",
        },
        hint = { enable = true, arrayIndex = "Disable" },
        telemetry = { enable = false },
      },
    },
  },

  svelte = {},

  cssls = {},

  tailwindcss = {
    hovers = true,
    suggestions = true,
    root_dir = function(fname)
      vim.inspect(fname)
      local root_pattern = require("lspconfig").util.root_pattern("tailwind.config.cjs", "tailwind.config.js", "tailwind.config.ts", "postcss.config.js")
      vim.inspect(root_pattern(fname), fname)
      return root_pattern(fname)
    end,
  },

  emmet_ls = {
    settings = {
      filetypes = { "html", "typescriptreact", "javascriptreact", "css", "sass", "scss", "less", "svelte" },
    },
  },

  bashls = {},
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
  },
  config = function()
    -- add border to the floating windows
    require("lspconfig.ui.windows").default_options = {
      border = "single",
    }

    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
      callback = function(event)
        vim.lsp.inlay_hint.enable(event.buf, true)

        local nmap = function(keys, func, desc)
          vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP:" .. desc })
        end

        nmap("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
        nmap("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")
        nmap("S", vim.lsp.buf.hover, "Hover Documentation")

        -- Jump to the definition of the word under your cursor.
        --  This is where a variable was first declared, or where a function is defined, etc.
        --  To jump back, press <C-T>.
        nmap("gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")

        -- Find references for the word under your cursor.
        nmap("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")

        nmap("<leader>s", vim.lsp.buf.signature_help, "Signature Documentation")

        if event.data.name == "tailwind" then
          vim.keymap.set({ "n", "i", "x", "s" }, "<C-s>", "<Esc>:wa<cr>:TailwindSort<cr>", { desc = "Save and Sort Tailwind Clases" })
        end

        local client = vim.lsp.get_client_by_id(event.data.client_id)
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
