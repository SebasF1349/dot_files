local mocha = require("catppuccin.palettes").get_palette("mocha")

local signs = {
  " ",
  " ",
  "",
  " ",
}
local levels = {
  vim.diagnostic.severity.ERROR,
  vim.diagnostic.severity.WARN,
  vim.diagnostic.severity.INFO,
  vim.diagnostic.severity.HINT,
}
local levels_hi = {
  "StatusLineError",
  "StatusLineWarn",
  "StatusLineInfo",
  "StatusLineHint",
}

vim.api.nvim_set_hl(0, levels_hi[1], { fg = mocha.red, bg = mocha.surface0 })
vim.api.nvim_set_hl(0, levels_hi[2], { fg = mocha.yellow, bg = mocha.surface0 })
vim.api.nvim_set_hl(0, levels_hi[3], { fg = mocha.sky, bg = mocha.surface0 })
vim.api.nvim_set_hl(0, levels_hi[4], { fg = mocha.teal, bg = mocha.surface0 })

local function local_diagnostics()
  for i, _ in ipairs(levels) do
    local count = vim.tbl_count(vim.diagnostic.get(0, { severity = i }))
    if count > 0 then
      return "%#" .. levels_hi[i] .. "#" .. signs[i]
    end
  end

  return ""
end

vim.api.nvim_set_hl(0, "StatusLineWorkspace", { fg = mocha.comment, bg = mocha.surface0 })

local function workspace_diagnostics()
  for i, _ in ipairs(levels) do
    local count = vim.tbl_count(vim.diagnostic.get(nil, { severity = i }))
    local local_count = vim.tbl_count(vim.diagnostic.get(0, { severity = i }))
    if count > local_count then
      return "%#StatusLineWorkspace#" .. signs[i]
    end
  end

  return ""
end

local function custom_diagnostics()
  local local_diag = local_diagnostics()
  local workspace_diag = workspace_diagnostics()
  if #local_diag == 0 then
    return workspace_diag
  elseif #workspace_diag == 0 then
    return local_diag
  else
    return local_diag .. " " .. workspace_diag
  end
end

return {
  "nvim-lualine/lualine.nvim",
  event = { "BufReadPre", "BufNewFile" },
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
      },
      lualine_c = {},
      lualine_x = {},
      lualine_y = { custom_diagnostics },
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
      lualine_a = {},
      lualine_b = {},
      lualine_c = {},
      lualine_x = {},
      lualine_y = { { "filetype", icon_only = true } },
      lualine_z = { { "filename", path = 1 } },
    },
    extensions = { "fugitive", "trouble", "quickfix", "nvim-dap-ui", "man" },
  },
}
