local oss = require('utils.os')

local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable', -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup({ { import = 'plugins' } }, {
  install = {
    colorscheme = { 'catppuccin' },
  },
  change_detection = {
    notify = false,
  },
  defaults = {
    lazy = true,
    version = false,
    autocmds = true,
    keymaps = false,
  },
  rocks = { enabled = false },
  dev = {
    path = oss.joinpath(vim.fn.stdpath('config'), 'custom'),
  },
  performance = {
    rtp = {
      disabled_plugins = {
        '2html_plugin',
        'bugreport',
        -- "compiler",
        'ftplugin',
        'getscript',
        'getscriptPlugin',
        'gzip',
        'logipat',
        -- 'matchit',
        'matchparen',
        'netrwPlugin',
        'optwin',
        'rplugin',
        'rrhelper',
        -- "spellfile_plugin",
        'synmenu',
        'syntax',
        'tar',
        'tarPlugin',
        'tohtml',
        'tutor',
        'vimball',
        'vimballPlugin',
        'zip',
        'zipPlugin',
      },
    },
  },
})
