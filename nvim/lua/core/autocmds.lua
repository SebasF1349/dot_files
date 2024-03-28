-- General Settings
local general = vim.api.nvim_create_augroup("General Settings", { clear = true })

vim.api.nvim_create_autocmd({ "VimEnter" }, {
  callback = function(data)
    local directory = vim.fn.isdirectory(data.file) == 1
    if directory then
      require("telescope") -- needed of error message for loop of something
      require("utils.telescopeFiles").Telescope_git_or_files()
    end
  end,
  group = general,
  desc = "Open Telescope when it's a Directory",
})

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

vim.api.nvim_create_autocmd({ "VimLeave" }, {
  callback = function()
    require("utils.setVar").Set_user_var("IS_NVIM", false)
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

vim.api.nvim_create_autocmd({ "BufLeave", "InsertLeave" }, {
  callback = function(args)
    if vim.bo.filetype ~= "" and vim.bo.buftype == "" and vim.bo.modified and not vim.bo.readonly then
      require("conform").format({ bufnr = args.buf })
      -- idk why the auto-sort command doesn't work, even with `:w`
      if vim.fn.exists(":TailwindSort") > 0 then
        vim.cmd("TailwindSort")
      end
      vim.cmd("silent! wa")
      -- vim.notify("AutoSave: saved at " .. vim.fn.strftime("%H:%M:%S"), vim.log.levels.INFO)
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
    vim.opt_local.textwidth = 80
    vim.opt_local.colorcolumn = "81"
    vim.opt_local.wrap = true
    vim.opt_local.spell = true
    vim.opt_local.spelllang = "es"
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.expandtab = true
  end,
})

-- copied from https://github.com/Aasim-A/scrollEOF.nvim
vim.api.nvim_create_autocmd({ "CursorMoved", "WinScrolled" }, {
  group = general,
  pattern = "*",
  callback = function(data)
    if data.event == "WinScrolled" then
      local win_id = vim.api.nvim_get_current_win()
      local win_event = vim.v.event[tostring(win_id)]
      if win_event ~= nil and win_event.topline <= 0 then
        return
      end
    end

    local win_height = vim.fn.winheight(0)
    local win_cur_line = vim.fn.winline()
    local scrolloff = math.min(vim.o.scrolloff, math.floor(win_height / 2))
    local visual_distance_to_eof = win_height - win_cur_line

    if visual_distance_to_eof < scrolloff then
      local win_view = vim.fn.winsaveview()
      vim.fn.winrestview({ topline = win_view.topline + scrolloff - visual_distance_to_eof })
    end
  end,
})
