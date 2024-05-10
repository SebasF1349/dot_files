return {
  { "tpope/vim-fugitive", cmd = "G" },

  { "NMAC427/guess-indent.nvim", event = "InsertEnter", opts = {} },

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
