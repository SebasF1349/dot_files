return {
  -- Adds git related signs to the gutter, as well as utilities for managing changes
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    signs = {
      add = { text = "+" },
      change = { text = "~" },
      delete = { text = "_" },
      topdelete = { text = "‾" },
      changedelete = { text = "~" },
    },
    on_attach = function(bufnr)
      local gs = package.loaded.gitsigns
      local function map(mode, l, r, opts)
        opts = opts or {}
        opts.buffer = bufnr
        vim.keymap.set(mode, l, r, opts)
      end

      -- These are the defaul keybindings
      -- only leaving them here for reference and for the desc

      -- Navigation
      map({ "n", "v" }, "]h", function()
        if vim.wo.diff then
          return "]c"
        end
        vim.schedule(function()
          gs.next_hunk()
        end)
        return "<Ignore>"
      end, { expr = true, desc = "Jump to next Hunk" })
      map({ "n", "v" }, "[h", function()
        if vim.wo.diff then
          return "[c"
        end
        vim.schedule(function()
          gs.prev_hunk()
        end)
        return "<Ignore>"
      end, { expr = true, desc = "Jump to previous Hunk" })

      -- Visual mode
      map("v", "<leader>hs", function()
        gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
      end, { desc = "[H]unk [S]tage" })
      map("v", "<leader>hr", function()
        gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
      end, { desc = "[H]unk [R]eset" })

      -- Text object
      map({ "o", "x" }, "<leader>hS", ":<C-U>Gitsigns select_hunk<CR>", { desc = "[H]unk [S]elect" })

      -- Normal mode
      map("n", "<leader>hs", gs.stage_hunk, { desc = "[H]unk [S]tage" })
      map("n", "<leader>hr", gs.reset_hunk, { desc = "[H]unk [R]eset" })
      map("n", "<leader>hu", gs.undo_stage_hunk, { desc = "[H]unk [U]ndo" })
      map("n", "<leader>hp", gs.preview_hunk, { desc = "[H]unk [P]review" })

      -- Buffer
      map("n", "<leader>bs", gs.stage_buffer, { desc = "[B]uffer [S]tage" })
      map("n", "<leader>br", gs.reset_buffer, { desc = "[B]uffer [R]eset" })
      map("n", "<leader>bd", gs.diffthis, { desc = "[B]uffer [D]iff" })

      -- Toggles
      map("n", "<leader>tb", gs.toggle_current_line_blame, { desc = "[T]oggle git [B]lame line" })
      map("n", "<leader>td", gs.toggle_deleted, { desc = "[T]oggle git show [D]eleted" })
    end,
  },
}
