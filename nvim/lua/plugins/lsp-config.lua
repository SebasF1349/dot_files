local servers = {
  rust_analyzer = {
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
  tsserver = {},
  html = {
    filetypes = { "html", "twig", "hbs" },
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

  lua_ls = {
    Lua = {
      workspace = { checkThirdParty = false },
      telemetry = { enable = false },
    },
  },

  svelte = {
    ["sveltejs/language-tools"] = {},
  },

  cssls = {
    ["css-lsp"] = {},
  },

  tailwindcss = {
    ["tailwindcss-language-server"] = {},
  },

  emmet_ls = {
    filetypes = { "html", "typescriptreact", "javascriptreact", "css", "sass", "scss", "less", "svelte" },
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
      -- used to enable autocompletion (assign to every lsp server config)
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local cmp_nvim_lsp = require("cmp_nvim_lsp")
      capabilities = cmp_nvim_lsp.default_capabilities()

      local on_attach = function(data, bufnr)
        vim.lsp.inlay_hint.enable(bufnr, true)
        local nmap = function(keys, func, desc)
          if desc then
            desc = "LSP: " .. desc
          end

          vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
        end

        nmap("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
        nmap("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")

        nmap("gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")
        nmap("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
        nmap("gI", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")
        -- nmap("<leader>D", require("telescope.builtin").lsp_type_definitions, "Type [D]efinition")
        -- nmap("<leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")
        nmap("<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")

        nmap("K", vim.lsp.buf.hover, "Hover Documentation")
        nmap("<leader>s", vim.lsp.buf.signature_help, "Signature Documentation")

        if data.name == "tailwind" then
          vim.keymap.set({ "n", "i", "x", "s" }, "<C-s>", "<Esc>:wa<cr>:TailwindSort<cr>")
        end

        -- Lesser used LSP functionality
        nmap("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
        nmap("<leader>wa", vim.lsp.buf.add_workspace_folder, "[W]orkspace [A]dd Folder")
        nmap("<leader>wr", vim.lsp.buf.remove_workspace_folder, "[W]orkspace [R]emove Folder")
        nmap("<leader>wl", function()
          print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
        end, "[W]orkspace [L]ist Folders")

        -- Create a command `:Format` local to the LSP buffer
        vim.api.nvim_buf_create_user_command(bufnr, "Format", function(_)
          vim.lsp.buf.format()
        end, { desc = "Format current buffer with LSP" })
      end

      local mason_lspconfig = require("mason-lspconfig")
      mason_lspconfig.setup({
        -- list of servers for mason to install
        ensure_installed = vim.tbl_keys(servers),
        -- auto-install configured servers (with lspconfig)
        automatic_installation = true, -- not the same as ensure_installed
      })
      mason_lspconfig.setup_handlers({
        function(server_name)
          require("lspconfig")[server_name].setup({
            capabilities = capabilities,
            on_attach = on_attach,
            settings = servers[server_name],
            filetypes = (servers[server_name] or {}).filetypes,
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
      })
    end,
  },
}
