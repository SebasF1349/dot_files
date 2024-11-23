local nvim_version = require('utils.nvim-version')

vim.o.hlsearch = false

vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.showmode = false
vim.opt.showcmd = false

vim.o.equalalways = true
vim.o.eadirection = 'hor'

vim.o.mouse = ''
vim.keymap.set('', '<up>', '<nop>', { noremap = true })
vim.keymap.set('', '<down>', '<nop>', { noremap = true })
vim.keymap.set('i', '<up>', '<nop>', { noremap = true })
vim.keymap.set('i', '<down>', '<nop>', { noremap = true })

vim.o.breakindent = true

vim.o.undofile = true
vim.o.backup = false
vim.o.writebackup = false
vim.o.autoread = true

vim.o.ignorecase = true
vim.o.smartcase = true

vim.o.fillchars = 'eob: '

vim.opt.shortmess = 'aoOstTWIcCF'
vim.o.formatoptions = 'qjl1'

if nvim_version.is_nightly() then
  vim.o.completeopt = 'menu,menuone,noinsert,noselect,fuzzy,popup'
else
  vim.o.completeopt = 'menu,menuone,noinsert,noselect'
end

vim.o.pumheight = 10

vim.opt.updatetime = 250
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
vim.opt.inccommand = 'split'

vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 20
vim.opt.signcolumn = 'yes'

vim.opt.splitright = true
vim.opt.splitbelow = true

vim.opt.fileencoding = 'utf-8'

vim.opt.iskeyword:append('-')

-- vim.opt.wildchar = (''):byte()
vim.opt.wildoptions = 'pum,tagfile,fuzzy'
vim.opt.wildmode = 'longest:full,full'
-- vim.opt.wildignore:append({ '*/.git/*' }) -- git
-- vim.opt.wildignore:append({ '*/node_modules/*' }) -- web
-- vim.opt.wildignore:append({ '*/target/*' }) -- java

vim.opt.smoothscroll = true

vim.opt.foldmethod = 'expr'
vim.opt.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
vim.opt.foldlevelstart = 99

-- https://new.reddit.com/r/neovim/comments/1fzn1zt/custom_fold_text_function_with_treesitter_syntax/
local function fold_virt_text(result, s, lnum, coloff)
  if not coloff then
    coloff = 0
  end
  local text = ''
  local hl
  for i = 1, #s do
    local char = s:sub(i, i)
    local hls = vim.treesitter.get_captures_at_pos(0, lnum, coloff + i - 1)
    local _hl = hls[#hls]
    if _hl then
      local new_hl = '@' .. _hl.capture
      if new_hl ~= hl then
        table.insert(result, { text, hl })
        text = ''
        hl = nil
      end
      text = text .. char
      hl = new_hl
    else
      text = text .. char
    end
  end
  table.insert(result, { text, hl })
end

function _G.custom_foldtext()
  local start = vim.fn.getline(vim.v.foldstart):gsub('\t', string.rep(' ', vim.o.tabstop))
  local end_str = vim.fn.getline(vim.v.foldend)
  local end_ = vim.trim(end_str)
  local result = {}
  fold_virt_text(result, start, vim.v.foldstart - 1)
  local number_lines = vim.v.foldend - vim.v.foldstart
  table.insert(result, { ' [ ' .. number_lines .. ' lines ] ', 'Delimiter' })
  fold_virt_text(result, end_, vim.v.foldend - 1, #(end_str:match('^(%s+)') or ''))
  return result
end

vim.opt.foldtext = 'v:lua.custom_foldtext()'
-- vim.opt.foldtext = ''

vim.opt.fillchars:append({
  fold = ' ',
  foldopen = ' ',
  foldclose = ' ',
  foldsep = ' ',
})

vim.opt.signcolumn = 'yes'
-- vim.opt.statuscolumn = '%s%=%{% v:virtnum > 0 ? "" : v:relnum ? v:relnum : v:lnum %} '
vim.opt.numberwidth = 3
vim.opt.statuscolumn = '%=%{% v:virtnum > 0 ? "" : v:lnum %}%=%s'

vim.opt.cursorline = true
vim.opt.cursorlineopt = 'number'

local function capitalize(str)
  return str:lower():gsub('^%l', string.upper)
end

-- Diagnostics
vim.diagnostic.config({
  underline = false,
  float = {
    scope = 'cursor',
    severity_sort = true,
    source = false,
    header = '',
    prefix = function(d)
      local severity_name = capitalize(vim.diagnostic.severity[d.severity])
      return '-' .. ' ', 'DiagnosticSign' .. severity_name
    end,
    format = function(d)
      return d.message --.. ' '
    end,
    suffix = function(d)
      return string.format('[%s: %s]', d.source, d.code), 'Underlined'
    end,
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
---@diagnostic disable-next-line: duplicate-set-field
vim.lsp.handlers['$/progress'] = function(_, progress, ctx)
  local msg = progress.value

  if msg.kind ~= 'end' and msg.kind ~= 'begin' then
    return
  end

  local client = vim.lsp.get_client_by_id(ctx.client_id)
  local client_name = client and client.name and '[' .. client.name .. ']' or ''

  local title = msg.title and ' ' .. msg.title or ''

  local kind = msg.kind == 'end' and 'done' or 'starting...'

  local out = string.format('%s%s %s', client_name, title, kind)

  vim.notify(out, vim.log.levels.INFO)
end

-- Disable health checks for these providers.
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_node_provider = 0
