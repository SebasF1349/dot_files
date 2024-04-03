-- Set highlight on search
vim.o.hlsearch = false

-- Make line numbers default
vim.opt.number = true
vim.opt.relativenumber = true

-- Don't show the mode, since it's already in status line
vim.opt.showmode = false

-- Don't show number of lines of characters selected
vim.opt.showcmd = false

-- Enable mouse mode
vim.o.mouse = "a"

-- Enable break indent
vim.o.breakindent = true

-- Save undo history
vim.o.undofile = true

-- Don't store backup while overwriting the file
vim.o.backup = false
vim.o.writebackup = false

-- Case-insensitive searching UNLESS \C or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true

-- Don't show `~` outside of buffer
vim.o.fillchars = "eob: "

-- Reduce command line messages
vim.opt.shortmess("aoOstTWIcCFS")

-- Reduce scroll during window split
vim.o.splitkeep = "screen"

-- Set completeopt to have a better completion experience
vim.o.completeopt = "menuone,noselect"

-- Slight transparency - I like this ones but don't play with catppuccin
-- vim.o.pumblend = 10 -- builtin completion
-- vim.o.winblend = 10 -- floating windows
vim.o.pumheight = 10 -- popup

-- Decreate update time
vim.opt.updatetime = 250
-- Decrease mapped sequence wait time - Displays which-key popup sooner
vim.opt.timeoutlen = 300

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.opt.smartindent = true

vim.opt.wrap = false
vim.opt.linebreak = true
vim.opt.textwidth = 0

vim.opt.incsearch = true

vim.opt.termguicolors = true

vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"

-- Sync clipboard between OS and Neovim.
vim.opt.clipboard = "unnamedplus"

-- split windows
vim.opt.splitright = true -- split vertical window to the right
vim.opt.splitbelow = true -- split horizontal window to the bottom

vim.opt.fileencoding = "utf-8"

-- Preview substitutions live, as you type!
vim.opt.inccommand = "split"

vim.opt.iskeyword:append("-")
vim.opt.wildignore:append({ "*/node_modules/*", "*/.git/*" })

-- netrw options
vim.g.netrw_liststyle = 0
vim.g.netrw_banner = 0
vim.g.netrw_sort_options = "i"
vim.g.netrw_winsize = 20

-- add borders to floating windows
local _border = "rounded"
vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
  border = _border,
})
vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
  border = _border,
})

-- Nicer and less noicy signcolumn
vim.wo.signcolumn = "yes"
vim.opt.statuscolumn = "%s%=%{%v:relnum ? '%r ' : '%l '%}"
vim.diagnostic.config({
  float = { border = _border },
  severity_sort = true,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "",
      [vim.diagnostic.severity.WARN] = "",
      [vim.diagnostic.severity.INFO] = "",
      [vim.diagnostic.severity.HINT] = "",
    },
    numhl = {
      [vim.diagnostic.severity.ERROR] = "ErrorMsg",
      [vim.diagnostic.severity.WARN] = "WarningMsg",
      [vim.diagnostic.severity.INFO] = "InfoMsg",
      [vim.diagnostic.severity.HINT] = "HintMsg",
    },
  },
})

---@diagnostic disable-next-line: duplicate-set-field
vim.lsp.handlers["$/progress"] = function(_, progress, ctx)
  local msg = progress.value

  if msg.kind ~= "end" and msg.kind ~= "begin" then
    return
  end

  local out = ""

  local client = vim.lsp.get_client_by_id(ctx.client_id)
  if client and client.name then
    out = out .. "[" .. client.name .. "]"
  end

  local title = msg.title or ""
  if title ~= "" then
    out = out .. " " .. title
  end

  if msg.kind == "end" then
    out = out .. " done"
  elseif msg.kind == "begin" then
    out = out .. " starting..."
  end

  vim.api.nvim_command([[echo "]] .. out .. [["]])
end

-- Disable health checks for these providers.
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_node_provider = 0
