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
        fidget = true,
        telescope = true,
        harpoon = true,
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
    })
    vim.cmd.colorscheme("catppuccin")
  end,
}
