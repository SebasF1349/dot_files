-- [[ Setting options ]]
-- See `:help vim.o`

-- Set highlight on search
vim.o.hlsearch = false

-- Make line numbers default
vim.wo.number = true

-- Enable mouse mode
vim.o.mouse = "a"

-- Enable break indent
vim.o.breakindent = true

-- Save undo history
vim.o.undofile = true

-- Case-insensitive searching UNLESS \C or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true

-- Keep signcolumn on by default
vim.wo.signcolumn = "yes"

-- Set completeopt to have a better completion experience
vim.o.completeopt = "menuone,noselect"

--vim.opt.guicursor = ""

vim.opt.nu = true
vim.opt.relativenumber = true

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.opt.smartindent = true

vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.textwidth = 0

vim.opt.incsearch = true

vim.opt.termguicolors = true

vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"

vim.opt.timeoutlen = 300
vim.opt.updatetime = 250

vim.opt.title = true

-- Sync clipboard between OS and Neovim.
-- removed as idk how to use and takes 300ms of startup time
--vim.opt.clipboard = 'unnamedplus'

-- split windows
vim.opt.splitright = true -- split vertical window to the right
vim.opt.splitbelow = true -- split horizontal window to the bottom

vim.opt.fileencoding = "utf-8"

vim.opt.iskeyword:append("-")

-- netrw options
vim.g.netrw_banner = 0
vim.g.netrw_liststyle = 3
