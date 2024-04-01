return {
  { "tpope/vim-fugitive", cmd = "G" },

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

  {
    "aznhe21/actions-preview.nvim",
    keys = { "<leader>c" },
    config = function()
      require("actions-preview").setup({
        backend = { "telescope" },
        telescope = {
          dynamic_preview_title = false,
          sorting_strategy = "ascending",
          layout_strategy = "vertical",
          layout_config = {
            width = 0.8,
            height = 0.9,
            prompt_position = "top",
            preview_cutoff = 20,
            preview_height = function(_, _, max_lines)
              return max_lines - 15
            end,
          },
        },
      })
      vim.keymap.set({ "v", "n" }, "<leader>ca", require("actions-preview").code_actions, { desc = "LSP:[C]ode [A]ction" })
    end,
  },
}
