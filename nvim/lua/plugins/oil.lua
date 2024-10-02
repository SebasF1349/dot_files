return {
  'stevearc/oil.nvim',
  -- event = { 'VimEnter */*,.*', 'BufNew */*,.*' },
  -- init = function()
  -- local previous_buffer_name
  -- vim.api.nvim_create_autocmd('BufEnter', {
  -- pattern = '*',
  -- callback = function()
  -- vim.schedule(function()
  -- local buffer_name = vim.api.nvim_buf_get_name(0)
  -- if vim.fn.isdirectory(buffer_name) == 0 then
  -- _, previous_buffer_name = pcall(vim.fn.expand, '#:p:h')
  -- return
  -- end

  -- Avoid reopening when exiting without selecting a file
  -- if previous_buffer_name == buffer_name then
  -- previous_buffer_name = nil
  -- return
  -- else
  -- previous_buffer_name = buffer_name
  -- end

  -- Ensure no buffers remain with the directory name
  -- vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = 0 })
  -- require('oil').open(vim.fn.expand('%:p:h'))
  -- end)
  -- end,
  -- desc = 'Oil replacement for Netrw',
  -- })
  -- end,
  cmd = { 'Oil' },
  -- stylua: ignore
  keys = {
    { '-', function() require('oil').open() end, { desc = 'Open parent directory' } },
    { '_', function() require('oil').open(vim.fn.getcwd()) end, { desc = 'Open cwd' } },
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
