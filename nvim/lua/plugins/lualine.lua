local function breadcrumb()
  local indicator_size = vim.o.columns > 80 and vim.o.columns / 2 or vim.o.columns / 3
  return require("nvim-treesitter").statusline({
    indicator_size = indicator_size,
  }) or ""
end

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
      lualine_b = { "branch", "diff", "diagnostics" },
      lualine_c = {},
      lualine_x = {},
      lualine_y = { { "diagnostics", sources = { "nvim_workspace_diagnostic" } } },
      lualine_z = { "grapple" },
    },
    inactive_sections = {},
    tabline = {},
    winbar = {
      lualine_a = {},
      lualine_b = { breadcrumb },
      lualine_c = {},
      lualine_x = {},
      lualine_y = { { "filetype", icon_only = true } },
      lualine_z = { { "filename", path = 1 } },
    },
    inactive_winbar = {
      lualine_a = { "diagnostics" },
      lualine_b = {},
      lualine_c = {},
      lualine_x = {},
      lualine_y = { { "filetype", icon_only = true } },
      lualine_z = { { "filename", path = 1 } },
    },
    extensions = { "fugitive", "trouble" },
  },
}
