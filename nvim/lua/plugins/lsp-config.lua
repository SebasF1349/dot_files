local servers = {
  rust_analyzer = {
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
    },
    command = {
      "cargo",
      "clippy",
    },
    checkOnSave = {
      command = "clippy",
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
    ["tailwind-language-server"] = {},
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
        },
      })
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "neovim/nvim-lspconfig",
      "simrat39/rust-tools.nvim",
      "hrsh7th/cmp-nvim-lsp",
      {
        "j-hui/fidget.nvim",
        opts = {
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
      -- used to enable autocompletion (assign to every lsp server config)
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local cmp_nvim_lsp = require("cmp_nvim_lsp")
      capabilities = cmp_nvim_lsp.default_capabilities()

      local on_attach = function(data, bufnr)
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
        nmap("<leader>D", require("telescope.builtin").lsp_type_definitions, "Type [D]efinition")
        nmap("<leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")
        nmap("<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")

        -- See `:help K` for why this keymap
        if data.name == "rust_analyzer" then
          nmap("K", require("rust-tools").hover_actions.hover_actions, "Hover Documentation")
        else
          nmap("K", vim.lsp.buf.hover, "Hover Documentation")
        end
        nmap("<C-s>", vim.lsp.buf.signature_help, "Signature Documentation")

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

      local codelldb = require("mason-registry").get_package("codelldb")
      local extension_path = codelldb:get_install_path() .. "/extension/"
      local codelldb_path = extension_path .. "adapter/codelldb"
      local liblldb_path = extension_path .. "lldb/lib/liblldb.so"

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
        ["rust_analyzer"] = function()
          require("rust-tools").setup({
            server = {
              on_attach = on_attach,
              capabilities = capabilities,
              --settings = servers['rust_analyzer'],
              settings = {
                cargo = {
                  allFeatures = true,
                },
              },
              filetypes = { "rust", "rs" },
              check = {
                command = "clippy",
                extraArgs = { "--all", "--", "-W", "clippy::all" },
              },
            },
            tools = {
              hover_actions = {
                auto_focus = true,
              },
            },
            dap = {
              adapter = require("rust-tools.dap").get_codelldb_adapter(codelldb_path, liblldb_path),
            },
          })
        end,
      })
      -- Setup neovim lua configuration
      require("neodev").setup()
    end,
  },
}
