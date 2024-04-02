return {
  "catppuccin/nvim",
  name = "catppuccin",
  priority = 1000,
  init = function()
    require("catppuccin").setup({
      flavour = "mocha",
      transparent_background = true,
      integrations = {
        cmp = true,
        gitsigns = true,
        treesitter = true,
        telescope = true,
        lsp_trouble = true,
        which_key = true,
        mason = true,
        dap = true,
        dap_ui = true,
        mini = {
          enabled = true,
          indentscope_color = "",
        },
        native_lsp = {
          enabled = true,
          virtual_text = {
            errors = { "italic" },
            hints = { "italic" },
            warnings = { "italic" },
            information = { "italic" },
          },
          underlines = {
            errors = { "underline" },
            hints = { "underline" },
            warnings = { "underline" },
            information = { "underline" },
          },
          inlay_hints = {
            background = true,
          },
        },
      },
      custom_highlights = function(colors)
        return {
          FloatBorder = { fg = colors.blue, bg = colors.none },
          FloatTitle = { fg = colors.lavender, bg = colors.none },

          LineNr = { fg = colors.overlay0 },

          -- make the references to the word under the cursor darker
          LspReferenceRead = { bg = colors.surface0 },
          LspReferenceWrite = { bg = colors.surface0 },

          MasonNormal = { link = "NormalFloat" },

          PanelHeading = {
            fg = colors.lavender,
            bg = colors.none,
            style = { "bold", "italic" },
          },

          LazyH1 = {
            bg = colors.none,
            fg = colors.lavender,
            style = { "bold" },
          },
          LazyButton = {
            bg = colors.none,
            fg = colors.overlay0,
          },
          LazyButtonActive = {
            bg = colors.none,
            fg = colors.lavender,
            style = { "bold" },
          },
          LazySpecial = { fg = colors.green },

          PmenuSel = { bg = colors.green, fg = colors.base },

          CmpItemAbbrMatch = { fg = colors.blue, style = { "bold" } },
          CmpItemMenu = { fg = colors.subtext1 },
          CmpDoc = { link = "NormalFloat" },
          CmpDocBorder = { fg = colors.surface1, bg = colors.none },

          TroubleNormal = { bg = colors.none },

          TelescopeMatching = { fg = colors.lavender },
          TelescopeResultsDiffAdd = { fg = colors.green },
          TelescopeResultsDiffChange = { fg = colors.yellow },
          TelescopeResultsDiffDelete = { fg = colors.red },
        }
      end,
    })
    vim.cmd.colorscheme("catppuccin")
  end,
}
