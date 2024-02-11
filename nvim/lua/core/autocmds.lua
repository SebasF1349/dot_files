-- General Settings
local general = vim.api.nvim_create_augroup("General Settings", { clear = true })

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function(data)
    -- buffer is a directory
    local directory = vim.fn.isdirectory(data.file) == 1

    -- change to the directory
    if directory then
      vim.cmd.cd(data.file)
      local builtin = require("telescope.builtin")
      builtin.find_files()
    end
  end,
  group = general,
  desc = "Open Telescope when it's a Directory",
})

vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
  once = true,
  callback = function()
    -- In wsl 2, just install xclip
    -- Ubuntu
    -- sudo apt install xclip
    -- Arch linux
    -- sudo pacman -S xclip
    vim.opt.clipboard = "unnamedplus" -- allows neovim to access the system clipboard
  end,
  group = general,
  desc = "Lazy load clipboard",
})

vim.api.nvim_create_autocmd({ "FocusLost", "BufLeave" }, {
  callback = function()
    if vim.bo.filetype ~= "" and vim.bo.buftype == "" and vim.bo.modified and not vim.bo.readonly then
      vim.cmd("silent!w")
      vim.notify("AutoSave: saved at " .. vim.fn.strftime("%H:%M:%S"), "info")
      if vim.fn.exists(":Format") > 0 then
        vim.cmd.Format()
      end
      if vim.fn.exists(":TailwindSort") then
        vim.cmd("TailwindSort")
      end
    end
  end,
  group = general,
  desc = "Auto Save",
})

-- Highlight on yank
local highlight_group = vim.api.nvim_create_augroup("YankHighlight", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.highlight.on_yank()
  end,
  group = highlight_group,
  pattern = "*",
})

-- Don't auto comment after pressing enter in comment
vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
  callback = function()
    vim.cmd("set formatoptions-=cro")
  end,
})

-- Always enter terminal in insert move
vim.api.nvim_create_autocmd({ "WinEnter" }, {
  pattern = "term://*",
  command = "startinsert",
})

-- Remove line numbers from terminal
vim.api.nvim_create_autocmd({ "TermOpen" }, {
  callback = function()
    vim.cmd("setlocal nonumber")
    vim.cmd("setlocal norelativenumber")
  end,
})

-- Close with 'q' in some windows
vim.api.nvim_create_autocmd({ "FileType" }, {
  pattern = {
    "netrw",
    "Jaq",
    "qf",
    "query",
    "checkhealth",
    "git",
    "help",
    "man",
    "lspinfo",
    "spectre_panel",
    "lir",
    "tsplayground",
    "fugitive",
    "",
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
  end,
})

vim.api.nvim_create_autocmd({ "VimResized" }, {
  callback = function()
    vim.cmd("tabdo wincmd =")
  end,
})

-- sync with system clipboard on focus
vim.api.nvim_create_autocmd({ "FocusGained" }, {
  pattern = { "*" },
  command = [[call setreg("@", getreg("+"))]],
})
vim.api.nvim_create_autocmd({ "FocusLost" }, {
  pattern = { "*" },
  command = [[call setreg("+", getreg("@"))]],
})

-- autoformat on save
vim.api.nvim_create_autocmd("BufWritePre", {
  group = vim.api.nvim_create_augroup("format_on_save", { clear = true }),
  pattern = "*",
  desc = "Run LSP formatting on a file on save",
  callback = function()
    if vim.fn.exists(":Format") > 0 then
      vim.cmd.Format()
    end
  end,
})
-- Old autoformat.lua replaced by the autocmd above
--
-- Use your language server to automatically format your code on save.
-- Adds additional commands as well to manage the behavior
-- return {
--   "neovim/nvim-lspconfig",
--   event = { "BufReadPre", "BufNewFile" },
--   config = function()
--     -- Switch for controlling whether you want autoformatting.
--     --  Use :KickstartFormatToggle to toggle autoformatting on or off
--     local format_is_enabled = true
--     vim.api.nvim_create_user_command("KickstartFormatToggle", function()
--       format_is_enabled = not format_is_enabled
--       print("Setting autoformatting to: " .. tostring(format_is_enabled))
--     end, {})
--
--     -- Create an augroup that is used for managing our formatting autocmds.
--     --      We need one augroup per client to make sure that multiple clients
--     --      can attach to the same buffer without interfering with each other.
--     local _augroups = {}
--     local get_augroup = function(client)
--       if not _augroups[client.id] then
--         local group_name = "kickstart-lsp-format-" .. client.name
--         local id = vim.api.nvim_create_augroup(group_name, { clear = true })
--         _augroups[client.id] = id
--       end
--
--       return _augroups[client.id]
--     end
--
--     -- Whenever an LSP attaches to a buffer, we will run this function.
--     --
--     -- See `:help LspAttach` for more information about this autocmd event.
--     vim.api.nvim_create_autocmd("LspAttach", {
--       group = vim.api.nvim_create_augroup("kickstart-lsp-attach-format", { clear = true }),
--       -- This is where we attach the autoformatting for reasonable clients
--       callback = function(args)
--         local client_id = args.data.client_id
--         local client = vim.lsp.get_client_by_id(client_id)
--         local bufnr = args.buf
--
--         -- Only attach to clients that support document formatting
--         if not client.server_capabilities.documentFormattingProvider then
--           return
--         end
--
--         -- Tsserver usually works poorly. Sorry you work with bad languages
--         -- You can remove this line if you know what you're doing :)
--         if client.name == "tsserver" then
--           return
--         end
--
--         -- Create an autocmd that will run *before* we save the buffer.
--         --  Run the formatting command for the LSP that has just attached.
--         vim.api.nvim_create_autocmd("BufWritePre", {
--           group = get_augroup(client),
--           buffer = bufnr,
--           callback = function()
--             if not format_is_enabled then
--               return
--             end
--
--             vim.lsp.buf.format({
--               async = false,
--               filter = function(c)
--                 return c.id == client.id
--               end,
--             })
--           end,
--         })
--       end,
--     })
--   end,
-- }
