-- UPDATED KICKSTARTER UNTIL 2024-05-11

if vim.g.vscode then
  vim.cmd([[source $HOME\.vimrc]])
  return
end

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

require('core')
