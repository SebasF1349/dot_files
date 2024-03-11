return {
  "folke/flash.nvim",
  opts = {
    prompt = {
      -- Place the prompt above the statusline.
      win_config = { row = -2 },
    },
  },
  keys = {
    {
      "gj",
      mode = { "n", "x", "o" },
      function()
        require("flash").jump({
          remote_op = { restore = true, motion = true },
        })
      end,
      desc = "Flash Jump",
    },
    {
      "gt",
      mode = { "n", "x", "o" },
      function()
        require("flash").treesitter()
      end,
      desc = "Flash Treesitter Selection",
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
      desc = "Flash Treesitter Selection",
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
      desc = "Flash Treesitter Selection",
    },
  },
}
