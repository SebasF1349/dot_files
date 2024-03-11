return {
  "nvim-treesitter/nvim-treesitter",
  event = { "BufReadPost", "BufNewFile" },
  dependencies = {
    "nvim-treesitter/nvim-treesitter-textobjects",
    "windwp/nvim-ts-autotag",
    {
      "nvim-treesitter/nvim-treesitter-context",
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
    },
  },
  build = ":TSUpdate",
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
        textobjects = {
          select = {
            enable = true,
            lookahead = true, -- automatically jump forward to textobj, similar to targets.vim
            keymaps = {
              -- you can use the capture groups defined in textobjects.scm
              ["af"] = "@function.outer",
              ["if"] = "@function.inner",
              ["aa"] = "@parameter.outer",
              ["ia"] = "@parameter.inner",
              -- ["ac"] = "@class.outer",
              -- ["ic"] = "@class.inner",
              ["ab"] = "@block.outer",
              ["ib"] = "@block.inner",
              ["al"] = "@loop.outer",
              ["il"] = "@loop.inner",
              ["ac"] = "@conditional.outer",
              ["ic"] = "@conditional.inner",
              ["a/"] = "@comment.outer",
              ["i/"] = "@comment.outer", -- inner doesn't make sense
            },
          },
          move = {
            enable = true,
            set_jumps = true, -- whether to set jumps in the jumplist
            goto_next_start = {
              ["]/"] = "@comment.outer",
            },
            goto_previous_start = {
              ["[/"] = "@comment.outer",
            },
            goto_next = {
              ["]f"] = "@function.outer",
              ["]a"] = "@parameter.inner",
              ["]b"] = "@block.outer",
              ["]l"] = "@loop.outer",
              ["]c"] = "@conditional.outer",
              -- ["]["] = "@class.outer",
            },
            goto_previous = {
              ["[f"] = "@function.outer",
              ["[a"] = "@parameter.inner",
              ["[b"] = "@block.outer",
              ["[l"] = "@loop.outer",
              ["[c"] = "@conditional.outer",
              -- ["[["] = "@class.outer",
            },
          },
          swap = {
            enable = true,
            swap_next = {
              ["<leader>a"] = "@parameter.inner",
            },
            swap_previous = {
              ["<leader>A"] = "@parameter.inner",
            },
          },
        },

        autotag = {
          enable = true,
          enable_rename = true,
          enable_close = true,
          enable_close_on_slash = true,
        },
      })
    end, 0)
  end,
}
