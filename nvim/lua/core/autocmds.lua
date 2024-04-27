-- General Settings
local general = vim.api.nvim_create_augroup("General Settings", { clear = true })

vim.api.nvim_create_autocmd({ "BufReadPost" }, {
  pattern = "*",
  -- command = 'silent! normal! g`"zv',
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    if mark[1] > 1 and mark[1] <= vim.api.nvim_buf_line_count(0) then
      vim.api.nvim_win_set_cursor(0, mark)
    end
  end,
  group = general,
  desc = "Open file at the last position it was edited earlier",
})

vim.api.nvim_create_autocmd({ "BufLeave", "FocusGained" }, {
  callback = function(args)
    if vim.bo.filetype ~= "" and vim.bo.buftype == "" and vim.bo.modified and not vim.bo.readonly then
      require("conform").format({ bufnr = args.buf })
      -- idk why the auto-sort command doesn't work, even with `:w`
      if vim.fn.exists(":TailwindSort") > 0 then
        vim.cmd("TailwindSort")
      end
      vim.cmd("silent! wa")
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

vim.api.nvim_create_autocmd({ "TermOpen" }, {
  callback = function()
    vim.cmd("startinsert")
    vim.cmd("setlocal nonumber")
    vim.cmd("setlocal norelativenumber")
  end,
  group = general,
  desc = "Remove line numbers from terminal and start on insert",
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
  desc = "Resize splits after resizing nvim",
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

vim.api.nvim_create_autocmd({ "FileType" }, {
  pattern = "markdown",
  callback = function()
    vim.opt_local.textwidth = 0
    vim.opt_local.columns = 80
    vim.opt_local.colorcolumn = "81"
    vim.opt_local.wrap = true
    vim.opt_local.wrapmargin = true
    vim.opt_local.linebreak = true
    vim.opt_local.spell = true
    vim.opt_local.spelllang = { "es", "en" }
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.expandtab = true
  end,
  desc = "Markdown defaults",
})
