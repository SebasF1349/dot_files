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
  { 'artemave/workspace-diagnostics.nvim' },
  {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPost', 'BufNewFile' },
    config = function()
      local oss = require('utils.os')
      vim.env.PATH = vim.fn.stdpath('data') .. '/mason/bin' .. (oss.is_win and ';' or ':') .. vim.env.PATH

      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
        callback = function(event)
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if not client then
            return
          end

          vim.api.nvim_create_autocmd({ 'InsertEnter' }, {
            buffer = event.buf,
            callback = function()
              vim.lsp.completion.trigger()
            end,
          })
          -- based on https://github.com/neovim/neovim/issues/29225#issuecomment-2159428607 (autocmd there breaks snippets)
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
          vim.lsp.completion.enable(true, event.data.client_id, event.buf, {
            autotrigger = true,
            convert = function(item)
              local labelDetails = item.labelDetails and item.labelDetails.description or ''
              local kind = vim.lsp.protocol.CompletionItemKind[item.kind]
              return {
                menu = labelDetails,
                kind_hlgroup = kind and 'CmpItemKind' .. kind or 'CmpItemKindUnit',
              }
            end,
            desc = 'Highlight kinds as in cmp',
          })

          vim.o.completeitemalign = 'abbr,menu,kind'
          vim.o.pumheight = 6
          vim.opt.completeopt = { 'menuone', 'noselect', 'fuzzy', 'popup' }

          -- vim.keymap.set('s', '<C-l>', function()
          --   if vim.snippet.active({ direction = 1 }) then
          --     return '<cmd>lua vim.snippet.jump(1)<cr>'
          --   else
          --     return '<C-l>'
          --   end
          -- end, { desc = 'Jump Snippet Forwards', expr = true, buffer = event.buf })
          -- vim.keymap.set('s', '<C-h>', function()
          --   if vim.snippet.active({ direction = -1 }) then
          --     return '<cmd>lua vim.snippet.jump(-1)<cr>'
          --   else
          --     return '<C-h>'
          --   end
          -- end, { desc = 'Jump Snippet Backwards', expr = true, buffer = event.buf })
          vim.keymap.set({ 'i', 's' }, '<C-c>', function()
            if vim.snippet then
              vim.snippet.stop()
            end
            return '<ESC>'
          end, { desc = 'Delete Selected Text', expr = true, buffer = event.buf })
          vim.keymap.set('s', '<BS>', '<C-O>s', { desc = 'Delete Selected Text', buffer = event.buf })
          vim.keymap.set('i', '<BS>', function()
            return vim.fn.pumvisible() ~= 0 and '<BS><cmd>lua vim.lsp.completion.trigger()<CR>' or '<BS>'
          end, { desc = 'Retrigger completion when deleting', expr = true, buffer = event.buf })
          vim.keymap.set('i', '<C-n>', function()
            if vim.fn.pumvisible() ~= 0 then
              vim.api.nvim_input('<C-n>')
            elseif next(vim.lsp.get_clients({ bufnr = 0 })) then
              vim.lsp.completion.trigger()
            elseif vim.bo.omnifunc == '' then
              vim.api.nvim_input('<C-x><C-n>')
            else
              vim.api.nvim_input('<C-x><C-o>')
            end
          end, { desc = 'Trigger And Select Next Completion' })
          -- NOTE: nice pum styling https://github.com/neovim/neovim/pull/25541

          -- if client and client.server_capabilities.inlayHintProvider and vim.lsp.inlay_hint then
          --   require('inlay-hint').setup()
          --   vim.lsp.inlay_hint.enable(true)
          --   vim.keymap.set('n', '<leader>ti', function()
          --     vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = 0 }))
          --   end, { desc = 'LSP: [T]oggle [I]nlay Hints', buffer = event.buf })
          -- end

          local ts_repeat_move = require('nvim-treesitter.textobjects.repeatable_move')
          local next_diag, prev_diag = ts_repeat_move.make_repeatable_move_pair(function()
            vim.diagnostic.jump({ count = 1 })
          end, function()
            vim.diagnostic.jump({ count = -1 })
          end)
          vim.keymap.set('n', ']d', next_diag, { desc = 'LSP: Go to next [D]iagnostic message', buffer = event.buf })
          vim.keymap.set('n', '[d', prev_diag, { desc = 'LSP: Go to prev [D]iagnostic message', buffer = event.buf })

          -- replaced my own implementation with Folke's which is more performant: https://github.com/folke/snacks.nvim/blob/main/lua/snacks/words.lua#L117
          local ns = vim.api.nvim_create_namespace('vim_lsp_references')

          ---@alias LspWord {from:{[1]:number, [2]:number}, to:{[1]:number, [2]:number}} 1-0 indexed

          ---@return LspWord[] words, number? current
          local function get_lsp_word()
            local cursor = vim.api.nvim_win_get_cursor(0)
            local current, ret = nil, {} ---@type number?, LspWord[]
            for _, extmark in ipairs(vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, { details = true })) do
              local w = {
                from = { extmark[2] + 1, extmark[3] },
                to = { extmark[4].end_row + 1, extmark[4].end_col },
              }
              ret[#ret + 1] = w
              if
                cursor[1] >= w.from[1]
                and cursor[1] <= w.to[1]
                and cursor[2] >= w.from[2]
                and cursor[2] <= w.to[2]
              then
                current = #ret
              end
            end
            return ret, current
          end

          ---@param count number
          ---@param direction 1 | -1
          ---@param cycle? boolean
          local function move_reference(count, direction, cycle)
            local words, idx = get_lsp_word()
            if not idx then
              return
            end
            idx = idx + count * direction
            if cycle then
              idx = (idx - 1) % #words + 1
            end
            local target = words[idx]
            if target then
              vim.api.nvim_win_set_cursor(0, target.from)
            end
          end

          vim.keymap.set('n', ']r', function()
            move_reference(vim.v.count1, 1, true)
          end, { desc = 'LSP: Go to next [R]eference', buffer = event.buf })
          vim.keymap.set('n', '[r', function()
            move_reference(vim.v.count1, -1, true)
          end, { desc = 'LSP: Go to previous [R]eference', buffer = event.buf })

          vim.keymap.set('n', 'gr', '<NOP>', { desc = 'LSP mappings', buffer = event.buf })
          vim.keymap.set(
            'n',
            'gre',
            vim.diagnostic.open_float,
            { desc = 'LSP: Open Floating [E]rror Message', buffer = event.buf }
          )
          vim.keymap.set('n', 'grd', '<C-]>', { desc = 'LSP: [G]oto [D]efinition', buffer = event.buf })
          vim.keymap.set(
            'n',
            'grt',
            vim.lsp.buf.type_definition,
            { desc = 'LSP: [G]oto [T]ype Definition', buffer = event.buf }
          )

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
          end, { desc = 'LSP: [O]rganize Imports', buffer = event.buf })

          if client:supports_method('textDocument/signatureHelp') then
            vim.api.nvim_create_autocmd('InsertCharPre', {
              buffer = 0,
              callback = function()
                local char = vim.v.char
                if char == '(' or char == ',' then
                  vim.defer_fn(function()
                    vim.lsp.buf.signature_help()
                  end, 3)
                end
              end,
            })
          end

          for _, key in ipairs({ '<C-b>', '<C-f>' }) do
            vim.keymap.set({ 'n', 'i' }, key, function()
              local winnr = vim.b.lsp_floating_preview
              if not winnr or not vim.api.nvim_win_is_valid(winnr) then
                local keys = vim.api.nvim_replace_termcodes(key, true, false, true)
                vim.api.nvim_feedkeys(keys, 'n', true)
                return
              end
              local cursor_pos = vim.api.nvim_win_get_cursor(winnr)
              local win_config = vim.api.nvim_win_get_config(winnr)
              local new_row = key == '<C-b>' and math.max(cursor_pos[1] - win_config.height + 1, 1)
                or math.min(cursor_pos[1] + win_config.height - 1, vim.fn.line('$', winnr))
              vim.api.nvim_win_set_cursor(winnr, { new_row, cursor_pos[2] })
            end, { desc = 'Scroll Docs' })
          end

          -- based on https://github.com/mfussenegger/nvim-qwahl/blob/main/lua/qwahl.lua#L446C1-L468C4
          ---@param bufnr? integer 0 for current buffer; nil for all diagnostic
          ---@param opts? {lnum?: integer, severity?: vim.diagnostic.Severity} See vim.diagnostic.get
          local function select_diagnostic(bufnr, opts)
            local diagnostics = vim.diagnostic.get(bufnr, opts)
            local ui_opts = {
              prompt = 'Diagnostic: ',
              format_item = function(d)
                local new_line = d.message:find('\n')
                if new_line then
                  d.message = d.message:sub(1, new_line - 1)
                end
                local signs = { ' ', ' ', ' ', ' ' }
                local bufname = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(d.bufnr), ':p:.')
                local lnum = d.lnum or d.end_lnum
                return string.format('%s%s (%s:%s)', signs[d.severity], d.message, bufname, lnum + 1)
              end,
            }
            local win = vim.api.nvim_get_current_win()
            vim.ui.select(diagnostics, ui_opts, function(d)
              if d then
                vim.api.nvim_set_current_buf(d.bufnr)
                vim.api.nvim_win_set_cursor(win, { d.lnum + 1, d.col })
                vim.api.nvim_win_call(win, function()
                  vim.cmd('normal! zvzz')
                end)
              end
            end)
          end
          vim.keymap.set('n', 'grl', select_diagnostic, { desc = '[L]ist Diagnostics', buffer = event.buf })

          local ok_wd, wd = pcall(require, 'workspace-diagnostics')
          if ok_wd then
            wd.populate_workspace_diagnostics(client, event.buf)
          end

          -- if client:supports_method('textDocument/foldingRange') then
          --   vim.wo.foldmethod = 'expr'
          --   vim.wo.foldexpr = 'v:lua.vim.lsp.foldexpr()'
          -- end

          if client.server_capabilities.documentHighlightProvider then
            local highlight_augroup = vim.api.nvim_create_augroup('lsp-highlight', { clear = false })
            -- Highlight references of the word under your cursor
            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI', 'ModeChanged' }, {
              group = highlight_augroup,
              buffer = event.buf,
              callback = function()
                vim.schedule(function()
                  vim.lsp.buf.clear_references()
                  if vim.fn.mode() == 'n' then
                    vim.lsp.buf.document_highlight()
                  end
                end)
              end,
            })

            -- -- When you move your cursor, the highlights will be cleared
            -- vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
            --   group = highlight_augroup,
            --   buffer = event.buf,
            --   callback = vim.lsp.buf.clear_references,
            -- })

            -- Clear highlight when detaching lsp (fix some lsp errors)
            vim.api.nvim_create_autocmd('LspDetach', {
              group = vim.api.nvim_create_augroup('lsp-detach', { clear = true }),
              buffer = event.buf,
              callback = function(local_event)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds({ group = 'lsp-highlight', buffer = local_event.buf })
              end,
            })
          end
        end,
      })

      -- thanks lewis: https://github.com/lewis6991/dotfiles/blob/main/config/nvim/lua/lewis6991/diagnostic.lua#L25
      -- Override the virtual text diagnostic handler so that the most severe diagnostic is shown first,
      -- without changing normal order for same severity.
      local show_handler = vim.diagnostic.handlers.virtual_text.show
      assert(show_handler)
      local hide_handler = vim.diagnostic.handlers.virtual_text.hide
      vim.diagnostic.handlers.virtual_text = {
        show = function(ns, bufnr, diagnostics, opts)
          local max_severity_per_line = {}
          for _, d in pairs(diagnostics) do
            local m = max_severity_per_line[d.lnum]
            if not m or d.severity < m.severity then
              max_severity_per_line[d.lnum] = d
            end
          end
          local filtered_diagnostics = vim.tbl_values(max_severity_per_line)
          show_handler(ns, bufnr, filtered_diagnostics, opts)
        end,
        hide = hide_handler,
      }

      local hover = vim.lsp.buf.hover
      ---@diagnostic disable-next-line: duplicate-set-field
      vim.lsp.buf.hover = function()
        local max_height = vim.fn.screenrow() == vim.o.scrolloff + 1 and vim.o.scrolloff - 1 or 8
        hover({
          anchor_bias = 'above',
          max_height = max_height,
          max_width = math.floor(vim.o.columns * 0.4),
        })
      end
      local signature_help = vim.lsp.buf.signature_help
      ---@diagnostic disable-next-line: duplicate-set-field
      vim.lsp.buf.signature_help = function()
        local max_height = vim.fn.screenrow() == vim.o.scrolloff + 1 and vim.o.scrolloff - 1 or 8
        signature_help({
          anchor_bias = 'above',
          max_height = max_height,
          max_width = math.floor(vim.o.columns * 0.4),
        })
      end

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
