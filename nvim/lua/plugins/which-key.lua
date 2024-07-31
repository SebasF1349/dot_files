return {
  'folke/which-key.nvim',
  event = 'VeryLazy',
  config = function()
    local which_key = require('which-key')

    local function create_goto_keymap(number)
      return {
        'gb' .. number,
        function()
          local count = 0
          for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_loaded(bufnr) and vim.api.nvim_get_option_value('buflisted', { buf = bufnr }) then
              count = count + 1
              if count == number then
                vim.cmd('buffer ' .. bufnr)
              end
            end
          end
        end,
        desc = function()
          local count = 0
          for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_loaded(bufnr) and vim.api.nvim_get_option_value('buflisted', { buf = bufnr }) then
              count = count + 1
              if count == number then
                local filepath = vim.api.nvim_buf_get_name(bufnr)
                return 'Go to ' .. filepath:gsub(vim.uv.cwd() or '', '')
              end
            end
          end
          return 'null'
        end,
      }
    end

    which_key.setup({
      win = { border = 'rounded' },
      icons = { rules = false },
      filter = function(mapping)
        return mapping.desc ~= 'null'
      end,
      spec = {
        {
          create_goto_keymap(1),
          create_goto_keymap(2),
          create_goto_keymap(3),
          create_goto_keymap(4),
          create_goto_keymap(5),
          create_goto_keymap(6),
          create_goto_keymap(7),
          create_goto_keymap(8),
          create_goto_keymap(9),
        },
      },
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
      { 'ge', group = '[E]dit Buffer' },
      { 'gE', group = '[E]dit Buffer in Current Directory' },
      { 'gs', group = 'Open [S]cratch Buffer' },
      { 'ga', group = 'Edit [A]lternative File' },
      { 'ys', group = 'Surround' },
      { 'cr', group = '[C]ode [R]unner' },
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
