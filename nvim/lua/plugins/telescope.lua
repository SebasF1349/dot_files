return {
  "nvim-telescope/telescope.nvim",
  keys = { "<leader>f", "<leader><leader>", "<leader>/" },
  -- branch = "0.1.x",
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
    "nvim-telescope/telescope-ui-select.nvim",
  },
  config = function()
    local telescope = require("telescope")
    local actions = require("telescope.actions")
    local actions_state = require("telescope.actions.state")

    telescope.setup({
      defaults = {
        mappings = {
          i = {
            ["<leader>q"] = function(bufnr)
              local picker = actions_state.get_current_picker(bufnr)
              if #picker:get_multi_selection() > 0 then
                actions.send_selected_to_qflist(bufnr)
                actions.open_qflist(bufnr)
              else
                actions.send_to_qflist(bufnr)
                actions.open_qflist(bufnr)
              end
            end,
          },
        },
        prompt_prefix = " ",
        selection_caret = " ",
        dynamic_preview_title = true,
        path_display = { "filename_first" },
        layout_strategy = "flex",
        layout_config = {
          horizontal = {
            width = 0.95,
            height = 0.95,
            preview_cutoff = 0,
          },
          vertical = {
            width = 0.95,
            height = 0.95,
            padding = 0,
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
        extensions = {
          ["ui-select"] = {
            require("telescope.themes").get_dropdown({}),
          },
        },
      },
    })

    -- Enable telescope extensions, if installed
    telescope.load_extension("fzf")
    telescope.load_extension("ui-select")

    local builtin = require("telescope.builtin")

    -- Browsing
    vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "[F]ind [F]iles" })
    vim.keymap.set("n", "<leader><leader>", builtin.buffers, { desc = "Find another [ ] opened buffers" })

    -- Searching
    vim.keymap.set("n", "<leader>fg", function()
      builtin.live_grep({ disable_coordinates = true })
    end, { desc = "[F]ind by [G]rep" })
    vim.keymap.set("n", "<leader>/", function()
      builtin.live_grep({
        disable_coordinates = true,
        search_dirs = { vim.api.nvim_buf_get_name(0) },
        prompt_title = "Live Grep in Current Buffer",
      })
    end, { desc = "Find [/] in Current Buffer" })
    vim.keymap.set("n", "<leader>f/", function()
      builtin.live_grep({
        disable_coordinates = true,
        grep_open_files = true,
        prompt_title = "Live Grep in Open Buffers",
      })
    end, { desc = "[F]ind [/] in Open Buffers" })
    vim.keymap.set("n", "<leader>fw", builtin.grep_string, { desc = "[F]ind current [W]ord" })
    vim.keymap.set("v", "<leader>fs", function()
      local visual_selection = vim.fn.getregion(vim.fn.getpos("."), vim.fn.getpos("v"), { mode = vim.fn.mode() })
      builtin.live_grep({
        disable_coordinates = true,
        default_text = vim.fn.escape(table.concat(visual_selection), ".(){}"),
      })
    end, { desc = "[F]ind [S]elected Text" })

    -- Miscelaneous
    vim.keymap.set("n", "<leader>fn", function()
      builtin.grep_string({
        disable_coordinates = true,
        search = "(note|todo|fix):",
        use_regex = true,
      })
    end, { desc = "[F]ind [N]otes" })
    vim.keymap.set("n", "<leader>fd", builtin.diagnostics, { desc = "[F]ind [D]iagnostics" })
    vim.keymap.set("n", "<leader>fb", builtin.git_branches, { desc = "[F]ind Git [B]ranch" })
    vim.keymap.set("n", "<leader>fs", builtin.git_status, { desc = "[F]ind Git [S]tatus" })
    vim.keymap.set("n", "<leader>fp", builtin.registers, { desc = "[F]ind Register to [P]aste" })
    vim.keymap.set("n", "<leader>fr", builtin.resume, { desc = "[F]ind [R]esume" })
    vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "[F]ind [H]elp" })
  end,
}
