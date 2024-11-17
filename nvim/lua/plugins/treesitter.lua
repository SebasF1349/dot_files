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
          'vimdoc',
          'vim',
          'bash',
          'hyprlang',
          'git_config',
          'gitcommit',
          'rasi',
          'readline',
          -- misc
          'sql',
          'regex',
          'diff',
          -- work
          'php',
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
              [']f'] = '@function.outer',
              [']c'] = '@class.outer',
              [']a'] = '@parameter.outer',
              [']o'] = '@block.outer',
              [']/'] = '@comment.outer',
            },
            goto_next_end = {
              [']F'] = '@function.outer',
              [']C'] = '@class.outer',
              [']A'] = '@parameter.outer',
              [']O'] = '@block.outer',
            },
            goto_previous_start = {
              ['[f'] = '@function.outer',
              ['[c'] = '@class.outer',
              ['[a'] = '@parameter.outer',
              ['[o'] = '@block.outer',
              ['[/'] = '@comment.outer',
            },
            goto_previous_end = {
              ['[F'] = '@function.outer',
              ['[C'] = '@class.outer',
              ['[A'] = '@parameter.outer',
              ['[O'] = '@block.outer',
            },
          },
          swap = {
            enable = true,
            swap_next = {
              ['<leader>a'] = '@parameter.inner',
            },
            swap_previous = {
              ['<leader>A'] = '@parameter.inner',
            },
          },
        },
      })

      local ts_repeat_move = require('nvim-treesitter.textobjects.repeatable_move')

      vim.keymap.set({ 'n', 'x', 'o' }, ';', ts_repeat_move.repeat_last_move)
      vim.keymap.set({ 'n', 'x', 'o' }, ',', ts_repeat_move.repeat_last_move_opposite)

      -- Optionally, make builtin f, F, t, T also repeatable with ; and ,
      vim.keymap.set({ 'n', 'x', 'o' }, 'f', ts_repeat_move.builtin_f_expr, { expr = true })
      vim.keymap.set({ 'n', 'x', 'o' }, 'F', ts_repeat_move.builtin_F_expr, { expr = true })
      vim.keymap.set({ 'n', 'x', 'o' }, 't', ts_repeat_move.builtin_t_expr, { expr = true })
      vim.keymap.set({ 'n', 'x', 'o' }, 'T', ts_repeat_move.builtin_T_expr, { expr = true })
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
}
