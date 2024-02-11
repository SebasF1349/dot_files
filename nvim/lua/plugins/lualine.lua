local function basename(str)
  local path = vim.fn.split(str, "/")
  if #path == 1 then
    return "/" .. path[#path]
  end
  return path[#path - 1] .. "/" .. path[#path]
end

local function Harpoon_files()
  local harpoon = require("harpoon")
  local currentfile = basename(vim.fn.expand("%:p"))

  local s = ""

  for i, v in ipairs(harpoon:list().items) do
    local fn = basename(v.value)
    local prefix = fn ~= currentfile and i or "󰛢"

    s = s .. prefix .. " " .. fn
    if i < #harpoon:list().items then
      s = s .. "  "
    end
  end

  if #harpoon:list().items == 0 then
    s = s .. "󰛢"
  end

  return s
end

return {
  "nvim-lualine/lualine.nvim",
  -- event = { "BufReadPre", "BufNewFile" },
  event = "VeryLazy",
  dependencies = { "nvim-tree/nvim-web-devicons", "theprimeagen/harpoon" },
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
      lualine_y = {},
      lualine_z = { { Harpoon_files } },
    },
    inactive_sections = {},
    tabline = {},
    winbar = {
      lualine_a = {},
      lualine_b = {},
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
    extensions = {},
  },
}
