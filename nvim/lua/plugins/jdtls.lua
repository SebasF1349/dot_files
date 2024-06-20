-- based on https://github.com/LazyVim/LazyVim/blob/6e57e86c9952986a0e90055e13aa86dcde5e478e/lua/lazyvim/plugins/extras/lang/java.lua
return {
  "mfussenegger/nvim-jdtls",
  dependencies = {
    "mfussenegger/nvim-dap",
    "williamboman/mason.nvim",
    "neovim/nvim-lspconfig",
    "hrsh7th/cmp-nvim-lsp",
  },
  ft = "java",
  config = function()
    local bundles = {} ---@type string[]
    local mason_install_path = vim.env.HOME .. "/.local/share/nvim/mason/packages"
    local jar_patterns = {
      mason_install_path .. "/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar",
      mason_install_path .. "/java-test/extension/server/*.jar",
    }
    for _, jar_pattern in ipairs(jar_patterns) do
      for _, bundle in ipairs(vim.split(vim.fn.glob(jar_pattern), "\n")) do
        table.insert(bundles, bundle)
      end
    end

    local cmd = function()
      local fname = vim.api.nvim_buf_get_name(0)
      local root_dir = require("lspconfig.server_configurations.jdtls").default_config.root_dir(fname)
      local cmd = { vim.fn.exepath("jdtls") }
      local project_name = root_dir and vim.fs.basename(root_dir)
      local jdtls_config_dir = vim.fn.stdpath("cache") .. "/jdtls/" .. project_name .. "/config"
      local jdtls_workspace_dir = vim.fn.stdpath("cache") .. "/jdtls/" .. project_name .. "/workspace"
      if project_name then
        vim.list_extend(cmd, {
          "-configuration",
          jdtls_config_dir,
          "-data",
          jdtls_workspace_dir,
        })
      end
      return cmd
    end

    local config = function()
      return {
        cmd = cmd(),
        root_dir = require("jdtls.setup").find_root({ "pom.xml", "mvnw", "gradlew", ".git" }), -- update to vim.fs.root in nv0.10
        init_options = { bundles = bundles },
        filetypes = { "java" },
        settings = {
          java = {
            configuration = {
              updateBuildConfiguration = "interactive",
            },
            eclipse = {
              downloadSources = true,
            },
            maven = {
              downloadSources = true,
            },
            implementationsCodeLens = {
              enabled = true,
            },
            referencesCodeLens = {
              enabled = true,
            },
            references = {
              includeAccessors = true,
              includeDecompiledSources = true,
            },
            format = {
              enabled = true,
            },
            signatureHelp = {
              enabled = true,
            },
            inlayHints = {
              parameterNames = {
                enabled = "all",
              },
            },
            sources = {
              organizeImports = {
                starThreshold = 9999,
                staticStarThreshold = 9999,
              },
            },
            codeGeneration = {
              toString = {
                template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
              },
              useBlocks = true,
            },
          },
        },
        capabilities = require("cmp_nvim_lsp").default_capabilities(),
        dap = { hotcodereplace = "auto", config_overrides = {} },
        dap_main = {},
        test = true,
      }
    end

    local function attach_jdtls()
      require("jdtls").start_or_attach(config())

      -- codelens
      pcall(vim.lsp.codelens.refresh)
      vim.api.nvim_create_autocmd("BufWritePost", {
        buffer = 0,
        callback = function()
          pcall(vim.lsp.codelens.refresh)
        end,
        desc = "Refresh Codelens",
      })
    end

    vim.api.nvim_create_autocmd("FileType", {
      pattern = "java",
      callback = attach_jdtls,
    })

    vim.api.nvim_create_autocmd("LspAttach", {
      callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if client and client.name == "jdtls" then
          local jdtls_dap = require("jdtls.dap")
          require("jdtls").setup_dap(config().dap)
          jdtls_dap.setup_dap_main_class_configs(config().dap_main)
          if config().test then
            vim.keymap.set("n", "<leader>nt", jdtls_dap.test_class, { desc = "[N]eotest [T]est" })
            vim.keymap.set("n", "<leader>nn", jdtls_dap.test_nearest_method, { desc = "[N]eotest Test [N]earest" })
            vim.keymap.set("n", "<leader>np", jdtls_dap.pick_test, { desc = "[N]eotest [P]ick Test" })
          end
        end
      end,
    })

    -- Avoid race condition by calling attach the first time, since the autocmd won't fire.
    attach_jdtls()
  end,
}
