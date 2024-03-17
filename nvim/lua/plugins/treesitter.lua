return {
  "nvim-treesitter/nvim-treesitter",
  event = { "BufReadPost", "BufNewFile" },
  build = "<cmd>TSUpdate",
  config = function()
    vim.defer_fn(function()
      require("nvim-treesitter.configs").setup({
        -- Add languages to be installed here that you want installed for treesitter
        ensure_installed = {
          "c",
          "cpp",
          "go",
          "lua",
          "python",
          "rust",
          "tsx",
          "javascript",
          "typescript",
          "vimdoc",
          "vim",
          "bash",
          "css",
          "html",
          "svelte",
          "json",
          "toml",
          "markdown",
          "markdown_inline",
          "regex",
        },

        -- Autoinstall languages that are not installed. Defaults to false (but you can change for yourself!)
        auto_install = true,
        -- Install languages synchronously (only applied to `ensure_installed`)
        sync_install = false,
        -- List of parsers to ignore installing
        ignore_install = {},
        -- You can specify additional Treesitter modules here: -- For example: -- playground = {--enable = true,-- },
        modules = {},

        highlight = { enable = true },
        -- indent = { enable = true }, -- doesn't work properly
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = "gn",
            node_incremental = "gn",
            scope_incremental = "gs",
            node_decremental = "gr",
          },
        },
      })
    end, 0)
  end,
}
