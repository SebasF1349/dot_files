return {
  { 'tpope/vim-fugitive', cmd = 'G' },

  { 'NMAC427/guess-indent.nvim', event = 'InsertEnter', opts = {} },

  {
    'saecki/crates.nvim',
    ft = { 'rust', 'toml' },
    config = function(_, opts)
      local crates = require('crates')
      crates.setup(opts)
      crates.show()
    end,
  },

  {
    -- improve wordwise-movements to skip insignificant punctuation
    -- note that it changes how [d|c|y]w work, use [d|c|y]iw
    'chrisgrieser/nvim-spider',
    keys = {
      {
        'w',
        "<cmd>lua require('spider').motion('w')<CR>", -- using lua breaks dot-repeaetebility
        mode = { 'n', 'o', 'x' },
      },
      {
        'e',
        "<cmd>lua require('spider').motion('e')<CR>",
        mode = { 'n', 'o', 'x' },
      },
      {
        'b',
        "<cmd>lua require('spider').motion('b')<CR>",
        mode = { 'n', 'o', 'x' },
      },
    },
    opts = {
      skipInsignificantPunctuation = true,
      consistentOperatorPending = false,
      subwordMovement = false, -- don't needed with mini.ai subword textobject
    },
  },
}
