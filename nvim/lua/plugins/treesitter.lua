return {
  {
    'nvim-treesitter/nvim-treesitter',
    event = { 'BufReadPost', 'BufNewFile' },
    build = ':TSUpdate',
    init = function(plugin)
      -- PERF: add nvim-treesitter queries to the rtp and it's custom query predicates early
      -- This is needed because a bunch of plugins no longer `require("nvim-treesitter")`, which
      -- no longer trigger the **nvim-treesitter** module to be loaded in time.
      -- Luckily, the only things that those plugins need are the custom queries, which we make available
      -- during startup.
      require('lazy.core.loader').add_to_rtp(plugin)
      require('nvim-treesitter.query_predicates')
    end,
    config = function()
      vim.filetype.add({
        extension = { rasi = 'rasi' },
        pattern = {
          ['.*/hypr/.*%.conf'] = 'hyprlang',
          ['.*/waybar/config'] = 'jsonc',
        },
      })

      require('nvim-treesitter.configs').setup({
        -- NOTE: maybe replace with a custom function to reduce startup time
        ensure_installed = {
          -- langs
          'c',
          'cpp',
          'go',
          'gomod',
          'gowork',
          'gosum',
          'lua',
          'python',
          'rust',
          'java',
          -- web
          'javascript',
          'typescript',
          'tsx',
          'css',
          'html',
          'svelte',
          -- config
          'json',
          'jsonc',
          'toml',
          'yaml',
          'markdown',
          'markdown_inline',
          -- specific config
          'bash',
          'hyprlang',
          'git_config',
          'gitcommit',
          'gitignore',
          'rasi',
          'readline',
          'powershell',
          'query',
          'vim',
          'vimdoc',
          -- misc
          'diff',
          'comment',
          'regex',
          'sql',
          -- work
          'php',
          'phpdoc',
        },
        auto_install = true,
        sync_install = false,
        ignore_install = {},
        modules = {},
        highlight = { enable = true },
        -- indent = { enable = true }, -- doesn't work properly
      })

      -- can use ['az'] = { query = '@fold', query_group = 'folds' , silent =true }, but needs an offset for iz
      -- more robust option (do I want the if/else behaviour?) : https://vimways.org/2018/transactions-pending/
      vim.keymap.set('v', 'iz', ':<C-U>silent! normal! [zjV]zk<CR>', { desc = 'Fold Text-Object', silent = true })
      vim.keymap.set('o', 'iz', '<cmd>normal Viz<CR>', { desc = 'Fold Text-Object', remap = false, silent = true })
      vim.keymap.set('v', 'az', ':<C-U>silent! normal! [zV]z<CR>', { desc = 'Fold Text-Object', silent = true })
      vim.keymap.set('o', 'az', '<cmd>normal Vaz<CR>', { desc = 'Fold Text-Object', remap = false, silent = true })

      vim.api.nvim_set_hl(0, '@lsp.type.comment', {})

      local function enable_foldexpr(bufnr)
        if vim.api.nvim_buf_line_count(bufnr) > 40000 then
          return
        end
        vim.api.nvim_buf_call(bufnr, function()
          vim.wo[0][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
          vim.wo[0][0].foldmethod = 'expr'
          vim.cmd.normal('zx')
        end)
      end

      vim.api.nvim_create_autocmd('FileType', {
        callback = function(args)
          if not pcall(vim.treesitter.start, args.buf) then
            return
          end

          enable_foldexpr(args.buf)
        end,
      })
    end,
  },
  {
    'aaronik/treewalker.nvim',
    event = { 'BufReadPost', 'BufNewFile' },
    config = function()
      local treewalker = require('treewalker')
      treewalker.setup({
        highlight = true, -- Whether to briefly highlight the node after jumping to it
        highlight_duration = 250, -- How long should above highlight last (in ms)
      })

      vim.keymap.set({ 'n', 'v' }, '<A-k>', '<cmd>Treewalker Up<cr>zz', { silent = true })
      vim.keymap.set({ 'n', 'v' }, '<A-j>', '<cmd>Treewalker Down<cr>zz', { silent = true })
      vim.keymap.set({ 'n', 'v' }, '<A-l>', '<cmd>Treewalker Right<cr>zz', { silent = true })
      vim.keymap.set({ 'n', 'v' }, '<A-h>', '<cmd>Treewalker Left<cr>zz', { silent = true })
      vim.keymap.set('n', '<A-K>', '<cmd>Treewalker SwapUp<cr>zz', { silent = true })
      vim.keymap.set('n', '<A-J>', '<cmd>Treewalker SwapDown<cr>zz', { silent = true })
      vim.keymap.set('n', '<A-L>', '<cmd>Treewalker SwapRight<CR>zz', { silent = true })
      vim.keymap.set('n', '<A-H>', '<cmd>Treewalker SwapLeft<CR>zz', { silent = true })

      -- Text-Objects
      local targets = require('treewalker.targets')
      local nodes = require('treewalker.nodes')
      local function nodeMoveTextObject(target)
        if not target then
          return
        end
        local start_row, _, end_row, _ = target:range(false)
        vim.cmd('normal! V' .. start_row + 1 .. 'ggo' .. end_row + 1 .. 'gg')
      end

      vim.keymap.set('v', 'on', function()
        vim.cmd('normal! ^')
        local node = nodes.get_current()
        local target = targets.out(node)
        nodeMoveTextObject(target)
      end, { desc = 'Out Node Text-Object', silent = true })
      vim.keymap.set('o', 'on', '<cmd>normal von<CR>', { desc = '[O]ut [N]ode Text-Object', silent = true })

      vim.keymap.set('v', 'in', function()
        vim.cmd('normal! ^')
        local target = targets.inn()
        nodeMoveTextObject(target)
      end, { desc = 'In Node Text-Object', silent = true })
      vim.keymap.set('o', 'in', '<cmd>normal vin<CR>', { desc = '[I]n [N]ode Text-Object', silent = true })

      vim.keymap.set('v', 'un', function()
        vim.cmd('normal! ^')
        local target = targets.up()
        nodeMoveTextObject(target)
      end, { desc = 'Up Node Text-Object', silent = true })
      vim.keymap.set('o', 'un', '<cmd>normal vun<CR>', { desc = '[U]p [N]ode Text-Object', silent = true })

      vim.keymap.set('v', 'dn', function()
        vim.cmd('normal! ^')
        local target = targets.down()
        nodeMoveTextObject(target)
      end, { desc = 'Down Node Text-Object', silent = true })
      vim.keymap.set('o', 'dn', '<cmd>normal vdn<CR>', { desc = '[D]own [N]ode Text-Object', silent = true })

      vim.keymap.set('v', 'an', function()
        vim.cmd('normal! ^')
        local target = nodes.get_current()
        nodeMoveTextObject(target)
      end, { desc = 'Around Current Node Text-Object', silent = true })
      vim.keymap.set('o', 'an', '<cmd>normal van<CR>', { desc = '[A]round Current [N]ode Text-Object', silent = true })
    end,
  },
}
