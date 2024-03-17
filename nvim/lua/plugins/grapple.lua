return {
  "cbochs/grapple.nvim",
  dependencies = {
    { "nvim-tree/nvim-web-devicons", lazy = true },
  },
  event = { "BufReadPost", "BufNewFile" },
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
        grapple.tag({ name = name })
      end
    end, { desc = "[G]rapple" })
    vim.keymap.set("n", "<leader>tg", grapple.toggle_tags, { desc = "[T]oggle [G]rapple Window" })
    vim.keymap.set("n", "<C-f>", grapple.cycle_forward, { desc = "Grapple Cycle [F]orwards" })
    vim.keymap.set("n", "<C-b>", grapple.cycle_backward, { desc = "Grapple Cycle [B]ackwards" })
    for pos = 1, 4 do
      vim.keymap.set("n", "<leader>" .. pos, function()
        grapple.select({ index = pos })
      end, { desc = "Grapple Select Index [" .. pos .. "]" })
    end
  end,
}
