-- based on https://nuxsh.is-a.dev/blog/custom-nvim-statusline.html#orgbd5fcc4
local mocha = require('catppuccin.palettes').get_palette('mocha')
local signs = require('utils.ui').diagnostic_icons_num

---- Highlights ----
local custom_bg = mocha.surface0
local curr_statusline_bg = vim.api.nvim_get_hl(0, { name = 'StatusLine' })['bg'] or custom_bg
local statusline_normal = vim.api.nvim_get_hl(0, { name = 'Normal' })['fg']

vim.api.nvim_set_hl(0, 'SLNormal', { bg = curr_statusline_bg, fg = statusline_normal })

vim.api.nvim_set_hl(0, 'SLSeparator', { bg = curr_statusline_bg, fg = mocha.blue })

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
  vim.api.nvim_set_hl(0, 'SLMode' .. mode, hi)
end

-- file hl --
local active_buf_fg = vim.api.nvim_get_hl(0, { name = 'Normal' })['fg']
vim.api.nvim_set_hl(0, 'SLActiveBuffer', { bg = curr_statusline_bg, fg = active_buf_fg })

local inactive_buf_fg = vim.api.nvim_get_hl(0, { name = 'Comment' })['fg']
vim.api.nvim_set_hl(0, 'SLInactiveBuffer', { bg = curr_statusline_bg, fg = inactive_buf_fg })

-- context hl --
-- local normal_fg = vim.api.nvim_get_hl(0, { name = 'Normal' })['fg']
local normal_fg = vim.api.nvim_get_hl(0, { name = 'CursorLineNr' })['fg']
vim.api.nvim_set_hl(0, 'SLContext', { bg = curr_statusline_bg, fg = normal_fg })

-- diagnostics hl --
local diag_error_fg = vim.api.nvim_get_hl(0, { name = 'DiagnosticError' })['fg']
local diag_warn_fg = vim.api.nvim_get_hl(0, { name = 'DiagnosticWarn' })['fg']
local diag_info_fg = vim.api.nvim_get_hl(0, { name = 'DiagnosticInfo' })['fg']
local diag_hint_fg = vim.api.nvim_get_hl(0, { name = 'DiagnosticHint' })['fg']
local diag_external_fg = vim.api.nvim_get_hl(0, { name = 'Comment' })['fg']
vim.api.nvim_set_hl(0, 'SLDiagError', { bg = curr_statusline_bg, fg = diag_error_fg })
vim.api.nvim_set_hl(0, 'SLDiagWarn', { bg = curr_statusline_bg, fg = diag_warn_fg })
vim.api.nvim_set_hl(0, 'SLDiagInfo', { bg = curr_statusline_bg, fg = diag_info_fg })
vim.api.nvim_set_hl(0, 'SLDiagHint', { bg = curr_statusline_bg, fg = diag_hint_fg })
vim.api.nvim_set_hl(0, 'SLDiagExternal', { bg = curr_statusline_bg, fg = diag_external_fg })

-- git hl --
local git_branch = vim.api.nvim_get_hl(0, { name = 'Special' })['fg']
local git_diff = vim.api.nvim_get_hl(0, { name = 'Error' })['fg']
vim.api.nvim_set_hl(0, 'SLBranch', { bg = curr_statusline_bg, fg = git_branch })
vim.api.nvim_set_hl(0, 'SLDiff', { bg = curr_statusline_bg, fg = git_diff })

---- MODE ----
local function mode()
  -- NOTE: apparently it's not possible to get operator pending mode or it flickers with normal
  local mode_char = vim.api.nvim_get_mode().mode
  mode_char = mode_char == '' and 'V' or mode_char:sub(1, 1):upper()
  return string.format('%%#SLMode%s#%s', mode_char, mode_char)
end

---- FILENAME ----
local function file()
  local ftype = vim.o.filetype
  local label, title
  -- TODO: Change filename in special buffers (dap)
  if ftype == 'help' then
    title, label = vim.fn.expand('%:t:r:r'), 'Help'
  elseif ftype == 'netrw' then
    label = 'Netrw'
    title = vim.fn.fnamemodify(vim.uv.cwd() or '', ':t')
    local target = vim.api.nvim_call_function('netrw#Expose', { 'netrwmftgt' })
    if target ~= 'n/a' then
      title = string.format('%s - Target: %s', title, target:gsub('^' .. vim.uv.os_homedir(), '~'))
    end
  elseif ftype == 'fugitive' then
    title, label = vim.fn.expand('%:h:h:t'), 'Fugitive'
  elseif ftype == 'gitcommit' then
    title, label = 'Git Commit Message', 'Fugitive'
  elseif ftype == 'qf' then
    local isLoclist = vim.fn.getloclist(0, { filewinid = 1 }).filewinid ~= 0
    label = isLoclist and 'Location List' or 'Quickfix List'
    title = isLoclist and vim.fn.getloclist(0, { title = 0 }).title or vim.fn.getqflist({ title = 0 }).title
  elseif ftype == 'oil' then
    title, label = require('oil').get_current_dir() or 'Trash', 'oil'
  elseif vim.list_contains({ 'lazy', 'mason', 'TelescopePrompt' }, ftype) then
    return ''
  end
  if label then
    return string.format('%%#SLInactiveBuffer# [%s] %%#SLActiveBuffer#%s ', label, title)
  end
  local buffers = {}
  for _, arg in
    ipairs(vim.fn.argv()--[[@as string[] ]])
  do
    table.insert(buffers, vim.fs.normalize(vim.fn.fnamemodify(arg, ':.')))
  end
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_config(win).relative == '' then
      local bufnr = vim.api.nvim_win_get_buf(win)
      local bufname = vim.api.nvim_buf_get_name(bufnr)
      bufname = vim.fs.normalize(vim.fn.fnamemodify(bufname, ':.'))
      if not vim.list_contains(buffers, bufname) then
        table.insert(buffers, bufname)
      end
    end
  end
  local current_bufnr = vim.api.nvim_get_current_buf()
  local current_bufname = vim.api.nvim_buf_get_name(current_bufnr)
  current_bufname = vim.fs.normalize(vim.fn.fnamemodify(current_bufname, ':.'))
  local current_buf_shorten = { pos = -1, path = '', fname = '' }
  local buffer_names = {}
  local display_length = 0
  for i, bufname in ipairs(buffers) do
    local fname = vim.fn.fnamemodify(bufname, ':t')
    local is_svelte = vim.startswith(fname, '+')
    if is_svelte then
      fname = vim.fs.joinpath(vim.fn.fnamemodify(bufname, ':h:t'), fname)
    end
    if fname == '' then
      fname = vim.fn.fnamemodify(vim.uv.cwd() or '', ':t')
    end
    fname = vim.fs.normalize(fname)
    local bufnr = vim.fn.bufnr(fname)
    local modified = bufnr ~= -1 and vim.bo[bufnr].modified or false
    if modified then
      fname = fname .. '•'
    end
    display_length = display_length + #fname + 3 -- separators + []
    local file_display
    if bufname ~= current_bufname then
      file_display = string.format('%%#SLInactiveBuffer#%s', fname)
    else
      local fpath = is_svelte and vim.fn.fnamemodify(bufname, ':~:.:h:h') or vim.fn.fnamemodify(bufname, ':~:.:h')
      fpath = vim.fs.normalize(fpath)
      current_buf_shorten.fname = string.format('%%#SLActiveBuffer#%s', fname)
      current_buf_shorten.pos = #buffer_names + 1
      if fpath == '' or fpath == '.' or vim.startswith(bufname, 'term://') then
        file_display = current_buf_shorten.fname
        current_buf_shorten.path = file_display
      else
        file_display = string.format('%%#SLInactiveBuffer#%s/%%#SLActiveBuffer#%s', fpath, fname)
        current_buf_shorten.path =
          string.format('%%#SLInactiveBuffer#%s/%%#SLActiveBuffer#%s', vim.fn.pathshorten(fpath), fname)
        display_length = display_length + #fpath + 1
      end
    end
    if i == vim.fn.argidx() + 1 and vim.fn.argc() ~= 0 then
      if bufname == current_bufname then
        file_display = string.format('%%#SLActiveBuffer#[%s%%#SLActiveBuffer#]', file_display)
        current_buf_shorten.fname = string.format('%%#SLActiveBuffer#[%s%%#SLActiveBuffer#]', current_buf_shorten.fname)
        current_buf_shorten.path = string.format('%%#SLActiveBuffer#[%s%%#SLActiveBuffer#]', current_buf_shorten.path)
      else
        file_display = string.format('%%#SLInactiveBuffer#[%s%%#SLInactiveBuffer#]', file_display)
      end
    end
    vim.list_extend(buffer_names, { file_display })
  end
  if #buffer_names == 0 then
    return ''
  end
  local max_columns = vim.o.columns
  if display_length < max_columns or current_buf_shorten.pos == -1 then
    return string.format(' %s ', table.concat(buffer_names, ' %#SLSeparator#| '))
  elseif display_length - #buffer_names[current_buf_shorten.pos] + #current_buf_shorten.path < max_columns then
    buffer_names[current_buf_shorten.pos] = current_buf_shorten.path
    return string.format(' %s ', table.concat(buffer_names, ' %#SLSeparator#| '))
  elseif display_length - #buffer_names[current_buf_shorten.pos] + #current_buf_shorten.fname < max_columns then
    buffer_names[current_buf_shorten.pos] = current_buf_shorten.fname
    return string.format(' %s ', table.concat(buffer_names, ' %#SLSeparator#| '))
  elseif #buffer_names[current_buf_shorten.pos] < max_columns then
    return string.format(' %s […] ', buffer_names[current_buf_shorten.pos])
  elseif #current_buf_shorten.path < max_columns then
    return string.format(' %s […] ', current_buf_shorten.path)
  else
    return string.format(' %s […] ', current_buf_shorten.fname)
  end
end

---- Context ----
local function get_context()
  local nodes = vim.b.contextStatus
  if not nodes then
    return ''
  end
  local curr_line = vim.api.nvim_win_get_cursor(0)
  local non_blank = vim.api.nvim_get_current_line():find('%S') or 0
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
local gstatus = ''

-- improved my implementation stealing from https://github.com/pynappo/git-notify.nvim/blob/main/lua/git-notify/init.lua
local function git_command(args)
  return {
    'git',
    '--no-pager',
    '--no-optional-locks',
    '--literal-pathspecs',
    '-c',
    'gc.auto=0',
    unpack(args),
  }
end

local function update_git()
  vim.system(git_command({ 'fetch' }), {}, function(o)
    vim.system(git_command({ 'status', '--porcelain=v2', '--branch' }), {}, function(branch_status_output)
      local output = branch_status_output.stdout
      if branch_status_output.code ~= 0 or not output then
        return
      end

      local branch = output:match('# branch%.head%s+([%w%-%._%(%)]+)')
      local modified = (output:find("\n[^#\n]%S") ~= nil or output:match("^[^#\n]%S")) and '~' or ''
      local ahead, behind = output:match('# branch%.ab%s+%+([0-9]+)%s+%-([0-9]+)')
      ahead = ahead ~= '0' and '' or ''
      behind = behind ~= '0' and '' or ''

      if ahead == '' and behind == '' and modified == '' then
        gstatus = string.format('%%#SLBranch#%s', branch)
      else
        gstatus = string.format('%%#SLBranch#%s%%#SLDiff#[%s%s%s]', branch, ahead, behind, modified)
      end
      vim.defer_fn(function()
        vim.api.nvim__redraw({ statusline = true })
      end, 0)
    end)
  end)
end

local is_git = require('utils.is-git')()
if is_git then
  if _G.Gstatus_timer == nil then
    _G.Gstatus_timer = vim.uv.new_timer()
  else
    _G.Gstatus_timer:stop()
  end
  _G.Gstatus_timer:start(0, 300000, vim.schedule_wrap(update_git))
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
  if vim.api.nvim_get_mode().mode ~= 'n' then
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

---- LS PROGRESS
local spinner = { '•◦', '◦•' }
local progress = 1
local ls_progress = ''

vim.lsp.handlers['$/progress'] = function(_, p, _)
  if p.value.kind == 'end' then
    ls_progress = ''
    _G.LsProgress_timer:stop()
    vim.api.nvim__redraw({ statusline = true })
  elseif _G.LsProgress_timer == nil then
    _G.LsProgress_timer = vim.uv.new_timer()
    _G.LsProgress_timer:start(0, 500, vim.schedule_wrap(function()
      progress = (progress == 1) and 2 or 1
      ls_progress = string.format('%%#SLSeparator# %s', spinner[progress])
      vim.api.nvim__redraw({ statusline = true })
    end))
  end
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
        ls_progress,
        ' ',
        custom_diagnostics(),
        gstatus,
        ' ',
      })
    else
      return table.concat({
        '%#SLNormal# ',
        mode(),
        file(),
        '%=',
        custom_diagnostics(),
        gstatus,
        ' ',
      })
    end
  end,
}

vim.g.qf_disable_statusline = true
vim.opt.statusline = '%!v:lua.Statusline.active()'
vim.opt.laststatus = 3
vim.opt.ruler = false
-- TODO: should I have cmdheigth = 0? (and increase waybar height)
