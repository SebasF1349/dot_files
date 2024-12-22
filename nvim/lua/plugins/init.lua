return {
  { 'tpope/vim-fugitive', cmd = { 'G', 'Git', 'Gdiffsplit' } },

  { 'NMAC427/guess-indent.nvim', event = 'InsertEnter', opts = {} },

  {
    'danymat/neogen',
    keys = {
      { 'ga', "<cmd>lua require('neogen').generate()<CR>", mode = 'n', desc = '[A]nnotate Code' },
    },
    opts = { snippet_engine = 'nvim' },
  },

  {
    'saecki/crates.nvim',
    event = { 'BufRead Cargo.toml' },
    config = function()
      local crates = require('crates')
      crates.setup({
        completion = {
          cmp = { enabled = true },
        },
      })
      crates.show()
      vim.keymap.set('n', 'K', function()
        if vim.fn.expand('%:t') == 'Cargo.toml' and require('crates').popup_available() then
          require('crates').show_popup()
        else
          vim.lsp.buf.hover()
        end
      end, { desc = 'Show Crate Documentation', buffer = true })
    end,
  },
}
