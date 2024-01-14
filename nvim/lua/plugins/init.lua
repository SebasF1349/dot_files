return {
  -- Git related plugins
  "tpope/vim-fugitive",
  "tpope/vim-rhubarb",

  -- Detect tabstop and shiftwidth automatically
  "tpope/vim-sleuth",

  -- shows first unique letter of each word
  {
    "jinh0/eyeliner.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = { highlight_on_key = true },
  },

  -- "gc" to comment visual regions/lines
  {
    "numToStr/Comment.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {},
  },
}
