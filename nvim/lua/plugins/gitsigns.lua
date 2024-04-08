return {
  -- Adds git related signs to the gutter, as well as utilities for managing changes
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    signs = {
      add = { text = "▎" },
      change = { text = "▎" },
      delete = { text = "" },
      topdelete = { text = "" },
      changedelete = { text = "▎" },
      untracked = { text = "▎" },
    },
    preview_config = { border = "rounded" },
    on_attach = function()
      local gitsigns = require("gitsigns")

      -- Navigation
      vim.keymap.set("n", "]h", function()
        if vim.wo.diff then
          vim.cmd.normal({ "]c", bang = true })
        else
          gitsigns.nav_hunk("next")
        end
      end, { desc = "Jump to next Hunk" })
      vim.keymap.set("n", "[h", function()
        if vim.wo.diff then
          vim.cmd.normal({ "[c", bang = true })
        else
          gitsigns.nav_hunk("prev")
        end
      end, { desc = "Jump to previous Hunk" })

      -- Visual mode
      vim.keymap.set("v", "<leader>hs", function()
        gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
      end, { desc = "[H]unk [S]tage" })
      vim.keymap.set("v", "<leader>hr", function()
        gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
      end, { desc = "[H]unk [R]eset" })

      -- Text object
      vim.keymap.set({ "o", "x" }, "<leader>hS", gitsigns.select_hunk, { desc = "[H]unk [S]elect" })

      -- Normal mode
      vim.keymap.set("n", "<leader>hs", gitsigns.stage_hunk, { desc = "[H]unk [S]tage" })
      vim.keymap.set("n", "<leader>hr", gitsigns.reset_hunk, { desc = "[H]unk [R]eset" })
      vim.keymap.set("n", "<leader>hu", gitsigns.undo_stage_hunk, { desc = "[H]unk [U]ndo" })
      vim.keymap.set("n", "<leader>hp", gitsigns.preview_hunk, { desc = "[H]unk [P]review" })

      -- Buffer
      vim.keymap.set("n", "<leader>bs", gitsigns.stage_buffer, { desc = "[B]uffer [S]tage" })
      vim.keymap.set("n", "<leader>br", gitsigns.reset_buffer, { desc = "[B]uffer [R]eset" })
      vim.keymap.set("n", "<leader>bd", gitsigns.diffthis, { desc = "[B]uffer [D]iff" })

      -- Toggles
      vim.keymap.set("n", "<leader>tb", gitsigns.toggle_current_line_blame, { desc = "[T]oggle git [B]lame line" })
      vim.keymap.set("n", "<leader>td", gitsigns.toggle_deleted, { desc = "[T]oggle git show [D]eleted" })
    end,
  },
}
