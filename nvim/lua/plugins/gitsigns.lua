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
      local gs = package.loaded.gitsigns

      -- Navigation
      vim.keymap.set({ "n", "v" }, "]h", function()
        if vim.wo.diff then
          return "]c"
        end
        vim.schedule(function()
          gs.next_hunk()
        end)
        return "<Ignore>"
      end, { expr = true, desc = "Jump to next Hunk" })
      vim.keymap.set({ "n", "v" }, "[h", function()
        if vim.wo.diff then
          return "[c"
        end
        vim.schedule(function()
          gs.prev_hunk()
        end)
        return "<Ignore>"
      end, { expr = true, desc = "Jump to previous Hunk" })

      -- Visual mode
      vim.keymap.set("v", "<leader>hs", function()
        gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
      end, { desc = "[H]unk [S]tage" })
      vim.keymap.set("v", "<leader>hr", function()
        gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
      end, { desc = "[H]unk [R]eset" })

      -- Text object
      vim.keymap.set({ "o", "x" }, "<leader>hS", gs.select_hunk, { desc = "[H]unk [S]elect" })

      -- Normal mode
      vim.keymap.set("n", "<leader>hs", gs.stage_hunk, { desc = "[H]unk [S]tage" })
      vim.keymap.set("n", "<leader>hr", gs.reset_hunk, { desc = "[H]unk [R]eset" })
      vim.keymap.set("n", "<leader>hu", gs.undo_stage_hunk, { desc = "[H]unk [U]ndo" })
      vim.keymap.set("n", "<leader>hp", gs.preview_hunk, { desc = "[H]unk [P]review" })

      -- Buffer
      vim.keymap.set("n", "<leader>bs", gs.stage_buffer, { desc = "[B]uffer [S]tage" })
      vim.keymap.set("n", "<leader>br", gs.reset_buffer, { desc = "[B]uffer [R]eset" })
      vim.keymap.set("n", "<leader>bd", gs.diffthis, { desc = "[B]uffer [D]iff" })

      -- Toggles
      vim.keymap.set("n", "<leader>tb", gs.toggle_current_line_blame, { desc = "[T]oggle git [B]lame line" })
      vim.keymap.set("n", "<leader>td", gs.toggle_deleted, { desc = "[T]oggle git show [D]eleted" })
    end,
  },
}
