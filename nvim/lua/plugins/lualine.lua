return {
  -- Set lualine as statusline
  -- See `:help lualine.txt`
  'nvim-lualine/lualine.nvim',
  event = { 'BufReadPre', 'BufNewFile' },
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  opts = {
    options = {
      theme = 'catppuccin',
    },
  },
}
