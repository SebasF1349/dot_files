return {
  {
    'tpope/vim-fugitive',
    cmd = { 'G', 'Git', 'Gvdiffsplit', 'Gdiffsplit' },
    keys = {
      { '<leader>gg', '<cmd>tab G<CR>]]', desc = 'Open fu[G]itive in a new tab', remap = true },
      { '<leader>gd', '<cmd>Gvdiffsplit<CR>', desc = '[D]iff Current File' },
    },
    config = function()
      local function diffModeMap(key, cmd, desc)
        vim.keymap.set({ 'n', 'x' }, key, function()
          return not vim.wo.diff and 'normal! ' .. key
            or (vim.fn.mode() == 'n' and '?<<<<<<<<CR>V/>>>>>>><CR>' .. cmd or cmd)
        end, { desc = desc, silent = true, expr = true })
      end
      diffModeMap('gh', ':diffget //2 <CR>', 'Git: get lhs of diff')
      diffModeMap('gl', ':diffget //3 <CR>', 'Git: get rhs of diff')
    end,
  },

  { 'NMAC427/guess-indent.nvim', event = 'InsertEnter', opts = {} },

  {
    'danymat/neogen',
    keys = {
      { 'gd', "<cmd>lua require('neogen').generate()<CR>", mode = 'n', desc = 'Add [D]ocs' },
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

  { 'artemave/workspace-diagnostics.nvim' },

  {
    'echasnovski/mini.splitjoin',
    keys = { '<leader>j' },
    opts = { mappings = { toggle = '<leader>j', split = '', join = '' } },
  },
}
