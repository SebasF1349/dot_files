local nvim_version = require('utils.nvim-version')
local lsp_mappings = require('plugins.lsp.lsp-packages').lspconfig_to_package
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
        -- work
        'phpcs',
        'php-cs-fixer',
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
          height = 0.8,
        },
      })
    end,
  },
  { 'dmmulroy/ts-error-translator.nvim', ft = { 'typescript', 'svelte' }, opts = {} },
  { 'artemave/workspace-diagnostics.nvim' },
  { 'felpafel/inlay-hint.nvim' }, -- check nvim-lsp-endhints to show inlay hints only in current line
  {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPost', 'BufNewFile' },
    config = function()
      local is_windows = vim.fn.has('win32') ~= 0
      vim.env.PATH = vim.fn.stdpath('data') .. '/mason/bin' .. (is_windows and ';' or ':') .. vim.env.PATH

      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
        callback = function(event)
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if not client then
            return
          end

          vim.api.nvim_create_autocmd({ 'InsertEnter' }, {
            callback = function()
              vim.lsp.completion.trigger()
            end,
          })
          -- based on https://github.com/neovim/neovim/issues/29225#issuecomment-2159428607 (autocmd breaks snippets)
          vim.api.nvim_create_autocmd('CompleteChanged', {
            buffer = event.buf,
            callback = function()
              local info = vim.fn.complete_info({ 'selected' })
              local completionItem = vim.tbl_get(vim.v.completed_item, 'user_data', 'nvim', 'lsp', 'completion_item')
              if not completionItem then
                return
              end

              local resolvedItem = vim.lsp.buf_request_sync(
                event.buf,
                vim.lsp.protocol.Methods.completionItem_resolve,
                completionItem,
                500
              ) or {}

              local docs = vim.tbl_get(resolvedItem[event.data.client_id], 'result', 'documentation', 'value') or ''

              local winData = vim.api.nvim__complete_set(info['selected'], { info = docs })
              if not winData.winid or not vim.api.nvim_win_is_valid(winData.winid) then
                return
              end

              if docs == '' then
                vim.api.nvim_set_option_value('winhighlight', 'NormalFloat:Float', { win = winData.winid })
                return
              end

              vim.api.nvim_set_option_value('winhighlight', 'Normal:NormalFloat', { win = winData.winid })
              vim.treesitter.start(winData.bufnr, 'markdown')
              vim.wo[winData.winid].conceallevel = 3
            end,
          })
          vim.lsp.completion.enable(true, event.data.client_id, event.buf, { autotrigger = true })
          vim.opt.completeopt = { 'menuone', 'noselect', 'noinsert', 'fuzzy', 'popup' }
          vim.keymap.set({ 'i', 's' }, '<C-l>', function()
            if vim.fn.pumvisible() ~= 0 then
              return '<C-y>'
            elseif vim.snippet.active({ direction = 1 }) then
              return '<cmd>lua vim.snippet.jump(1)<cr>'
            else
              vim.lsp.completion.trigger()
            end
          end, { desc = 'Select, Expand and Jump Snippet', expr = true })
          vim.keymap.set({ 'i', 's' }, '<C-h>', function()
            if vim.snippet.active({ direction = -1 }) then
              return '<cmd>lua vim.snippet.jump(-1)<cr>'
            else
              return '<C-h>'
            end
          end, { desc = 'Jump Snippet Backwards', expr = true })
          vim.keymap.set('s', '<BS>', '<C-O>s', { desc = 'Delete Selected Text' })
          vim.keymap.set('i', '<BS>', function()
            return vim.fn.pumvisible() ~= 0 and '<BS><cmd>lua vim.lsp.completion.trigger()<CR>' or '<BS>'
          end, { desc = 'Retrigger completion when deleting', expr = true })
          vim.keymap.set(
            'i',
            '<C-Space>',
            vim.lsp.completion.trigger,
            { silent = true, desc = 'Trigger LSP Completion' }
          )
          vim.keymap.set('i', '<CR>', function()
            if vim.fn.pumvisible() ~= 0 then
              return '<C-e><CR>'
            else
              return '<CR>'
            end
          end, { desc = 'Accept selected or new line', expr = true })
          -- NOTE: nice pum styling https://github.com/neovim/neovim/pull/25541

          if client and client.server_capabilities.inlayHintProvider and vim.lsp.inlay_hint then
            require('inlay-hint').setup()
            vim.lsp.inlay_hint.enable(true)
            vim.keymap.set('n', '<leader>ti', function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = 0 }))
            end, { desc = 'LSP: [T]oggle [I]nlay Hints' })
          end

          local ts_repeat_move = require('nvim-treesitter.textobjects.repeatable_move')
          local next_diag, prev_diag = ts_repeat_move.make_repeatable_move_pair(function()
            vim.diagnostic.jump({ count = 1 })
          end, function()
            vim.diagnostic.jump({ count = -1 })
          end)
          vim.keymap.set('n', ']d', next_diag, { desc = 'LSP: Go to next [D]iagnostic message' })
          vim.keymap.set('n', '[d', prev_diag, { desc = 'LSP: Go to prev [D]iagnostic message' })
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

      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities.textDocument.completion.completionItem.snippetSupport = true

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
