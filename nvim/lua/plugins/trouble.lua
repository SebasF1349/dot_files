return {
  "folke/trouble.nvim",
  keys = { "<leader>x" },
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    local trouble = require("trouble")
    vim.keymap.set("n", "<leader>xx", function()
      trouble.toggle()
    end, { desc = "[X]Trouble [X]Toogle" })
    vim.keymap.set("n", "<leader>xw", function()
      trouble.toggle("workspace_diagnostics")
    end, { desc = "[X]Trouble [W]orkspace" })
    vim.keymap.set("n", "<leader>xd", function()
      trouble.toggle("document_diagnostics")
    end, { desc = "[X]Trouble [D]ocument" })
    vim.keymap.set("n", "<leader>xn", function()
      vim.cmd("silent grep! -i '(note\\|todo\\|fix):'")
      trouble.toggle("quickfix")
    end, { desc = "[X]Trouble [N]otes" })
    vim.keymap.set("n", "]x", function()
      if trouble.is_open() then
        trouble.next({ skip_groups = true, jump = true })
      end
    end, { desc = "Next [X]Trouble group" })
    vim.keymap.set("n", "[x", function()
      if trouble.is_open() then
        trouble.previous({ skip_groups = true, jump = true })
      end
    end, { desc = "Previous [X]Trouble group" })
  end,
}
