local servers = {
  rust_analyzer = {
    settings = {
      ["rust-analyzer"] = {
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
  },

  tsserver = {},

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
        workspace = { checkThirdParty = false },
        telemetry = { enable = false },
      },
    },
  },

  svelte = {
    settings = {
      ["sveltejs/language-tools"] = {},
    },
  },

  cssls = {
    settings = {
      ["css-lsp"] = {},
    },
  },

  tailwindcss = {
    settings = {
      ["tailwindcss-language-server"] = {},
    },
  },

  emmet_ls = {
    settings = {
      filetypes = { "html", "typescriptreact", "javascriptreact", "css", "sass", "scss", "less", "svelte" },
    },
  },
}

return {
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
  {
    "williamboman/mason-lspconfig.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
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
      "folke/neodev.nvim",
      "nvim-telescope/telescope.nvim",
      "WhoIsSethDaniel/mason-tool-installer.nvim",
    },
    config = function()
      -- add border to the floating windows
      require("lspconfig.ui.windows").default_options = {
        border = "single",
      }

      -- Setup neovim lua configuration
      require("neodev").setup({
        override = function(root_dir, library)
          if root_dir:match("dot_files") then
            library.enabled = true
            library.plugins = true
          end
        end,
      })

      local on_attach = function(data, bufnr)
        vim.lsp.inlay_hint.enable(bufnr, true)

        local nmap = function(keys, func, desc)
          vim.keymap.set("n", keys, func, { buffer = bufnr, desc = "LSP:" .. desc })
        end

        nmap("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
        nmap("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")
        nmap("K", vim.lsp.buf.hover, "Hover Documentation")

        -- Jump to the definition of the word under your cursor.
        --  This is where a variable was first declared, or where a function is defined, etc.
        --  To jump back, press <C-T>.
        nmap("gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")

        -- Find references for the word under your cursor.
        nmap("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")

        nmap("<leader>s", vim.lsp.buf.signature_help, "Signature Documentation")

        if data.name == "tailwind" then
          vim.keymap.set({ "n", "i", "x", "s" }, "<C-s>", "<Esc>:wa<cr>:TailwindSort<cr>")
        end

        -- Create a command `:Format` local to the LSP buffer
        vim.api.nvim_buf_create_user_command(bufnr, "Format", function(_)
          vim.lsp.buf.format()
        end, { desc = "Format current buffer with LSP" })

        -- The following two autocommands are used to highlight references of the
        -- word under your cursor when your cursor rests there for a little while.
        --    See `:help CursorHold` for information about when this is executed
        --
        -- When you move your cursor, the highlights will be cleared (the second autocommand).
        local client = vim.lsp.get_client_by_id(data.client_id)
        if client and client.server_capabilities.documentHighlightProvider then
          vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
            buffer = bufnr,
            callback = vim.lsp.buf.document_highlight,
          })

          vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
            buffer = bufnr,
            callback = vim.lsp.buf.clear_references,
          })
        end
      end

      -- used to enable autocompletion (assign to every lsp server config)
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())
      local ensure_installed = vim.tbl_keys(servers or {})
      vim.list_extend(ensure_installed, {
        "stylua", -- Used to format lua code
      })
      require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

      require("mason-lspconfig").setup({
        automatic_installation = true, -- not the same as ensure_installed

        handlers = {
          function(server_name)
            local server = servers[server_name] or {}
            require("lspconfig")[server_name].setup({
              cmd = server.cmd,
              settings = server.settings,
              filetypes = server.filetypes,
              capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {}),
              on_attach = on_attach,
            })
          end,

          ["tailwindcss"] = function()
            require("lspconfig").tailwindcss.setup({
              hovers = true,
              suggestions = true,
              root_dir = function(fname)
                vim.inspect(fname)
                local root_pattern =
                  require("lspconfig").util.root_pattern("tailwind.config.cjs", "tailwind.config.js", "tailwind.config.ts", "postcss.config.js")
                vim.inspect(root_pattern(fname), fname)
                return root_pattern(fname)
              end,
            })
          end,
        },
      })
    end,
  },
}
