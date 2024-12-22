return {
  'catppuccin/nvim',
  name = 'catppuccin',
  priority = 1000,
  init = function()
    require('catppuccin').setup({
      flavour = 'mocha',
      transparent_background = true,
      default_integrations = false,
      integrations = {
        cmp = true,
        dap = true,
        dap_ui = true,
        gitsigns = true,
        markdown = true,
        mason = true,
        mini = true,
        native_lsp = {
          enabled = true,
          virtual_text = {
            errors = { 'italic' },
            hints = { 'italic' },
            warnings = { 'italic' },
            information = { 'italic' },
            ok = { 'italic' },
          },
          underlines = {
            errors = { 'underline' },
            hints = { 'underline' },
            warnings = { 'underline' },
            information = { 'underline' },
            ok = { 'underline' },
          },
          inlay_hints = {
            background = true,
          },
        },
        semantic_tokens = true,
        telescope = true,
        treesitter = true,
      },
      custom_highlights = function(colors)
        local utils = require('catppuccin.utils.colors')

        local float_bg = utils.darken(colors.blue, 0.10, colors.base)

        return {
          MatchParen = { fg = colors.mauve, bg = colors.surface1, style = {} },

          -- make the references to the word under the cursor darker
          LspReferenceRead = { bg = colors.surface0 },
          LspReferenceWrite = { bg = colors.surface0 },

          MasonNormal = { link = 'NormalFloat' },

          PanelHeading = { fg = colors.lavender, bg = colors.none, style = { 'bold', 'italic' } },

          LazyH1 = { bg = colors.none, fg = colors.lavender, style = { 'bold' } },
          LazyButton = { bg = colors.none, fg = colors.overlay0 },
          LazyButtonActive = { bg = colors.none, fg = colors.lavender, style = { 'bold' } },
          LazySpecial = { fg = colors.green },

          Pmenu = { bg = float_bg, fg = colors.lavender },
          PmenuKind = { bg = float_bg, fg = colors.mauve },
          PmenuSbar = { bg = colors.surface0 },
          PmenuThumb = { bg = colors.overlay2 },
          NormalFloat = { bg = float_bg, fg = colors.lavender },
          FloatBorder = { bg = float_bg, fg = colors.blue },
          FloatTitle = { bg = float_bg, fg = colors.lavender },

          CmpItemAbbrMatch = { fg = colors.blue, style = { 'bold' } },
          CmpItemMenu = { fg = colors.surface0 },
          CmpDoc = { link = 'NormalFloat' },
          CmpDocBorder = { fg = colors.surface1, bg = colors.none },

          TelescopeNormal = { bg = float_bg, fg = colors.lavender },
          TelescopeMatching = { bg = float_bg, fg = colors.green },
          TelescopeSelection = { bg = float_bg, fg = colors.green },
          TelescopePromptNormal = { bg = float_bg, fg = colors.lavender },
          TelescopeResultsDiffAdd = { bg = float_bg, fg = colors.green },
          TelescopeResultsDiffChange = { bg = float_bg, fg = colors.yellow },
          TelescopeResultsDiffDelete = { bg = float_bg, fg = colors.red },
          TelescopeBorder = { bg = float_bg },

          TerminalNormal = { bg = colors.base, fg = colors.text },
        }
      end,
    })
    vim.cmd.colorscheme('catppuccin')
  end,
}
