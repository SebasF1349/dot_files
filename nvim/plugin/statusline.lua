local api, fn, fs, cwd = vim.api, vim.fn, vim.fs, vim.uv.cwd
local mocha = require('catppuccin.palettes').get_palette('mocha')
local signs = require('utils.ui').diagnostic_icons_num
local args = require('modules.args')

local statusline_group = api.nvim_create_augroup('statusline', { clear = true })

---- Highlights ----
local function fg_of(name)
  return api.nvim_get_hl(0, { name = name, link = false })['fg']
end

local function set_highlights()
  local bg = api.nvim_get_hl(0, { name = 'StatusLine', link = false })['bg'] or mocha.surface0
  local groups = {
    SLNormal = fg_of('Normal'),
    SLSeparator = mocha.blue,
    -- modes
    SLModeN = mocha.blue,
    SLModeI = mocha.green,
    SLModeT = mocha.teal,
    SLModeC = mocha.peach,
    SLModeV = mocha.mauve,
    SLModeR = mocha.red,
    SLModeO = mocha.overlay2,
    SLModeS = mocha.yellow,
    -- file
    SLActiveBuffer = fg_of('Normal'),
    SLInactiveBuffer = fg_of('Comment'),
    -- context
    SLContext = fg_of('CursorLineNr'),
    -- diagnostics
    SLDiagError = fg_of('DiagnosticError'),
    SLDiagWarn = fg_of('DiagnosticWarn'),
    SLDiagInfo = fg_of('DiagnosticInfo'),
    SLDiagHint = fg_of('DiagnosticHint'),
    SLDiagExternal = fg_of('Comment'),
    -- git
    SLBranch = fg_of('Special'),
  }
  for name, fg in pairs(groups) do
    api.nvim_set_hl(0, name, { bg = bg, fg = fg })
  end
end

set_highlights()

---- MODE ----
local function mode()
  -- NOTE: apparently it's not possible to get operator pending mode or it flickers with normal
  local mode_char = api.nvim_get_mode().mode
  mode_char = mode_char == '' and 'V' or mode_char:sub(1, 1):upper()
  return string.format('%%#SLMode%s#%s', mode_char, mode_char)
end

---- FILELIST ----
local cached_filelist_info = ''

local function file()
  if api.nvim_win_get_config(0).relative ~= '' then
    return cached_filelist_info
  end
  local ftype = vim.o.filetype
  local label, title
  if ftype == 'help' then
    title, label = fn.expand('%:t:r:r'), 'Help'
  elseif ftype == 'checkhealth' then
    title, label = '', 'CheckHealth'
  elseif ftype == 'fugitive' then
    title, label = fn.expand('%:h:h:t'), 'Fugitive'
  elseif ftype == 'gitcommit' then
    title, label = 'Git Commit Message', 'Fugitive'
  elseif ftype == 'qf' then
    local isLoclist = fn.getloclist(0, { filewinid = 1 }).filewinid ~= 0
    label = isLoclist and 'Location List' or 'Quickfix List'
    title = isLoclist and fn.getloclist(0, { title = 0 }).title or fn.getqflist({ title = 0 }).title
  elseif ftype == 'directory' then
    title, label = api.nvim_buf_get_name(0), 'dir'
  end
  if label then
    return string.format('%%#SLInactiveBuffer# [%s] %%#SLActiveBuffer#%s ', label, title)
  end

  local current_bufname = args.getBufName()

  local buffer_list = args.getArgs()
  for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do
    if api.nvim_win_get_config(win).relative == '' then
      local bufnr = api.nvim_win_get_buf(win)
      local name = args.getBufName(bufnr)
      if not vim.list_contains(buffer_list, name) then
        table.insert(buffer_list, name)
      end
    end
  end

  -- NOTE: don't use fn.bufnr(bufname) as it takes a pattern (breaks with names like `[id]/+page.svelte`)
  local modified = {}
  for _, bufnr in ipairs(api.nvim_list_bufs()) do
    if vim.bo[bufnr].modified then
      modified[args.getBufName(bufnr)] = true
    end
  end

  local buffer_displays = {}

  for i, bufname in ipairs(buffer_list) do
    local is_active = (bufname == current_bufname)

    local fname = fs.basename(bufname)
    if fname == '' then
      fname = fs.basename(cwd() or '')
    end
    if vim.startswith(fname, '+') then
      fname = fs.joinpath(fn.fnamemodify(bufname, ':h:t'), fname)
    end
    local fpath = bufname:sub(1, -#fname - 1)
    if modified[bufname] then
      fname = fname .. '•'
    end

    local display_str
    if not is_active then
      display_str = string.format('%%#SLInactiveBuffer#%s', fname)
    elseif fpath ~= '' and fpath ~= '.' and not vim.startswith(bufname, 'term:/') then
      display_str = string.format('%%#SLInactiveBuffer#%s%%#SLActiveBuffer#%s', fpath, fname)
    else
      display_str = string.format('%%#SLActiveBuffer#%s', fname)
    end

    if i == fn.argidx() + 1 and fn.argc() ~= 0 then
      local hl = is_active and '%#SLActiveBuffer#' or '%#SLInactiveBuffer#'
      display_str = string.format('%s[%s%s]', hl, display_str, hl)
    end

    table.insert(buffer_displays, display_str)
  end

  if #buffer_displays == 0 then
    return ''
  end

  cached_filelist_info = string.format(' %s ', table.concat(buffer_displays, ' %#SLSeparator#| '))
  return cached_filelist_info
end

---- Context ----
local function get_context()
  local nodes = vim.b.contextStatus
  if not nodes then
    return ''
  end
  local cursor = api.nvim_win_get_cursor(0)
  local curr_node = vim.treesitter.get_node({ pos = { cursor[1] - 1, cursor[2] } })
  while curr_node do
    local name = nodes[curr_node:type()]
    if name then
      local name_nodes = curr_node:field(name)
      local context = name_nodes[1] and vim.treesitter.get_node_text(name_nodes[1], 0) or 'FAILED'
      return '%#SLContext#[' .. context .. ']'
    end
    curr_node = curr_node:parent()
  end
  return ''
end

---- GIT ----
local function get_branch()
  return string.format('%%#SLBranch#%s', (vim.fn['fugitive#Head']()))
end

---- DIAGNOSTICS ----
local diagnostics_data = {
  { icon = signs[1], hi = 'SLDiagError' },
  { icon = signs[2], hi = 'SLDiagWarn' },
  { icon = signs[3], hi = 'SLDiagInfo' },
  { icon = signs[4], hi = 'SLDiagHint' },
}

local local_diagnostics = ''
local workspace_diagnostics = ''
local function custom_diagnostics()
  if api.nvim_get_mode().mode ~= 'n' then
    return local_diagnostics .. workspace_diagnostics
  end

  local_diagnostics = ''
  workspace_diagnostics = ''
  local workspace_count = vim.diagnostic.count(nil)
  local local_count = vim.diagnostic.count(0)
  for i, data in ipairs(diagnostics_data) do
    local local_diag = local_count[i] or 0
    local works_diag = workspace_count[i] or 0
    if #local_diagnostics == 0 and local_diag > 0 and vim.o.buftype == '' then
      local_diagnostics = string.format('%%#%s#%s', data.hi, data.icon)
    end
    if #workspace_diagnostics == 0 and works_diag > local_diag then
      workspace_diagnostics = string.format('%%#SLDiagExternal#%s', data.icon)
    end
  end

  return local_diagnostics .. workspace_diagnostics
end

---- STATUSLINE ----
_G.Statusline = {
  active = function()
    return table.concat({
      '%#SLNormal# ',
      mode(),
      file(),
      '%=',
      vim.o.columns > 80 and (get_context() .. ' ') or '',
      custom_diagnostics(),
      get_branch(),
      ' ',
    })
  end,
}

vim.g.qf_disable_statusline = true
vim.o.statusline = '%!v:lua._G.Statusline.active()'
vim.o.laststatus = 3
vim.o.ruler = false
