return {
  {
    'danymat/neogen',
    keys = {
      { 'gd', "<cmd>lua require('neogen').generate()<CR>", desc = 'Add [D]ocs' },
    },
    opts = { snippet_engine = 'nvim' },
  },

  { 'artemave/workspace-diagnostics.nvim' },

  {
    'echasnovski/mini.splitjoin',
    keys = { '<leader>j' },
    opts = { mappings = { toggle = '<leader>j', split = '', join = '' } },
  },
}
