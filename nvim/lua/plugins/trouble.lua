return {
  "folke/trouble.nvim",
  keys = { "<leader>x" },
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    vim.keymap.set("n", "<leader>xx", function()
      require("trouble").toggle()
    end, { desc = "[X]Trouble [X]Toogle" })
    vim.keymap.set("n", "<leader>xw", function()
      require("trouble").toggle("workspace_diagnostics")
    end, { desc = "[X]Trouble [W]orkspace" })
    vim.keymap.set("n", "<leader>xd", function()
      require("trouble").toggle("document_diagnostics")
    end, { desc = "[X]Trouble [D]ocument" })
    vim.keymap.set("n", "[x", function()
      require("trouble").next({ skip_groups = true, jump = true })
    end, { desc = "Next [T]rouble group" })
    vim.keymap.set("n", "]x", function()
      require("trouble").previous({ skip_groups = true, jump = true })
    end, { desc = "Previous [T]rouble group" })
  end,
}
