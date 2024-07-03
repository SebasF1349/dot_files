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
        which_key = true,
      },
      custom_highlights = function(colors)
        return {
          FloatBorder = { fg = colors.blue, bg = colors.none },
          FloatTitle = { fg = colors.lavender, bg = colors.none },

          -- make the references to the word under the cursor darker
          LspReferenceRead = { bg = colors.surface0 },
          LspReferenceWrite = { bg = colors.surface0 },

          MasonNormal = { link = 'NormalFloat' },

          PanelHeading = {
            fg = colors.lavender,
            bg = colors.none,
            style = { 'bold', 'italic' },
          },

          LazyH1 = {
            bg = colors.none,
            fg = colors.lavender,
            style = { 'bold' },
          },
          LazyButton = {
            bg = colors.none,
            fg = colors.overlay0,
          },
          LazyButtonActive = {
            bg = colors.none,
            fg = colors.lavender,
            style = { 'bold' },
          },
          LazySpecial = { fg = colors.green },

          PmenuSel = { bg = colors.green, fg = colors.base },

          CmpItemAbbrMatch = { fg = colors.blue, style = { 'bold' } },
          CmpItemMenu = { fg = colors.subtext1 },
          CmpDoc = { link = 'NormalFloat' },
          CmpDocBorder = { fg = colors.surface1, bg = colors.none },

          TroubleNormal = { bg = colors.none },

          TelescopeMatching = { fg = colors.lavender },
          TelescopeResultsDiffAdd = { fg = colors.green },
          TelescopeResultsDiffChange = { fg = colors.yellow },
          TelescopeResultsDiffDelete = { fg = colors.red },
        }
      end,
    })
    vim.cmd.colorscheme('catppuccin')
  end,
}
