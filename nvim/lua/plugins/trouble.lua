return {
  "folke/trouble.nvim",
  event = "LspAttach",
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
    vim.keymap.set("n", "<leader>xq", function()
      require("trouble").toggle("quickfix")
    end, { desc = "[X]Trouble [Q]uickfix" })
    vim.keymap.set("n", "<leader>xl", function()
      require("trouble").toggle("loclist")
    end, { desc = "[X]Trouble [L]ocal list" })
    vim.keymap.set("n", "gR", function()
      require("trouble").toggle("lsp_references")
    end, { desc = "[g]Trouble [R]eferences" })
    vim.keymap.set("n", "[x", function()
      require("trouble").next({ skip_groups = true, jump = true })
    end, { desc = "Next [T]rouble group" })
    vim.keymap.set("n", "]x", function()
      require("trouble").previous({ skip_groups = true, jump = true })
    end, { desc = "Previous [T]rouble group" })
  end,
}
