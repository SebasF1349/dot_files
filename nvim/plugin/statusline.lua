local api, fn, fs, uv = vim.api, vim.fn, vim.fs, vim.uv
local mocha = require('catppuccin.palettes').get_palette('mocha')
local signs = require('utils.ui').diagnostic_icons_num
local args = require('modules.args')

---- Highlights ----
local custom_bg = mocha.surface0
local curr_statusline_bg = api.nvim_get_hl(0, { name = 'StatusLine' })['bg'] or custom_bg
local statusline_normal = api.nvim_get_hl(0, { name = 'Normal' })['fg']

api.nvim_set_hl(0, 'SLNormal', { bg = curr_statusline_bg, fg = statusline_normal })

api.nvim_set_hl(0, 'SLSeparator', { bg = curr_statusline_bg, fg = mocha.blue })

-- modes hl --
local modes_hi = {
  N = { bg = curr_statusline_bg, fg = mocha.blue },
  I = { bg = curr_statusline_bg, fg = mocha.green },
  T = { bg = curr_statusline_bg, fg = mocha.teal },
  C = { bg = curr_statusline_bg, fg = mocha.peach },
  V = { bg = curr_statusline_bg, fg = mocha.mauve },
  R = { bg = curr_statusline_bg, fg = mocha.red },
  O = { bg = curr_statusline_bg, fg = mocha.overlay2 },
  S = { bg = curr_statusline_bg, fg = mocha.yellow },
}

for mode, hi in pairs(modes_hi) do
  api.nvim_set_hl(0, 'SLMode' .. mode, hi)
end

-- file hl --
local active_buf_fg = api.nvim_get_hl(0, { name = 'Normal' })['fg']
api.nvim_set_hl(0, 'SLActiveBuffer', { bg = curr_statusline_bg, fg = active_buf_fg })

local inactive_buf_fg = api.nvim_get_hl(0, { name = 'Comment' })['fg']
api.nvim_set_hl(0, 'SLInactiveBuffer', { bg = curr_statusline_bg, fg = inactive_buf_fg })

-- context hl --
-- local normal_fg = api.nvim_get_hl(0, { name = 'Normal' })['fg']
local normal_fg = api.nvim_get_hl(0, { name = 'CursorLineNr' })['fg']
api.nvim_set_hl(0, 'SLContext', { bg = curr_statusline_bg, fg = normal_fg })

-- diagnostics hl --
local diag_error_fg = api.nvim_get_hl(0, { name = 'DiagnosticError' })['fg']
local diag_warn_fg = api.nvim_get_hl(0, { name = 'DiagnosticWarn' })['fg']
local diag_info_fg = api.nvim_get_hl(0, { name = 'DiagnosticInfo' })['fg']
local diag_hint_fg = api.nvim_get_hl(0, { name = 'DiagnosticHint' })['fg']
local diag_external_fg = api.nvim_get_hl(0, { name = 'Comment' })['fg']
api.nvim_set_hl(0, 'SLDiagError', { bg = curr_statusline_bg, fg = diag_error_fg })
api.nvim_set_hl(0, 'SLDiagWarn', { bg = curr_statusline_bg, fg = diag_warn_fg })
api.nvim_set_hl(0, 'SLDiagInfo', { bg = curr_statusline_bg, fg = diag_info_fg })
api.nvim_set_hl(0, 'SLDiagHint', { bg = curr_statusline_bg, fg = diag_hint_fg })
api.nvim_set_hl(0, 'SLDiagExternal', { bg = curr_statusline_bg, fg = diag_external_fg })

-- git hl --
local git_branch = api.nvim_get_hl(0, { name = 'Special' })['fg']
api.nvim_set_hl(0, 'SLBranch', { bg = curr_statusline_bg, fg = git_branch })

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
  elseif ftype == 'netrw' then
    label = 'Netrw'
    title = vim.b.netrw_curdir:gsub(uv.cwd(), '.')
  elseif ftype == 'fugitive' then
    title, label = fn.expand('%:h:h:t'), 'Fugitive'
  elseif ftype == 'gitcommit' then
    title, label = 'Git Commit Message', 'Fugitive'
  elseif ftype == 'qf' then
    local isLoclist = fn.getloclist(0, { filewinid = 1 }).filewinid ~= 0
    label = isLoclist and 'Location List' or 'Quickfix List'
    title = isLoclist and fn.getloclist(0, { title = 0 }).title or fn.getqflist({ title = 0 }).title
  elseif ftype == 'oil' then
    title, label = require('oil').get_current_dir() or 'Trash', 'oil'
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

  local buffer_displays = {}

  for i, bufname in ipairs(buffer_list) do
    local is_active = (bufname == current_bufname)

    local fname = fs.basename(bufname)
    if fname == '' then
      fname = fs.basename(uv.cwd() or '')
    end
    if vim.startswith(fname, '+') then
      fname = fs.joinpath(fn.fnamemodify(bufname, ':h:t'), fname)
    end
    local fpath = bufname:sub(1, -#fname - 1)
    local bufnr = fn.bufnr(fname)
    if bufnr ~= -1 and vim.bo[bufnr].modified or false then
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
  local curr_line = api.nvim_win_get_cursor(0)
  local non_blank = api.nvim_get_current_line():find('%S') or 0
  local curr_node = vim.treesitter.get_node({ pos = { curr_line[1] - 1, non_blank } })
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
  return string.format('%%#SLBranch#%s', vim.g.gitsigns_head or '')
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
    return string.format('%s%s', local_diagnostics, workspace_diagnostics)
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

  if local_diagnostics == '' and workspace_diagnostics == '' then
    return ''
  end

  return string.format('%s%s', local_diagnostics, workspace_diagnostics)
end

---- STATUSLINE ----
Statusline = {
  active = function()
    if vim.o.columns > 80 then
      return table.concat({
        '%#SLNormal# ',
        mode(),
        file(),
        '%=',
        get_context(),
        ' ',
        custom_diagnostics(),
        get_branch(),
        ' ',
      })
    else
      return table.concat({
        '%#SLNormal# ',
        mode(),
        file(),
        '%=',
        custom_diagnostics(),
        get_branch(),
        ' ',
      })
    end
  end,
}

vim.g.qf_disable_statusline = true
vim.o.statusline = '%!v:lua.Statusline.active()'
vim.o.laststatus = 3
vim.o.ruler = false
