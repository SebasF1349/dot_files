local nvim_version = require("utils.nvim-version")
local lsp_mappings = require("utils.lsp-packages").lspconfig_to_package

local function organize_imports()
  local params = {
    command = "_typescript.organizeImports",
    arguments = { vim.api.nvim_buf_get_name(0) },
  }
  vim.lsp.buf.execute_command(params)
end

local servers = {
  rust_analyzer = {
    settings = {
      ["rust_analyzer"] = {
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
    commands = {
      OrganizeImports = {
        organize_imports,
        description = "Organize Imports",
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
      if (vim.uv or vim.loop).fs_stat(path .. "/.luarc.json") or (vim.uv or vim.loop).fs_stat(path .. "/.luarc.jsonc") then
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
    settings = { Lua = {} },
  },

  svelte = {},

  cssls = {},

  tailwindcss = {
    filetypes = {
      "astro",
      "astro-markdown",
      "ejs",
      "html",
      "css",
      "less",
      "postcss",
      "sass",
      "scss",
      "javascript",
      "javascriptreact",
      "typescript",
      "typescriptreact",
      "vue",
      "svelte",
    },
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

  marksman = {},
}

return {
  {
    "williamboman/mason.nvim",
    cmd = { "Mason", "MasonInstall", "MasonInstallAll", "MasonInstallNew", "MasonUpdate" },
    config = function()
      local ensure_installed = vim.tbl_keys(servers or {})
      for i, server in ipairs(ensure_installed) do
        ensure_installed[i] = lsp_mappings[server]
      end

      vim.list_extend(ensure_installed, {
        -- web
        "eslint_d",
        "prettier",
        -- markdown
        "markdownlint",
        "markdown-toc",
        -- lua
        "stylua", -- formatter
        -- java
        "google-java-format",
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

      vim.api.nvim_create_user_command("MasonInstallAll", function()
        if ensure_installed and #ensure_installed > 0 then
          vim.cmd("MasonInstall " .. table.concat(ensure_installed, " "))
        end
      end, {})

      vim.api.nvim_create_user_command("MasonInstallNew", function()
        if not ensure_installed or #ensure_installed == 0 then
          return
        end
        local mason_registry = require("mason-registry")
        local installed_packages = mason_registry.get_installed_package_names()
        for _, package in ipairs(ensure_installed) do
          if not vim.tbl_contains(installed_packages, package) then
            vim.cmd("MasonInstall " .. package)
          end
        end
      end, {})

      require("mason").setup({
        ui = {
          icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗",
          },
          border = "rounded",
          height = 0.8,
        },
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "nvim-telescope/telescope.nvim",
      "artemave/workspace-diagnostics.nvim",
      { "dmmulroy/ts-error-translator.nvim", opts = {} },
    },
    config = function()
      -- add border to the floating windows
      require("lspconfig.ui.windows").default_options = {
        border = "single",
      }

      local is_windows = vim.fn.has("win32") ~= 0
      vim.env.PATH = vim.fn.stdpath("data") .. "/mason/bin" .. (is_windows and ";" or ":") .. vim.env.PATH

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
        callback = function(event)
          local client = vim.lsp.get_client_by_id(event.data.client_id)

          vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "LSP:[C]ode [A]ction" })

          if client and client.server_capabilities.inlayHintProvider and vim.lsp.inlay_hint then
            vim.lsp.inlay_hint.enable(true)
            vim.keymap.set("n", "<leader>ti", function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = 0 }))
            end, { desc = "LSP: [T]oggle [I]nlay Hints" })
          end

          -- Diagnostic keymaps
          if not nvim_version.is_nightly() then
            vim.keymap.set("n", "[d", function()
              vim.diagnostic.goto_prev()
              vim.api.nvim_feedkeys("zz", "n", false)
            end, { desc = "LSP: Go to previous [D]iagnostic message" })
            vim.keymap.set("n", "]d", function()
              vim.diagnostic.goto_next()
              vim.api.nvim_feedkeys("zz", "n", false)
            end, { desc = "LSP: Go to next [D]iagnostic message" })
          end

          vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "LSP: Open floating diagnostic message" })

          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "LSP:[R]e[n]ame" })

          local telescope = require("telescope.builtin")
          vim.keymap.set("n", "gd", telescope.lsp_definitions, { desc = "LSP: [G]oto [D]efinition" })
          vim.keymap.set("n", "gr", telescope.lsp_references, { desc = "LSP: [G]oto [R]eferences" })
          vim.keymap.set("n", "gI", telescope.lsp_implementations, { desc = "LSP: [G]oto [I]mplementation" })
          vim.keymap.set("n", "gy", telescope.lsp_type_definitions, { desc = "LSP: [G]oto T[y]pe Definition" })
          vim.keymap.set("n", "gK", vim.lsp.buf.signature_help, { desc = "LSP: Signature Documentation on [K]Hover" })

          vim.keymap.set("n", "<leader>oi", function()
            if vim.fn.exists(":OrganizeImports") > 0 then
              vim.cmd("OrganizeImports")
            end
          end, { desc = "LSP: [O]rganize [I]mports" })

          local ok_wd, wd = pcall(require, "workspace-diagnostics")
          if ok_wd then
            wd.populate_workspace_diagnostics(client, event.buf)
          end

          if client and client.server_capabilities.documentHighlightProvider then
            local highlight_augroup = vim.api.nvim_create_augroup("lsp-highlight", { clear = false })
            -- Highlight references of the word under your cursor
            vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
              group = highlight_augroup,
              buffer = event.buf,
              callback = vim.lsp.buf.document_highlight,
            })

            -- When you move your cursor, the highlights will be cleared
            vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
              group = highlight_augroup,
              buffer = event.buf,
              callback = vim.lsp.buf.clear_references,
            })

            -- Clear highlight when detaching lsp (fix some lsp errors)
            vim.api.nvim_create_autocmd("LspDetach", {
              group = vim.api.nvim_create_augroup("lsp-detach", { clear = true }),
              callback = function(local_event)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds({ group = "lsp-highlight", buffer = local_event.buf })
              end,
            })
          end
        end,
      })

      -- used to enable autocompletion (assign to every lsp server config)
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities()) or {}

      for server_name, server in pairs(servers) do
        -- to avoid double lsp server, as java lsp is launched by the jdtls extension
        if server_name ~= "jdtls" then
          server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
          require("lspconfig")[server_name].setup(server)
        end
      end
    end,
  },
}
