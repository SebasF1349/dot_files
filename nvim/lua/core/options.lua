-- Set highlight on search
vim.o.hlsearch = false

-- Make line numbers default
vim.opt.number = true
vim.opt.relativenumber = true

-- Don't show the mode, since it's already in status line
vim.opt.showmode = false

-- Don't show number of lines of characters selected
vim.opt.showcmd = false

-- Disable mouse mode
vim.o.mouse = ''
vim.keymap.set('', '<up>', '<nop>', { noremap = true })
vim.keymap.set('', '<down>', '<nop>', { noremap = true })
vim.keymap.set('i', '<up>', '<nop>', { noremap = true })
vim.keymap.set('i', '<down>', '<nop>', { noremap = true })

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
vim.o.fillchars = 'eob: '

-- Reduce command line messages
vim.opt.shortmess = 'aoOstTWICF'

-- Reduce scroll during window split
vim.o.splitkeep = 'screen'

-- Set completeopt to have a better completion experience
vim.o.completeopt = 'menu,menuone'

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
-- Preview substitutions live, as you type!
vim.opt.inccommand = 'split'

vim.opt.termguicolors = true

vim.opt.scrolloff = 8
vim.opt.signcolumn = 'yes'

-- split windows
vim.opt.splitright = true
vim.opt.splitbelow = true

vim.opt.fileencoding = 'utf-8'

vim.opt.iskeyword:append('-')

-- cmdline autocomplete
vim.opt.wildchar = 12 -- <C-l>
vim.opt.wildmode = 'longest:full,full'
vim.opt.wildignore:append({ '*/node_modules/*', '*/.git/*' })

vim.opt.smoothscroll = true

-- folds
vim.opt.foldmethod = 'expr'
vim.opt.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
vim.opt.foldtext = ''
vim.opt.foldlevelstart = 99

-- add borders to floating windows
local _border = 'rounded'
vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(vim.lsp.handlers.hover, {
  border = _border,
})
vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(vim.lsp.handlers.signature_help, {
  border = _border,
})

-- Nicer and less noicy signcolumn
vim.wo.signcolumn = 'yes'
vim.opt.statuscolumn = '%s%=%{%v:relnum ? v:relnum : v:lnum %} '

-- Change color to current line number
vim.opt.cursorline = true
vim.opt.cursorlineopt = 'number'

-- Diagnostics
vim.diagnostic.config({
  underline = false,
  float = {
    border = _border,
    scope = 'cursor',
    severity_sort = true,
    source = true,
  },
  jump = { float = true },
  severity_sort = true,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = '',
      [vim.diagnostic.severity.WARN] = '',
      [vim.diagnostic.severity.INFO] = '',
      [vim.diagnostic.severity.HINT] = '',
    },
    numhl = {
      [vim.diagnostic.severity.ERROR] = 'ErrorMsg',
      [vim.diagnostic.severity.WARN] = 'WarningMsg',
      [vim.diagnostic.severity.INFO] = 'InfoMsg',
      [vim.diagnostic.severity.HINT] = 'HintMsg',
    },
  },
})

-- LSP progress messages on cmdline
vim.lsp.handlers['$/progress'] = function(_, progress, ctx)
  local msg = progress.value

  if msg.kind ~= 'end' and msg.kind ~= 'begin' then
    return
  end

  local out = ''

  local client = vim.lsp.get_client_by_id(ctx.client_id)
  if client and client.name then
    out = out .. '[' .. client.name .. ']'
  end

  local title = msg.title or ''
  if title ~= '' then
    out = out .. ' ' .. title
  end

  if msg.kind == 'end' then
    out = out .. ' done'
  elseif msg.kind == 'begin' then
    out = out .. ' starting...'
  end

  vim.notify(out, vim.log.levels.INFO)
end

-- overwrite default _get_url() to add github repos on plugins and google search
---@diagnostic disable-next-line: duplicate-set-field
vim.ui._get_url = function()
  if vim.bo.filetype == 'markdown' then
    local range = vim.api.nvim_win_get_cursor(0)
    vim.treesitter.get_parser():parse(range)
    -- marking the node as `markdown_inline` is required. Setting it to `markdown` does not
    -- work.
    local current_node = vim.treesitter.get_node({ lang = 'markdown_inline' })
    while current_node do
      local type = current_node:type()
      if type == 'inline_link' or type == 'image' then
        local child = assert(current_node:named_child(1))
        return vim.treesitter.get_node_text(child, 0)
      end
      current_node = current_node:parent()
    end
  end

  local url = vim._with({ go = { isfname = vim.o.isfname .. ',@-@' } }, function()
    return vim.fn.expand('<cfile>')
  end)

  local is_uri = url:match('%w+:')
  local is_repo = url:match('%w+/%w+') and vim.fn.count(url, '/') == 1
  local is_dir = url:match('/%w+') or url:match('\\%w+')
  if not is_uri then
    if vim.bo.filetype == 'lua' and is_repo then
      url = ('https://github.com/%s'):format(url)
    elseif not is_dir then
      url = ('https://google.com/search?q=%s'):format(vim.fn.expand('<cword>'))
    end
  end

  return url
end

-- Disable health checks for these providers.
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_node_provider = 0
