return {
  "folke/flash.nvim",
  event = "VeryLazy",
  opts = {
    prompt = {
      -- Place the prompt above the statusline.
      win_config = { row = -2 },
    },
  },
  keys = {
    {
      "s",
      mode = { "n", "x", "o" },
      function()
        require("flash").jump()
      end,
      desc = "Flash",
    },
  },
}
