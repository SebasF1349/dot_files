return {
  'folke/flash.nvim',
  -- stylua: ignore
  keys = {
    { "f", mode = { "n", "x", "o" } },
    { "F", mode = { "n", "x", "o" } },
    { "t", mode = { "n", "x", "o" } },
    { "T", mode = { "n", "x", "o" } },
  },
  opts = {
    modes = {
      char = {
        enabled = false,
      },
    },
  },
}
