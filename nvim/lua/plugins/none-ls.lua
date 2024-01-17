return {
  "nvimtools/none-ls.nvim",
  event = { "LspAttach" },
  config = function()
    local null_ls = require("null-ls")

    null_ls.setup({
      sources = {
        null_ls.builtins.formatting.stylua.with({
          extra_args = function(_params)
            return {
              "--indent-width=2",
              "--indent-type=spaces",
            }
          end,
        }),
      },
    })

    vim.keymap.set("n", "<leader>fn", vim.lsp.buf.format, {})
  end,
}
