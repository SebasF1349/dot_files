return {
  "nvim-treesitter/nvim-treesitter-context",
  event = { "BufReadPre", "BufNewFile" },
  keys = {
    {
      "[s",
      function()
        -- Jump to previous change when in diffview.
        if vim.wo.diff then
          return "[c"
        else
          vim.schedule(function()
            require("treesitter-context").go_to_context()
          end)
          return "<Ignore>"
        end
      end,
      desc = "Jump to upper context [s]tart",
      expr = true,
    },
  },
  opts = {
    max_lines = 2,
    multiline_threshold = 1,
    min_window_height = 20,
    separator = "—",
  },
}
