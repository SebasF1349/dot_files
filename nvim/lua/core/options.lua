-- Disable cursor blinking in terminal mode.
-- Using the same cursor for terminal as in insert mode is more vimmish but less terminalish
vim.o.guicursor = 'n-v-c-sm:block,i-ci-ve:ver25,r-cr-o:hor20,t:ver25-TermCursor'

vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.showmode = false
vim.opt.showcmd = false

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
vim.o.helpheight = 0

vim.o.ignorecase = true
vim.o.smartcase = true

vim.opt.shortmess = 'aoOstTWIcCF'
vim.o.formatoptions = 'qjl1'

vim.o.winborder = 'solid'

-- vim.o.completeopt = 'menu,menuone,noselect,fuzzy,popup'

vim.o.pumheight = 10

vim.cmd('packadd nohlsearch')
vim.opt.updatetime = 2000
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

vim.o.diffopt = 'internal,filler,closeoff,indent-heuristic,linematch:60,algorithm:histogram,inline:char'

vim.opt.fileencoding = 'utf-8'

vim.opt.iskeyword:append('-')

-- vim.opt.wildchar = (''):byte()
vim.opt.wildoptions = 'pum,tagfile,fuzzy'
vim.opt.wildmode = 'longest:full,full'
-- vim.opt.wildignore:append({ '*/.git/*' }) -- git
-- vim.opt.wildignore:append({ '*/node_modules/*' }) -- web
-- vim.opt.wildignore:append({ '*/target/*' }) -- java

vim.opt.smoothscroll = true

-- https://new.reddit.com/r/neovim/comments/1fzn1zt/custom_fold_text_function_with_treesitter_syntax/
local function fold_virt_text(result, lnum, trim)
  local str = vim.fn.getline(lnum + 1):gsub('\t', string.rep(' ', vim.o.tabstop))
  local coloff = trim and #(str:match('^(%s+)') or '') or 0
  str = trim and vim.trim(str) or str
  local text = ''
  local hl
  for i = 1, #str do
    local char = str:sub(i, i)
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
  local result = {}
  fold_virt_text(result, vim.v.foldstart - 1)
  local number_lines = vim.v.foldend - vim.v.foldstart
  table.insert(result, { ' [ ' .. number_lines .. ' lines ] ', 'Delimiter' })
  if vim.o.filetype ~= 'markdown' then
    fold_virt_text(result, vim.v.foldend - 1, true)
  end
  return result
end

vim.opt.foldtext = 'v:lua.custom_foldtext()'
vim.opt.foldlevelstart = 99

vim.opt.fillchars = {
  eob = ' ',
  fold = ' ',
  foldopen = ' ',
  foldclose = ' ',
  foldsep = ' ',
}

vim.opt.signcolumn = 'yes'
-- vim.opt.statuscolumn = '%s%=%{% v:virtnum > 0 ? "" : v:relnum ? v:relnum : v:lnum %} '
vim.opt.numberwidth = 3
vim.opt.statuscolumn = '%=%{% v:virtnum > 0 ? "" : v:lnum %}%=%s'

vim.opt.cursorline = true
vim.opt.cursorlineopt = 'number'

-- Diagnostics
vim.diagnostic.config({
  underline = false,
  float = {
    scope = 'cursor',
    severity_sort = true,
    source = false,
    header = '',
    prefix = '',
    format = function(d)
      return '- ' .. d.message
    end,
    suffix = function(d)
      return string.format('[%s: %s]', d.source, d.code), ''
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
      [vim.diagnostic.severity.ERROR] = 'DiagnosticSignError',
      [vim.diagnostic.severity.WARN] = 'DiagnosticSignWarn',
      [vim.diagnostic.severity.INFO] = 'DiagnosticSignInfo',
      [vim.diagnostic.severity.HINT] = 'DiagnosticSignHint',
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
