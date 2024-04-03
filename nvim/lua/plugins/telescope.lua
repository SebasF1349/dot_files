return {
  "nvim-telescope/telescope.nvim",
  keys = { "<leader>f", "<leader><leader>", "<leader>/" },
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
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    local telescope = require("telescope")

    telescope.setup({
      defaults = {
        vimgrep_arguments = {
          "rg",
          "--color=never",
          "--no-heading",
          "--with-filename",
          "--line-number",
          "--column",
          "--smart-case",
          "--trim",
        },
        prompt_prefix = " ",
        selection_caret = " ",
        dynamic_preview_title = true,
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
        file_ignore_patterns = {
          "%.jpg",
          "%.jpeg",
          "%.png",
          "%.otf",
          "%.ttf",
          "%.DS_Store",
          "%.git/",
          "%.mypy_cache/",
          "dist/",
          "node_modules/",
          "site-packages/",
          "__pycache__/",
          "migrations/",
          "package-lock.json",
          "yarn.lock",
          "pnpm-lock.yaml",
        },
      },
    })

    -- Enable telescope extensions, if installed
    telescope.load_extension("fzf")

    local customPickers = require("utils.telescopePickers")

    -- Browsing
    vim.keymap.set("n", "<leader>ff", require("utils.telescopeFiles").Telescope_git_or_files, { desc = "[F]ind [F]iles" })
    vim.keymap.set("n", "<leader><leader>", function()
      customPickers.prettyBuffersPicker({ sort_mru = true, ignore_current_buffer = true })
    end, { desc = "Find another [ ] opened buffers" })

    -- Searching
    vim.keymap.set("n", "<leader>fg", function()
      customPickers.prettyGrepPicker({ picker = "live_grep" })
    end, { desc = "[F]ind by [G]rep" })
    vim.keymap.set("n", "<leader>/", function()
      customPickers.prettyGrepPicker({
        picker = "live_grep",
        options = {
          search_dirs = { vim.api.nvim_buf_get_name(0) },
          prompt_title = "Live Grep in Current Buffer",
        },
      })
    end, { desc = "Find [/] in Current Buffer" })
    vim.keymap.set("n", "<leader>f/", function()
      customPickers.prettyGrepPicker({
        picker = "live_grep",
        options = {
          grep_open_files = true,
          prompt_title = "Live Grep in Open Buffers",
        },
      })
    end, { desc = "[F]ind [/] in Open Buffers" })
    vim.keymap.set("n", "<leader>fw", function()
      customPickers.prettyGrepPicker({ picker = "grep_string" })
    end, { desc = "[F]ind current [W]ord" })
    vim.keymap.set("n", "<leader>fW", function()
      local word = vim.fn.expand("<cWORD>")
      customPickers.prettyGrepPicker({ picker = "grep_string", options = { search = word } })
    end, { desc = "[F]ind current [W]ORD until space" })
    vim.keymap.set("v", "<leader>fs", function()
      local visual_selection = vim.fn.getregion(vim.fn.getpos("."), vim.fn.getpos("v"), { mode = vim.fn.mode() })
      customPickers.prettyGrepPicker({ picker = "live_grep", options = {
        default_text = vim.fn.escape(table.concat(visual_selection), ".()"),
      } })
    end, { desc = "[F]ind [S]elected Text" })

    local builtin = require("telescope.builtin")
    -- Miscelaneous
    vim.keymap.set("n", "<leader>ft", function()
      customPickers.prettyGrepPicker({ picker = "grep_string", options = { search = "(note|todo|fix):", use_regex = true } })
    end, { desc = "[F]ind [T]odos or Notes" })
    vim.keymap.set("n", "<leader>fd", builtin.diagnostics, { desc = "[F]ind [D]iagnostics" })
    vim.keymap.set("n", "<leader>fb", builtin.git_branches, { desc = "[F]ind Git [B]ranch" })
    vim.keymap.set("n", "<leader>fs", builtin.git_status, { desc = "[F]ind Git [S]tatus" })
    vim.keymap.set("n", "<leader>fp", builtin.registers, { desc = "[F]ind Register to [P]aste" })
    vim.keymap.set("n", "<leader>fr", builtin.resume, { desc = "[F]ind [R]esume" })
    vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "[F]ind [H]elp" })
  end,
}
