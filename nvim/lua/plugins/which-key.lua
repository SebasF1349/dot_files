return {
  'folke/which-key.nvim',
  event = 'VeryLazy',
  config = function()
    local which_key = require('which-key')

    which_key.setup({
      win = { border = 'rounded' },
      icons = { rules = false },
    })

    which_key.add({
      { '<leader>b', group = 'Git [B]uffer' },
      { '<leader>c', group = '[C]ode' },
      { '<leader>d', group = '[D]ebugger' },
      { '<leader>f', group = '[F]ind' },
      { '<leader>h', group = 'Git [H]unk' },
      { '<leader>l', group = '[L]ocation List' },
      { '<leader>m', group = '[M]arkdown' },
      { '<leader>q', group = '[Q]uickfix List' },
      { '<leader>r', group = '[R]efactoring' },
      { '<leader>t', group = '[T]oggle' },
      { '[', group = 'Prev' },
      { ']', group = 'Next' },
      { 'cs', group = 'Change Surround' },
      { 'ds', group = 'Delete Surround' },
      { 'g', group = '[G]o to' },
      { 'gb', group = '[B]ufferlist Management' },
      { 'ys', group = 'Surround' },
    })
    which_key.add({
      {
        mode = { 'v' },
        { '<leader>', group = 'VISUAL <leader>' },
        { '<leader>f', group = '[F]ind' },
        { '<leader>h', group = 'Git [H]unk' },
        { '<leader>r', group = '[R]efactoring' },
      },
    })
  end,
}
