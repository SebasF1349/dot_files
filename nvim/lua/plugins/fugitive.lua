vim.keymap.set('n', '<leader>gg', '<cmd>tab G<CR>]]', { desc = 'Open fu[G]itive in a new tab', remap = true })
vim.keymap.set('n', '<leader>gd', '<cmd>Gvdiffsplit<CR>', { desc = '[D]iff Current File' })
vim.keymap.set('n', '<leader>gb', '<cmd>Git blame<cr>', { desc = 'fu[G]itive [B]lame' })
vim.keymap.set('n', '<leader>gl', '<cmd>tab Git log -50 --oneline<cr>', { desc = 'fu[G]itive [L]og' })
vim.keymap.set(
  'x',
  '<leader>gl',
  ":<C-u>execute 'Git log -L ' . line(\"'<\") . ',' . line(\"'>\") . ':%'<CR>",
  { desc = 'fu[G]itive [L]og' }
)
vim.keymap.set('n', '<leader>gL', '<cmd>tab Git log -50 --oneline %<cr>', { desc = 'fu[G]itive [L]og File' })

return {
  'tpope/vim-fugitive',
  cmd = { 'G', 'Git', 'Gvdiffsplit', 'Gdiffsplit' },
  config = function()
    local function diffModeMap(key, cmd, desc)
      vim.keymap.set({ 'n', 'x' }, key, function()
        return not vim.wo.diff and 'normal! ' .. key
          or (vim.api.nvim_get_mode().mode == 'n' and '?<<<<<<<<CR>V/>>>>>>><CR>' .. cmd or cmd)
      end, { desc = desc, silent = true, expr = true })
    end
    diffModeMap('gh', ':diffget //2 <CR>', 'Git: get lhs of diff')
    diffModeMap('gl', ':diffget //3 <CR>', 'Git: get rhs of diff')
  end,
}
