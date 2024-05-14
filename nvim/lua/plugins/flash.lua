return {
  "folke/flash.nvim",
  keys = {
    { "f", mode = { "n", "x", "o" } },
    { "F", mode = { "n", "x", "o" } },
    { "t", mode = { "n", "x", "o" } },
    { "T", mode = { "n", "x", "o" } },
    {
      "s",
      mode = { "n", "x", "o" },
      function()
        require("flash").jump({
          remote_op = { restore = true, motion = true },
        })
      end,
      desc = "Fla[S]h Jump",
    },
    {
      "S",
      mode = { "n", "x", "o" },
      function()
        require("flash").treesitter()
      end,
      desc = "Flash Treesitter [S]election",
    },
    {
      "gs",
      mode = { "n", "x", "o" },
      function()
        require("flash").treesitter({
          jump = { pos = "start" },
          label = { before = true, after = false },
        })
      end,
      desc = "Flash Treesitter [G]o [S]tart",
    },
    {
      "ge",
      mode = { "n", "x", "o" },
      function()
        require("flash").treesitter({
          jump = { pos = "end" },
          label = { before = false, after = true },
        })
      end,
      desc = "Flash Treesitter [G]o [E]nd",
    },
  },
}
