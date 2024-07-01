return {
  'folke/which-key.nvim',
  keys = { '<leader>', 'g', '[', ']', '"', 'y', 'd', 'c' },
  ft = 'markdown',
  config = function()
    local which_key = require('which-key')

    which_key.setup({
      window = { border = 'rounded' },
    })

    which_key.register({
      ['g'] = { name = '[G]o to' },
      ['gb'] = { name = '[B]ufferlist Management' },
      [']'] = { name = 'Next' },
      ['['] = { name = 'Prev' },
      ['ys'] = { name = 'Surround' },
      ['ds'] = { name = 'Delete Surround' },
      ['cs'] = { name = 'Change Surround' },
      ['<leader>'] = {
        ['c'] = { name = '[C]ode' },
        ['d'] = { name = '[D]ebugger' },
        ['h'] = { name = 'Git [H]unk' },
        ['b'] = { name = 'Git [B]uffer' },
        ['f'] = { name = '[F]ind' },
        ['t'] = { name = '[T]oggle' },
        ['x'] = { name = '[X]Trouble' },
        ['q'] = { name = '[Q]uickfix List' },
        ['l'] = { name = '[L]ocation List' },
        ['m'] = { name = '[M]arkdown' },
        ['r'] = { name = '[R]eplace current word' },
      },
    })
    which_key.register({
      ['<leader>'] = {
        name = 'VISUAL <leader>', -- this is needed (looks like a which-key bug)
        ['h'] = { name = 'Git [H]unk' },
        ['f'] = { name = '[F]ind' },
      },
    }, { mode = 'v' })
  end,
}
