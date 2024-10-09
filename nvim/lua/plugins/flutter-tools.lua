return {
  'akinsho/flutter-tools.nvim',
  ft = { 'dart' },
  dependencies = {
    'nvim-lua/plenary.nvim',
  },
  config = function()
    require('flutter-tools').setup()
  end,
}
