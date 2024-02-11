return {
  "laytan/tailwind-sorter.nvim",
  dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-lua/plenary.nvim" },
  build = "cd formatter && npm i && npm run build",
  config = true,
  ft = { "html", "svelte" },
  opts = {
    on_save_enabled = true,
    on_save_pattern = { "*.html", "*.js", "*.ts", "*.jsx", "*.tsx", "*.twig", "*.hbs", "*.php", "*.heex", "*.astro", "*.svelte" },
    node_path = "node",
  },
}
