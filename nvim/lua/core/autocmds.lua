-- General Settings
local general = vim.api.nvim_create_augroup("General Settings", { clear = true })

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function(data)
    -- buffer is a directory
    local directory = vim.fn.isdirectory(data.file) == 1
    -- change to the directory
    if directory then
      vim.cmd.cd(data.file)
      require("telescope.builtin").git_files()
    end
  end,
  group = general,
  desc = "Open Telescope when it's a Directory",
})

vim.api.nvim_create_autocmd("VimLeave", {
  callback = function()
    set_user_var("IS_NVIM", false)
  end,
  group = general,
  desc = "Set Global Variable to false for Wezterm to use",
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
      vim.cmd("silent! wa")
      vim.notify("AutoSave: saved at " .. vim.fn.strftime("%H:%M:%S"), "info")
      if vim.fn.exists(":Format") > 0 then
        vim.cmd.Format()
      end
      if vim.fn.exists(":TailwindSort") > 0 then
        vim.cmd("TailwindSort")
      end
    end
  end,
  group = general,
  desc = "Auto Save",
})

vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.highlight.on_yank()
  end,
  group = general,
  desc = "Highlight on yank",
})

vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
  callback = function()
    vim.cmd("set formatoptions-=cro")
  end,
  group = general,
  desc = "Don't auto comment after pressing enter in comment",
})

vim.api.nvim_create_autocmd({ "WinEnter" }, {
  pattern = "term://*",
  command = "startinsert",
  group = general,
  desc = "Always enter terminal in insert mode",
})

vim.api.nvim_create_autocmd({ "TermOpen" }, {
  callback = function()
    vim.cmd("setlocal nonumber")
    vim.cmd("setlocal norelativenumber")
  end,
  group = general,
  desc = "Remove line numbers from terminal",
})

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
  group = general,
  desc = "Close with 'q' in some windows",
})

vim.api.nvim_create_autocmd({ "VimResized" }, {
  callback = function()
    vim.cmd("tabdo wincmd =")
  end,
  group = general,
  desc = "Don't auto comment after pressing enter in comment",
})

vim.api.nvim_create_autocmd({ "FocusGained" }, {
  pattern = { "*" },
  command = [[call setreg("@", getreg("+"))]],
  group = general,
  desc = "Sync with system clipboard on focus",
})
vim.api.nvim_create_autocmd({ "FocusLost" }, {
  pattern = { "*" },
  command = [[call setreg("+", getreg("@"))]],
  group = general,
  desc = "Sync with system clipboard on focus",
})

vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  callback = function()
    if vim.fn.exists(":Format") > 0 then
      vim.cmd.Format()
    end
  end,
  group = general,
  desc = "Run LSP formatting on a file on save",
})

vim.api.nvim_create_autocmd({ "CmdWinEnter" }, {
  callback = function()
    vim.cmd("quit")
  end,
  group = general,
  desc = "Automagically close command-line window.",
})

vim.api.nvim_create_autocmd({ "BufWritePre" }, {
  callback = function(event)
    if event.match:match("^%w%w+://") then
      return
    end
    local file = vim.loop.fs_realpath(event.match) or event.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
  end,
  group = general,
  desc = "Create dir when saving a file when an intermediate directory is missing.",
})
