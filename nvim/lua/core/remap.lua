-- [[ Basic Keymaps ]]

-- Keymaps for better default experience
-- See `:help vim.keymap.set()`
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Diagnostic keymaps
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous diagnostic message' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next diagnostic message' })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Open floating diagnostic message' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostics list' })

--Remap Escape
vim.keymap.set('i', 'jk', '<Esc>')

--Open explorer
vim.keymap.set('n', '<leader>pv', vim.cmd.Ex)

--Move things around when in visual mode
vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv")
vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv")

--Keep search terms in the middle of the screen
vim.keymap.set('n', 'n', 'nzzzv')
vim.keymap.set('n', 'N', 'Nzzzv')

vim.keymap.set('n', 'Q', '<nop>')

--Make files executable
vim.keymap.set('n', '<leader>x', '<cmd>!chmod +x %<CR>', { silent = true })

-- split screen and navigation
--[[ vim.keymap.set('n', '<leader>v', ':vsplit<CR><C-w>l', { noremap = true })
vim.keymap.set('n', '<leader>h', ':wincmd h<CR>', { noremap = true })
vim.keymap.set('n', '<leader>l', ':wincmd l<CR>', { noremap = true }) ]]

-- window management
vim.keymap.set('n', '<leader>bi', '<C-w>v', { desc = '[B]reak/Split Window [i]Vertically' })   -- split window vertically
vim.keymap.set('n', '<leader>b-', '<C-w>s', { desc = '[B]reak/Split Window [-]Horizontally' }) -- split window horizontally
vim.keymap.set('n', '<leader>be', '<C-w>=', { desc = '[B]reak/Splits [E]qual Size' })          -- make split windows equal width & height
vim.keymap.set('n', '<leader>bx', '<cmd>close<CR>', { desc = '[B]reak/Split [x]Close' })       -- close current split window
-- Move window
vim.keymap.set("n", "<leader>bh", "<C-w>h", { desc = 'Move [B]reak/Split [h]Left' })
vim.keymap.set("n", "<leader>bk", "<C-w>k", { desc = 'Move [B]reak/Split [k]Up' })
vim.keymap.set("n", "<leader>bj", "<C-w>j", { desc = 'Move [B]reak/Split [j]Down' })
vim.keymap.set("n", "<leader>bl", "<C-w>l", { desc = 'Move [B]reak/Split [l]right' })
-- Resize window
vim.keymap.set("n", "<leader>b<", "5<C-w><", { desc = 'Resize [B]reak/Split [<]Smaller Vertically' })
vim.keymap.set("n", "<leader>b>", "5<C-w>>", { desc = 'Resize [B]reak/Split [>]Bigger Vertically' })
vim.keymap.set("n", "<leader>b.", "5<C-w>-", { desc = 'Resize [B]reak/Split [<]Smaller Horizontally' })
vim.keymap.set("n", "<leader>b,", "5<C-w>+", { desc = 'Resize [B]reak/Split [<]Bigger Horizontally' })
