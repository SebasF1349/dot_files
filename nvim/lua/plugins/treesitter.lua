return {
  "nvim-treesitter/nvim-treesitter",
  event = { "BufReadPost", "BufNewFile" },
  build = ":TSUpdate",
  dependencies = { "andymass/vim-matchup", opts = {} },
  config = function()
    vim.filetype.add({
      extension = { rasi = "rasi" },
      pattern = {
        [".*/hypr/.*%.conf"] = "hyprlang",
        [".*/waybar/config"] = "jsonc",
      },
    })

    require("nvim-treesitter.configs").setup({
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
        "java",
        "vimdoc",
        "vim",
        "bash",
        "css",
        "html",
        "svelte",
        "json",
        "jsonc",
        "toml",
        "markdown",
        "markdown_inline",
        "regex",
        "hyprlang",
        "git_config",
        "dockerfile",
        "sql",
        "rasi",
        "readline",
        "yaml",
      },

      auto_install = true,
      sync_install = false,
      ignore_install = {},
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
      matchup = { enable = true },
    })
  end,
}
