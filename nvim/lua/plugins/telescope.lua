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

    -- See `:help telescope.builtin`
    vim.keymap.set("n", "<leader>?", builtin.oldfiles, { desc = "[?] Find recently opened files" })
    -- vim.keymap.set("n", "<leader><space>", builtin.buffers, { desc = "[ ] Find existing buffers" })
    vim.keymap.set("n", "<leader><leader>", function()
      builtin.buffers({ sort_mru = true, ignore_current_buffer = true })
    end, { desc = "[ ] Find another opened buffers" })
    vim.keymap.set("n", "<leader>/", builtin.current_buffer_fuzzy_find, { desc = "[/] Fuzzily search in current buffer" })

    local function telescope_live_grep_open_files()
      builtin.live_grep({
        grep_open_files = true,
        prompt_title = "Live Grep in Open Files",
      })
    end

    vim.keymap.set("n", "<leader>f/", telescope_live_grep_open_files, { desc = "[F]ind [/] in Open Files" })
    vim.keymap.set("n", "<leader>fs", builtin.builtin, { desc = "[F]ind [S]elect Telescope" })
    vim.keymap.set("n", "<leader>gf", builtin.git_files, { desc = "Find [G]it [F]iles" })
    vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "[F]ind [F]iles" })
    vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "[F]ind [H]elp" })
    vim.keymap.set("n", "<leader>fw", builtin.grep_string, { desc = "[F]ind current [W]ord" })
    vim.keymap.set("n", "<leader>fW", function()
      local word = vim.fn.expand("<cWORD>")
      builtin.grep_string({ search = word })
    end, { desc = "[F]ind current [W]ORD until space" })
    vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "[F]ind by [G]rep" })
    vim.keymap.set("n", "<leader>fd", builtin.diagnostics, { desc = "[F]ind [D]iagnostics" })
    vim.keymap.set("n", "<leader>fr", builtin.resume, { desc = "[F]ind [R]esume" })
  end,
}
