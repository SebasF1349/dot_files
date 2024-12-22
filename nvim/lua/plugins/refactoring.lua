return {
  'ThePrimeagen/refactoring.nvim',
  cmd = 'Refactor',
  -- stylua: ignore
  keys = {
    { '<leader>rr', ':Refactor ', mode = { 'n', 'x' }, desc = '[R]efactoring' },
    { '<leader>rp', function() require('refactoring').debug.printf() end, mode = { 'n' }, desc = '[R]efactoring: Debug [P]rint', },
    { '<leader>rv', function() require('refactoring').debug.print_var() end, mode = { 'n', 'x' }, desc = '[R]efactoring: Debug [V]ariable', },
    { '<leader>rc', function() require('refactoring').debug.cleanup() end, mode = { 'n' }, desc = '[R]efactoring: [C]lear Debug', },
  },
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-treesitter/nvim-treesitter',
  },
  opts = {
    -- customize print messages per language
    -- https://github.com/ThePrimeagen/refactoring.nvim?tab=readme-ov-file#customizing-printf-statements
    show_success_message = true,
  },
}
