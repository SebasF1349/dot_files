local nvim_version = require('utils.nvim-version')
local lsp_mappings = require('plugins.lsp.lsp-packages')
local servers = require('plugins.lsp.servers')

return {
  {
    'williamboman/mason.nvim',
    cmd = { 'Mason', 'MasonInstall', 'MasonInstallAll', 'MasonInstallNew', 'MasonUpdate' },
    config = function()
      local ensure_installed = vim.tbl_keys(servers or {})
      for i, server in ipairs(ensure_installed) do
        ensure_installed[i] = lsp_mappings[server]
      end

      vim.list_extend(ensure_installed, {
        -- web
        'eslint_d',
        'prettier',
        -- markdown
        'markdownlint',
        'markdown-toc',
        -- lua
        'stylua', -- formatter
        -- java
        'java-debug-adapter',
        'java-test',
        'google-java-format',
        -- shell
        'shellcheck', -- linter
        'shfmt', -- formatter
        -- "yamllint", -- linter
        'yamlfmt', -- formatter
        -- json
        'jsonlint', -- linter
        -- text
        'vale', -- linter
        -- sql
        -- "sqlfluff", -- linter
      })

      vim.api.nvim_create_user_command('MasonInstallAll', function()
        if ensure_installed and #ensure_installed > 0 then
          vim.cmd('MasonInstall ' .. table.concat(ensure_installed, ' '))
        end
      end, {})

      vim.api.nvim_create_user_command('MasonInstallNew', function()
        if not ensure_installed or #ensure_installed == 0 then
          return
        end
        local mason_registry = require('mason-registry')
        local installed_packages = mason_registry.get_installed_package_names()
        for _, package in ipairs(ensure_installed) do
          if not vim.tbl_contains(installed_packages, package) then
            vim.cmd('MasonInstall ' .. package)
          end
        end
      end, {})

      require('mason').setup({
        ui = {
          icons = {
            package_installed = '✓',
            package_pending = '➜',
            package_uninstalled = '✗',
          },
          border = 'rounded',
          height = 0.8,
        },
      })
    end,
  },
  { 'dmmulroy/ts-error-translator.nvim', ft = { 'typescript', 'svelte' }, opts = {} },
  {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPost', 'BufNewFile' },
    dependencies = {
      'hrsh7th/cmp-nvim-lsp',
      'artemave/workspace-diagnostics.nvim',
      'felpafel/inlay-hint.nvim', -- check nvim-lsp-endhints to show inlay hints only in current line
    },
    config = function()
      -- add border to the floating windows
      require('lspconfig.ui.windows').default_options = {
        border = 'single',
      }

      local is_windows = vim.fn.has('win32') ~= 0
      vim.env.PATH = vim.fn.stdpath('data') .. '/mason/bin' .. (is_windows and ';' or ':') .. vim.env.PATH

      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
        callback = function(event)
          local client = vim.lsp.get_client_by_id(event.data.client_id)

          if client and client.server_capabilities.inlayHintProvider and vim.lsp.inlay_hint then
            require('inlay-hint').setup()
            vim.lsp.inlay_hint.enable(true)
            vim.keymap.set('n', '<leader>ti', function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = 0 }))
            end, { desc = 'LSP: [T]oggle [I]nlay Hints' })
          end

          -- Diagnostic keymaps
          if not nvim_version.is_nightly() then
            vim.keymap.set('n', '[d', function()
              ---@diagnostic disable-next-line: deprecated
              vim.diagnostic.goto_prev()
              vim.api.nvim_feedkeys('zz', 'n', false)
            end, { desc = 'LSP: Go to previous [D]iagnostic message' })
            vim.keymap.set('n', ']d', function()
              ---@diagnostic disable-next-line: deprecated
              vim.diagnostic.goto_next()
              vim.api.nvim_feedkeys('zz', 'n', false)
            end, { desc = 'LSP: Go to next [D]iagnostic message' })
          end

          vim.keymap.set('n', 'gr', '<NOP>', { desc = 'LSP mappings' })
          vim.keymap.set('n', 'gre', vim.diagnostic.open_float, { desc = 'LSP: Open Floating [E]rror Message' })
          vim.keymap.set('n', 'grd', '<C-]>', { desc = 'LSP: [G]oto [D]efinition' })
          vim.keymap.set('n', 'gri', vim.lsp.buf.implementation, { desc = 'LSP: [G]oto [I]mplementation' })
          vim.keymap.set('n', 'grt', vim.lsp.buf.type_definition, { desc = 'LSP: [G]oto [T]ype Definition' })
          vim.keymap.set('n', 'grs', vim.lsp.buf.signature_help, { desc = 'LSP: [S]ignature Documentation on Hover' })

          vim.keymap.set('n', 'gro', function()
            if vim.fn.exists(':OrganizeImports') > 0 then
              vim.cmd('OrganizeImports')
            else
              vim.lsp.buf.code_action({
                ---@diagnostic disable-next-line: missing-fields
                context = { only = { 'source.organizeImports' } },
                apply = true,
              })
            end
          end, { desc = 'LSP: [O]rganize Imports' })

          local ok_wd, wd = pcall(require, 'workspace-diagnostics')
          if ok_wd then
            wd.populate_workspace_diagnostics(client, event.buf)
          end

          if client and client.server_capabilities.documentHighlightProvider then
            local highlight_augroup = vim.api.nvim_create_augroup('lsp-highlight', { clear = false })
            -- Highlight references of the word under your cursor
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
              group = highlight_augroup,
              buffer = event.buf,
              callback = vim.lsp.buf.document_highlight,
            })

            -- When you move your cursor, the highlights will be cleared
            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
              group = highlight_augroup,
              buffer = event.buf,
              callback = vim.lsp.buf.clear_references,
            })

            -- Clear highlight when detaching lsp (fix some lsp errors)
            vim.api.nvim_create_autocmd('LspDetach', {
              group = vim.api.nvim_create_augroup('lsp-detach', { clear = true }),
              callback = function(local_event)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds({ group = 'lsp-highlight', buffer = local_event.buf })
              end,
            })
          end
        end,
      })

      -- used to enable autocompletion (assign to every lsp server config)
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities = vim.tbl_deep_extend('force', capabilities, require('cmp_nvim_lsp').default_capabilities()) or {}

      for server_name, server in pairs(servers) do
        -- to avoid double lsp server, as java lsp is launched by the jdtls extension
        if server_name ~= 'jdtls' then
          server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
          require('lspconfig')[server_name].setup(server)
        end
      end
    end,
  },
}
