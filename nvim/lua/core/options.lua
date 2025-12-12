vim.o.updatetime = 2000
vim.o.timeoutlen = 300

vim.o.scrolloff = 8
vim.o.sidescrolloff = 20

vim.o.cursorline = true
vim.o.cursorlineopt = 'number'

-- Disable cursor blinking in terminal mode.
-- Using the same cursor for terminal as in insert mode is more vimmish but less terminalish
vim.o.guicursor = 'n-v-c-sm:block,i-ci-ve:ver25,r-cr-o:hor20,t:ver25-TermCursor'

vim.o.number = true
vim.o.relativenumber = true

vim.o.signcolumn = 'yes'
vim.o.numberwidth = 3
vim.o.statuscolumn = '%=%{% v:virtnum > 0 ? "" : v:lnum %}%=%s'

vim.o.mouse = ''
vim.keymap.set('', '<up>', '<nop>', { noremap = true })
vim.keymap.set('', '<down>', '<nop>', { noremap = true })
vim.keymap.set('i', '<up>', '<nop>', { noremap = true })
vim.keymap.set('i', '<down>', '<nop>', { noremap = true })

vim.o.fileencoding = 'utf-8'
vim.opt.iskeyword:append('-')

vim.o.undofile = true
vim.o.backup = false
vim.o.writebackup = false
vim.o.autoread = true

vim.o.tabstop = 4
vim.o.softtabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true

vim.o.formatoptions = 'qjl1'
vim.o.wrap = false
vim.o.linebreak = true
vim.o.textwidth = 0
vim.o.smoothscroll = true

vim.o.smartindent = true
vim.o.breakindent = true

vim.o.helpheight = 0

vim.o.winborder = 'solid'

vim.o.splitright = true
vim.o.splitbelow = true

vim.o.diffopt = 'internal,filler,closeoff,indent-heuristic,inline:char,linematch:60,algorithm:histogram'

vim.o.pumheight = 10

vim.o.jumpoptions = "view,clean"

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

vim.o.foldtext = 'v:lua.custom_foldtext()'
vim.o.foldlevelstart = 99

vim.opt.fillchars = {
  eob = ' ',
  fold = ' ',
  foldopen = ' ',
  foldclose = ' ',
  foldsep = ' ',
}

vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_node_provider = 0
