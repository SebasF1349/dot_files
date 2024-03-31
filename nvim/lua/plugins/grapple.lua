return {
  "cbochs/grapple.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  keys = { "<leader>g", "<leader>tg", "<C-f>", "<C-b>", "<leader>1", "<leader>2", "<leader>3", "<leader>4" },
  cmd = "Grapple",
  config = function()
    local grapple = require("grapple")
    grapple.setup({
      win_opts = { border = "rounded" },
    })

    vim.keymap.set("n", "<leader>g", function()
      if grapple.exists() then
        grapple.untag()
      else
        local name = vim.fn.input("Enter tag name: ")
        if name == nil or name == "" then
          name = vim.fn.expand("%:t")
        end
        grapple.tag({ name = name })
      end
    end, { desc = "[G]rapple" })
    vim.keymap.set("n", "<leader>tg", grapple.toggle_tags, { desc = "[T]oggle [G]rapple Window" })
    vim.keymap.set("n", "<C-f>", function()
      grapple.cycle_tags("next")
    end, { desc = "Grapple Cycle [F]orwards" })
    vim.keymap.set("n", "<C-b>", function()
      grapple.cycle_tags("prev")
    end, { desc = "Grapple Cycle [B]ackwards" })
    for pos = 1, 4 do
      vim.keymap.set("n", "<leader>" .. pos, function()
        grapple.select({ index = pos })
      end, { desc = "Grapple Select Index [" .. pos .. "]" })
    end
  end,
}
