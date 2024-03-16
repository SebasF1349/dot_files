-- Useful plugin to show you pending keybinds.
return {
  "folke/which-key.nvim",
  keys = { "<leader>", "g", "[", "]" },
  opts = {},
  config = function()
    require("which-key").register({
      ["g"] = { name = "Flash", _ = "which_key_ignore" },
      ["]"] = { name = "+next", _ = "which_key_ignore" },
      ["["] = { name = "+prev", _ = "which_key_ignore" },
      ["<leader>c"] = { name = "[C]ode", _ = "which_key_ignore" },
      ["<leader>d"] = { name = "[D]ebugger", _ = "which_key_ignore" },
      ["<leader>h"] = { { name = "Git [H]unk", _ = "which_key_ignore" }, { name = "[H]arpoon", _ = "which_key_ignore" } },
      ["<leader>b"] = { name = "Git [B]uffer", _ = "which_key_ignore" },
      ["<leader>f"] = { name = "[F]ind", _ = "which_key_ignore" },
      ["<leader>t"] = { name = "[T]oggle", _ = "which_key_ignore" },
      ["<leader>w"] = { name = "[W]orkspace", _ = "which_key_ignore" },
      ["<leader>x"] = { name = "[X]Trouble", _ = "which_key_ignore" },
      ["<leader>m"] = { name = "[M]arkdown", _ = "which_key_ignore" },
    })
    -- register which-key VISUAL mode
    -- required for visual <leader>hs (hunk stage) to work
    require("which-key").register({
      ["<leader>"] = { name = "VISUAL <leader>" },
      ["<leader>h"] = { "Git [H]unk" },
    }, { mode = "v" })
  end,
}
