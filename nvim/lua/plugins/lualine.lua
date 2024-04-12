local mocha = require("catppuccin.palettes").get_palette("mocha")

return {
  "nvim-lualine/lualine.nvim",
  event = { "BufReadPre", "BufNewFile" },
  -- event = "VeryLazy",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    options = {
      icons_enabled = true,
      theme = "catppuccin",
      component_separators = { left = "", right = "" },
      section_separators = { left = "", right = "" },
      disabled_filetypes = {
        statusline = {},
        winbar = {},
      },
      ignore_focus = {},
      always_divide_middle = true,
      globalstatus = true,
      refresh = {
        statusline = 1000,
        tabline = 1000,
        winbar = 1000,
      },
    },
    sections = {
      lualine_a = { "mode" },
      lualine_b = {
        "branch",
        {
          function()
            return "󰜥"
          end,
          cond = function()
            local gitsigns = vim.b.gitsigns_status_dict
            return gitsigns
              and (gitsigns.added and gitsigns.added > 0 or gitsigns.removed and gitsigns.removed > 0 or gitsigns.modified and gitsigns.modified > 0)
          end,
          color = { fg = mocha.yellow },
        },
        "diagnostics",
      },
      lualine_c = {},
      lualine_x = {},
      lualine_y = { {
        "diagnostics",
        sources = { "nvim_workspace_diagnostic" },
        sections = { "error", "warn" },
      } },
      lualine_z = { "grapple" },
    },
    inactive_sections = {},
    tabline = {},
    winbar = {
      lualine_a = {},
      lualine_b = {},
      lualine_c = {},
      lualine_x = {},
      lualine_y = { { "filetype", icon_only = true } },
      lualine_z = { { "filename", path = 1, symbols = { unnamed = "" } } },
    },
    inactive_winbar = {
      lualine_a = { "diagnostics" },
      lualine_b = {},
      lualine_c = {},
      lualine_x = {},
      lualine_y = { { "filetype", icon_only = true } },
      lualine_z = { { "filename", path = 1 } },
    },
    extensions = { "fugitive", "trouble", "quickfix" },
  },
}
