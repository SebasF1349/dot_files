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
          indentscope_color = "", -- catppuccin color (eg. `lavender`) Default: text
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
        -- make the references to the word under the cursor darker
        -- probably making other things light too, but I want them to be different to when I select a word
        -- og color is surface1 in both
        return {
          LspReferenceRead = { bg = colors.surface0 },
          LspReferenceWrite = { bg = colors.surface0 },
        }
      end,
    })
    vim.cmd.colorscheme("catppuccin")
  end,
}
