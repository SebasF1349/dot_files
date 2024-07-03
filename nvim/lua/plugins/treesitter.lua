return {
  'nvim-treesitter/nvim-treesitter',
  event = { 'BufReadPost', 'BufNewFile' },
  build = ':TSUpdate',
  config = function()
    require('nvim-treesitter.install').prefer_git = true

    vim.filetype.add({
      extension = { rasi = 'rasi' },
      pattern = {
        ['.*/hypr/.*%.conf'] = 'hyprlang',
        ['.*/waybar/config'] = 'jsonc',
      },
    })

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
      },
      auto_install = true,
      sync_install = false,
      ignore_install = {},
      modules = {},
      highlight = { enable = true },
      -- indent = { enable = true }, -- doesn't work properly
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = 'gn',
          node_incremental = 'gn',
          scope_incremental = 'gs',
          node_decremental = 'gr',
        },
      },
    })
  end,
}
