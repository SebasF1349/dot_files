return {
  'ThePrimeagen/refactoring.nvim',
  cmd = 'Refactor',
  -- stylua: ignore
  keys = {
    { '<leader>rr', function() require('refactoring').select_refactor({ prefer_ex_cmd = true }) end, mode = { 'n', 'x' }, desc = '[R]efactoring', },
    { '<leader>rp', function() require('refactoring').debug.printf() end, desc = '[R]efactoring: Debug [P]rint', },
    { '<leader>rv', function() require('refactoring').debug.print_var() end, mode = { 'n', 'x' }, desc = '[R]efactoring: Debug [V]ariable', },
    { '<leader>rc', function() require('refactoring').debug.cleanup() end, desc = '[R]efactoring: [C]lear Debug', },
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
