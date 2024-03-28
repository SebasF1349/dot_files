return {
  { "tpope/vim-fugitive", cmd = "G" },

  -- Detect tabstop and shiftwidth automatically
  { "NMAC427/guess-indent.nvim", event = "InsertEnter", opts = {} },

  {
    "m4xshen/hardtime.nvim",
    dependencies = { "MunifTanjim/nui.nvim", "nvim-lua/plenary.nvim" },
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      hint = true,
      notification = false,
      disabled_filetypes = {
        "TelescopePrompt",
        "checkhealth",
        "dapui-repl",
        "dapui_breakpoints",
        "dapui_console",
        "dapui_scopes",
        "dapui_stacks",
        "dapui_watches",
        "help",
        "lazy",
        "mason",
        "netrw",
        "prompt",
        "qf",
        "Trouble",
        "fugitive",
      },
    },
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
