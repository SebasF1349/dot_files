return {
  -- Git related plugins
  { "tpope/vim-fugitive", cmd = "G" },

  -- Detect tabstop and shiftwidth automatically
  { "NMAC427/guess-indent.nvim", opts = {} },

  {
    "m4xshen/hardtime.nvim",
    dependencies = { "MunifTanjim/nui.nvim", "nvim-lua/plenary.nvim" },
    event = { "BufReadPre", "BufNewFile" },
    opts = {},
  },

  {
    "saecki/crates.nvim",
    ft = { "rust", "toml" },
    config = function(_, opts)
      local crates = require("crates")
      crates.setup(opts)
      crates.show()
    end,
  },
}
