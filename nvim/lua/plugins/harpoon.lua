return {
  "theprimeagen/harpoon",
  branch = "harpoon2",
  keys = "<leader>h",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    local harpoon = require("harpoon")
    harpoon:setup({
      settings = {
        save_on_toggle = true,
        sync_on_ui_close = true,
      },
    })

    vim.keymap.set("n", "<leader>ha", function()
      harpoon:list():append()
    end, { desc = "[H]arpoon [A]dd" })
    vim.keymap.set("n", "<leader>hx", function()
      harpoon:list():remove()
    end, { desc = "[H]arpoon [X]Remove" })
    vim.keymap.set("n", "<leader>hc", function()
      harpoon:list():clear()
    end, { desc = "[H]arpoon [C]lear" })
    vim.keymap.set("n", "<leader>ht", function()
      harpoon.ui:toggle_quick_menu(harpoon:list())
    end, { desc = "[H]arpoon [T]oggle" })
    for pos = 0, 9 do
      vim.keymap.set("n", "<leader>h" .. pos, function()
        harpoon:list():select(pos)
      end, { desc = "Move to harpoon mark #" .. pos })
    end
    vim.keymap.set("n", "<C-n>", function()
      harpoon:list():next({ ui_nav_wrap = true })
    end, { desc = "Move to [N]ext mark" })
    vim.keymap.set("n", "<C-p>", function()
      harpoon:list():prev({ ui_nav_wrap = true })
    end, { desc = "Move to [P]revious mark" })
  end,
}
