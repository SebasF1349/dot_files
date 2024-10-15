return {
  {
    'nvim-treesitter/nvim-treesitter',
    event = { 'BufReadPost', 'BufNewFile' },
    build = ':TSUpdate',
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
