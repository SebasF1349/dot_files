vim.keymap.set('n', '<leader>gg', '<cmd>tab Git<CR>]]', { desc = 'Open fu[G]itive in a new tab', remap = true })
vim.keymap.set('n', '<leader>gd', '<cmd>Gvdiffsplit<CR>', { desc = '[D]iff Current File' })
vim.keymap.set('n', '<leader>gb', '<cmd>Git blame<cr>', { desc = 'fu[G]itive [B]lame' })

local log_cmd = 'tab Git log -50 --graph --decorate --pretty=pf'
vim.keymap.set('n', '<leader>gl', '<cmd>' .. log_cmd .. '<cr>', { desc = 'fu[G]itive [L]og' })
vim.keymap.set(
  'x',
  '<leader>gl',
  ":<C-u>execute 'Git log -L ' . line(\"'<\") . ',' . line(\"'>\") . ':%'<CR>",
  { desc = 'fu[G]itive [L]og' }
)
vim.keymap.set('n', '<leader>gL', '<cmd>' .. log_cmd .. ' %<cr>', { desc = 'fu[G]itive [L]og File' })
vim.keymap.set('n', '<leader>gr', '<cmd>' .. log_cmd .. ' --numstat<cr>', { desc = 'fu[G]itive [R]eview Log' })
vim.keymap.set(
  'n',
  '<leader>gR',
  '<cmd>tab Git log -50 --oneline --patch<cr>',
  { desc = 'fu[G]itive Detailed [R]eview Log' }
)

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
