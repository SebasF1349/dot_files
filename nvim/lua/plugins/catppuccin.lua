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
        gitsigns = true,
        markdown = true,
        mason = true,
        mini = true,
        semantic_tokens = true,
        treesitter = true,
      },
      custom_highlights = function(colors)
        return {
          -- make the references to the word under the cursor darker
          LspReferenceText = { bg = colors.none },
          LspReferenceRead = { bg = colors.none },
          LspReferenceWrite = { bg = colors.none },

          LspReferenceShow = { bg = colors.surface1 }, -- custom hl

          LazyH1 = { bg = colors.none, fg = colors.lavender, style = { 'bold' } },
          LazyButton = { bg = colors.none, fg = colors.overlay0 },
          LazyButtonActive = { bg = colors.none, fg = colors.lavender, style = { 'bold' } },
          LazySpecial = { fg = colors.green },

          Pmenu = { bg = colors.surface0, fg = colors.text },
          PmenuSel = { bg = colors.surface1, style = { "bold" } },
          PmenuSbar = { bg = colors.surface1 },

          NormalFloat = { bg = colors.surface0, fg = colors.text },
          FloatBorder = { bg = colors.surface0, fg = colors.text },

          TerminalNormal = { bg = colors.base, fg = colors.text },

          -- Checkhealth
          ['@health.success'] = { bg = colors.none, fg = colors.teal, style = { 'bold', 'underline' } }, -- healthSuccess
          ['@health.warning'] = { bg = colors.none, fg = colors.yellow, style = { 'bold', 'underline' } }, -- healthWarning
          ['@health.error'] = { bg = colors.none, fg = colors.red, style = { 'bold', 'underline' } }, -- healthError
        }
      end,
    })
    vim.cmd.colorscheme('catppuccin')
  end,
}
