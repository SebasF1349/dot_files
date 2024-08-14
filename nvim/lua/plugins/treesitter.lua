return {
  'nvim-treesitter/nvim-treesitter',
  event = { 'BufReadPost', 'BufNewFile' },
  dependencies = {
    'andymass/vim-matchup', --better %
  },
  build = ':TSUpdate',
  config = function()
    vim.filetype.add({
      extension = { rasi = 'rasi' },
      pattern = {
        ['.*/hypr/.*%.conf'] = 'hyprlang',
        ['.*/waybar/config'] = 'jsonc',
      },
    })

    vim.g.matchup_matchparen_offscreen = {}
    vim.g.matchup_surround_enabled = 1 -- NOTE: is it better than just cs({ ?

    require('nvim-treesitter.configs').setup({
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
  end,
}
