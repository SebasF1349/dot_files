return {
  {
    'nvim-treesitter/nvim-treesitter',
    event = { 'BufReadPost', 'BufNewFile' },
    dependencies = { 'nvim-treesitter/nvim-treesitter-textobjects' },
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
        matchup = { enable = true },
        textobjects = {
          select = {
            enable = true,
            lookahead = true,
            keymaps = {
              ['io'] = '@block.inner',
              ['ao'] = '@block.outer',
              ['af'] = '@function.outer',
              ['if'] = '@function.inner',
              ['au'] = '@call.outer',
              ['iu'] = '@call.inner',
              ['ac'] = '@class.outer',
              ['ic'] = '@class.inner',
              ['aa'] = '@parameter.outer',
              ['ia'] = '@parameter.inner',
              ['a='] = '@assignment.outer',
              ['i='] = '@assignment.inner',
              ['l='] = '@assignment.lhs',
              ['r='] = '@assignment.rhs',
              ['a/'] = '@comment.outer',
              ['i/'] = '@comment.inner', -- Only added inner for lua, add for other languages
              ['aq'] = '@quote.outer',
              ['iq'] = '@quote.inner',
              -- ['ab'] = '@bracket.outer', -- Need more work, they are used in many cases
              -- ['ib'] = '@bracket.inner',
            },
          },
          move = {
            enable = true,
            goto_next_start = {
              ['],'] = '@parameter.outer',
              [']/'] = '@comment.outer',
            },
            goto_previous_start = {
              ['[,'] = '@parameter.outer',
              ['[/'] = '@comment.outer',
            },
          },
        },
      })

      local ts_repeat_move = require('nvim-treesitter.textobjects.repeatable_move')

      vim.keymap.set({ 'n', 'x', 'o' }, ';', ts_repeat_move.repeat_last_move)
      vim.keymap.set({ 'n', 'x', 'o' }, ',', ts_repeat_move.repeat_last_move_opposite)

      vim.keymap.set({ 'n', 'x', 'o' }, 'f', ts_repeat_move.builtin_f_expr, { expr = true })
      vim.keymap.set({ 'n', 'x', 'o' }, 'F', ts_repeat_move.builtin_F_expr, { expr = true })
      vim.keymap.set({ 'n', 'x', 'o' }, 't', ts_repeat_move.builtin_t_expr, { expr = true })
      vim.keymap.set({ 'n', 'x', 'o' }, 'T', ts_repeat_move.builtin_T_expr, { expr = true })

      -- More Text-Objects
      local sub_word_limiters = {
        '%u[%l%d]+%f[^%l%d]',
        '%f[%S][%l%d]+%f[^%l%d]',
        '%f[%P][%l%d]+%f[^%l%d]',
        '^[%l%d]+%f[^%l%d]',
      }

      ---@param type 'i' | 'a'
      function _G.subWord(type)
        local cursor_pos = vim.api.nvim_win_get_cursor(0)
        local line = vim.api.nvim_get_current_line()
        local start, ending = math.huge, math.huge
        for _, pattern in ipairs(sub_word_limiters) do
          ---@type number|nil, number|nil
          local s, e = 0, 0
          repeat
            s = s + 1
            s, e = line:find(pattern, s)
            local standingOnOrInFront = e and e > cursor_pos[2]
          until standingOnOrInFront or not s

          if s and e and s > 0 and s < start then
            start, ending = s, e
          end
        end
        vim.api.nvim_win_set_cursor(0, { cursor_pos[1], start - 1 })
        if vim.api.nvim_get_mode().mode:find('v') then
          vim.cmd.normal({ 'o', bang = true })
        else
          vim.cmd.normal({ 'v', bang = true })
        end
        if type == 'a' and vim.list_contains({ '_', '-' }, line:sub(ending + 1, ending + 1)) then
          vim.api.nvim_win_set_cursor(0, { cursor_pos[1], ending })
        else
          vim.api.nvim_win_set_cursor(0, { cursor_pos[1], ending - 1 })
        end
      end

      vim.keymap.set('v', 'ie', ':<C-U>lua _G.subWord("i")<CR>', { desc = 'SubWord Text-Object', silent = true })
      vim.keymap.set('o', 'ie', '<cmd>normal vie<CR>', { desc = 'SubWord Text-Object', silent = true })
      vim.keymap.set('v', 'ae', ':<C-U>lua _G.subWord("a")<CR>', { desc = 'SubWord Text-Object', silent = true })
      vim.keymap.set('o', 'ae', '<cmd>normal vae<CR>', { desc = 'SubWord Text-Object', silent = true })

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
    'andymass/vim-matchup',
    event = { 'BufReadPost', 'BufNewFile' },
    -- how to lazy load matchup?, I only really need it when pressing % but using % as trigger doesn't work
    init = function()
      vim.g.matchup_matchparen_offscreen = {}
      vim.g.matchup_matchparen_enabled = 0
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
