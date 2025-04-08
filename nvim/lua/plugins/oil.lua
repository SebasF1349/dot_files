return {
  'stevearc/oil.nvim',
  cmd = { 'Oil' },
  -- stylua: ignore
  keys = {
    { '-', function() require('oil').open() end, { desc = 'Open parent directory' } },
    { '_', function() require('oil').open(vim.uv.cwd()) end, { desc = 'Open cwd' } },
  },
  opts = {
    default_file_explorer = true,
    keymaps = {
      ['g?'] = 'actions.show_help',
      ['<CR>'] = 'actions.select',
      ['<C-v>'] = { 'actions.select', opts = { vertical = true }, desc = 'Open the entry in a vertical split' },
      ['<C-s>'] = { 'actions.select', opts = { horizontal = true }, desc = 'Open the entry in a horizontal split' },
      ['<C-t>'] = { 'actions.select', opts = { tab = true }, desc = 'Open the entry in new tab' },
      ['L'] = 'actions.select',
      ['H'] = 'actions.parent',
      ['<C-p>'] = 'actions.preview',
      ['<C-c>'] = 'actions.close',
      ['q'] = 'actions.close',
      ['<C-r>'] = 'actions.refresh',
      ['-'] = 'actions.parent',
      ['_'] = 'actions.open_cwd',
      ['`'] = 'actions.cd',
      ['~'] = { 'actions.cd', opts = { scope = 'tab' }, desc = ':tcd to the current oil directory' },
      ['gs'] = 'actions.change_sort',
      ['gx'] = 'actions.open_external',
      ['g.'] = 'actions.toggle_hidden',
      ['g\\'] = 'actions.toggle_trash',
    },
    use_default_keymaps = false,
    delete_to_trash = true,
    skip_confirm_for_simple_edits = true,
    view_options = {
      show_hidden = true,
      is_always_hidden = function(name, _)
        return name == '..' or name == '.git'
      end,
    },
    lsp_file_methods = {
      -- test if this works, looks like lua and java don't
      timeout_ms = 5000,
      autosave_changes = false,
    },
  },
}
