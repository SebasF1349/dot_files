-- netrw options
vim.g.netrw_liststyle = 3
vim.g.netrw_banner = 0
vim.g.netrw_sort_options = 'i'
vim.g.netrw_winsize = 25
vim.g.netrw_preview = 1
vim.g.netrw_altfile = 1

vim.keymap.set('n', '<leader>n', function()
  local function getPath(str)
    return str:match('(.*[/\\])')
  end
  local currentfile = getPath(vim.fn.expand('%:p'))
  vim.cmd('Lexplore! ' .. currentfile)
end, { desc = 'Open Explorer [N]etrw' })

local netrw = vim.api.nvim_create_augroup('NetRW', { clear = true })
vim.api.nvim_create_autocmd('FileType', {
  group = netrw,
  pattern = 'netrw',
  callback = function()
    vim.o.nu = true
    vim.o.rnu = true
    vim.keymap.set(
      'n',
      'w',
      '<cmd>Ex ' .. vim.fn.getcwd() .. '<CR>',
      { desc = 'Move to C[W]D', noremap = true, silent = true, buffer = true }
    )
    vim.keymap.set(
      'n',
      'm',
      'gn',
      { desc = '[M]ove to selected directory', noremap = true, silent = true, buffer = true }
    )
    vim.keymap.set('n', '<C-C>', '<cmd>bdel<CR>', { noremap = true, silent = true, buffer = true })
    vim.keymap.set('n', 'q', '<cmd>bdel<CR>', { noremap = true, silent = true, buffer = true })
    vim.keymap.set('n', 'h', 'gh', { desc = 'Toggle [H]idden files', remap = true, silent = true, buffer = true })
    vim.keymap.set('n', 'r', 'R', { desc = '[R]ename', remap = true, silent = true, buffer = true })
    local unbinds = {
      '<del>',
      '<c-r>',
      '<c-tab>',
      'a',
      'C',
      'gb',
      'gf',
      'gp',
      'i',
      'I',
      'mb',
      'md',
      'me',
      'mg',
      'mh',
      'mr',
      'mT',
      'mv',
      'mx',
      'mX',
      'mz',
      'o',
      'O',
      'P',
      'qb',
      'qf',
      'qF',
      'qL',
      's',
      'S',
      't',
      'u',
      'U',
      'v',
      'x',
      'X',
    }
    for _, value in pairs(unbinds) do
      vim.keymap.set('n', value, function()
        vim.notify("Keybind '" .. value .. "' has been removed", vim.log.levels.WARN)
      end, { noremap = true, silent = true, buffer = true })
    end
  end,
  desc = 'NetRW keymaps and options',
})
