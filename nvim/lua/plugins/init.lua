return {
  -- Git related plugins
  { "tpope/vim-fugitive", cmd = "G" },

  -- Detect tabstop and shiftwidth automatically
  { "NMAC427/guess-indent.nvim", opts = {} },

  -- Highlight todo, notes, etc in comments
  {
    "folke/todo-comments.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local todo = require("todo-comments")
      todo.setup({ signs = false })

      vim.keymap.set("n", "]t", function()
        todo.jump_next()
      end, { desc = "Next todo comment" })
      vim.keymap.set("n", "[t", function()
        todo.jump_prev()
      end, { desc = "Previous todo comment" })
    end,
  },

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
