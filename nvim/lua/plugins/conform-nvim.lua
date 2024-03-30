return {
  "stevearc/conform.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    formatters_by_ft = {
      lua = { "stylua" },
      svelte = { { "prettierd", "prettier" } },
      javascript = { { "prettierd", "prettier" } },
      typescript = { { "prettierd", "prettier" } },
      javascriptreact = { { "prettierd", "prettier" } },
      typescriptreact = { { "prettierd", "prettier" } },
      css = { { "prettierd", "prettier" } },
      json = { { "prettierd", "prettier" } },
      markdown = { { "prettierd", "prettier" } },
      html = { { "prettierd", "prettier" } },
      sh = { "shfmt" },
      rust = { "rustfmt" },
      yaml = { "yamlfmt" },
      toml = { "taplo" },
      java = { "google-java-format" },
    },
    format_on_save = {
      -- These options will be passed to conform.format()
      timeout_ms = 500,
      lsp_fallback = true,
    },
    notify_on_error = false,
  },
}
