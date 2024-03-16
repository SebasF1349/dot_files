-- Fuzzy Finder (files, lsp, etc)
return {
  "nvim-telescope/telescope.nvim",
  keys = "<leader>",
  branch = "0.1.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    {
      "nvim-telescope/telescope-fzf-native.nvim",
      build = "make",
      cond = function()
        return vim.fn.executable("make") == 1
      end,
    },
    "nvim-telescope/telescope-ui-select.nvim",
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    local telescope = require("telescope")
    local builtin = require("telescope.builtin")

    telescope.setup({
      defaults = {
        layout_strategy = "flex",
        layout_config = {
          horizontal = {
            width = 0.9,
            height = 0.9,
            preview_cutoff = 0,
          },
          vertical = {
            width = 0.9,
            height = 0.9,
            preview_cutoff = 0,
          },
        },
      },
      extensions = {
        ["ui-select"] = {
          require("telescope.themes").get_dropdown(),
        },
      },
    })

    -- Enable telescope extensions, if installed
    telescope.load_extension("fzf")
    telescope.load_extension("ui-select")

    -- Browsing
    vim.keymap.set("n", "<leader>ff", Telescope_git_or_files, { desc = "[F]ind [F]iles" })
    vim.keymap.set("n", "<leader><leader>", function()
      builtin.buffers({ sort_mru = true, ignore_current_buffer = true })
    end, { desc = "Find another [ ] opened buffers" })

    -- Searching
    vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "[F]ind by [G]rep" })
    vim.keymap.set("n", "<leader>/", builtin.current_buffer_fuzzy_find, { desc = "Find [/] in current buffer" })
    vim.keymap.set("n", "<leader>f/", function()
      builtin.live_grep({
        grep_open_files = true,
        prompt_title = "Live Grep in Open Buffers",
      })
    end, { desc = "[F]ind [/] in Open Buffers" })
    vim.keymap.set("n", "<leader>fw", builtin.grep_string, { desc = "[F]ind current [W]ord" })
    vim.keymap.set("n", "<leader>fW", function()
      local word = vim.fn.expand("<cWORD>")
      builtin.grep_string({ search = word })
    end, { desc = "[F]ind current [W]ORD until space" })
    vim.keymap.set("v", "<leader>fs", function()
      local visual_selection = vim.fn.getregion(vim.fn.getpos("."), vim.fn.getpos("v"), { mode = vim.fn.mode() })
      require("telescope.builtin").live_grep({
        default_text = vim.fn.escape(table.concat(visual_selection), ".()"),
      })
    end, { desc = "[F]ind [S]elected Text" })

    -- Miscelaneous
    vim.keymap.set("n", "<leader>ft", function()
      builtin.grep_string({ search = "(note|todo|fix):", use_regex = true })
    end, { desc = "[F]ind [T]odos or Notes" })
    vim.keymap.set("n", "<leader>fd", builtin.diagnostics, { desc = "[F]ind [D]iagnostics" })
    vim.keymap.set("n", "<leader>fr", builtin.resume, { desc = "[F]ind [R]esume" })
    vim.keymap.set("n", "<leader>fb", builtin.git_branches, { desc = "[F]ind Git [B]ranch" })
    vim.keymap.set("n", "<leader>fp", builtin.registers, { desc = "[F]ind Register to [P]aste" })
    vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "[F]ind [H]elp" })
  end,
}
