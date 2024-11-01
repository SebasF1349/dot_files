-- based on https://nuxsh.is-a.dev/blog/custom-nvim-statusline.html#orgbd5fcc4
local mocha = require('catppuccin.palettes').get_palette('mocha')
local pinbufs = require('core.buffers')

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
  T = { bg = curr_statusline_bg, fg = mocha.green },
  C = { bg = curr_statusline_bg, fg = mocha.peach },
  V = { bg = curr_statusline_bg, fg = mocha.mauve },
  R = { bg = curr_statusline_bg, fg = mocha.red },
  O = { bg = curr_statusline_bg, fg = mocha.overlay2 },
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
local modes = {
  ['n'] = 'Normal',
  ['no'] = 'O-Pending',
  ['nov'] = 'O-Pending',
  ['noV'] = 'O-Pending',
  ['no\22'] = 'O-Pending',
  ['niI'] = 'Normal',
  ['niR'] = 'Normal',
  ['niV'] = 'Normal',
  ['nt'] = 'Normal',
  ['ntT'] = 'Normal',
  ['v'] = 'Visual',
  ['vs'] = 'Visual',
  ['V'] = 'V-Line',
  ['\22'] = 'V-Block',
  ['\22s'] = 'V-Block',
  ['s'] = 'Select',
  ['S'] = 'S-Line',
  ['\19'] = 'S-Block',
  ['i'] = 'Insert',
  ['ic'] = 'Insert',
  ['ix'] = 'Insert',
  ['R'] = 'Replace',
  ['Rc'] = 'Replace',
  ['Rx'] = 'Replace',
  ['Rv'] = 'V-Replace',
  ['Rvc'] = 'V-Replace',
  ['Rvx'] = 'V-Replace',
  ['c'] = 'Command',
  ['cv'] = 'Ex',
  ['ce'] = 'Ex',
  ['r'] = 'Replace',
  ['rm'] = 'More',
  ['r?'] = 'Confirm',
  ['!'] = 'Shell',
  ['t'] = 'Terminal',
}

local function mode()
  local current_mode = vim.api.nvim_get_mode().mode
  local first_char = modes[current_mode]:sub(1, 1)
  local mode_hi = modes[current_mode] and ('SLMode' .. first_char) or 'SLModeO'
  return string.format('%%#%s#%s', mode_hi, modes[current_mode]:sub(1, 1))
end

---- FILENAME ----
-- NOTE: maybe use a custom list to garantize the order they are shown and stop the shenanigans
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
  for _, pinbuf in ipairs(pinbufs.get_pinbufs()) do
    table.insert(buffers, pinbuf)
  end
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_config(win).relative == '' then
      local bufnr = vim.api.nvim_win_get_buf(win)
      if not vim.list_contains(buffers, bufnr) then
        table.insert(buffers, bufnr)
      end
    end
  end
  local current_bufnr = vim.api.nvim_get_current_buf()
  local current_buf_shorten = { pos = -1, path = '', fname = '' }
  local buffer_names = {}
  for i, bufnr in ipairs(buffers) do
    if not vim.api.nvim_buf_is_valid(bufnr) then
      goto continue
    end
    local bufname = vim.api.nvim_buf_get_name(bufnr)
    local fname = vim.fn.fnamemodify(bufname, ':t')
    local is_svelte = vim.startswith(fname, '+')
    if is_svelte then
      fname = vim.fn.fnamemodify(bufname, ':h:t') .. '/' .. fname
    end
    if fname == '' then
      fname = vim.fn.fnamemodify(vim.uv.cwd() or '', ':t')
    end
    local file_display
    if bufnr ~= current_bufnr then
      file_display = string.format('%%#SLInactiveBuffer#%s', fname)
    else
      local fpath = is_svelte and vim.fn.fnamemodify(bufname, ':~:.:h:h') or vim.fn.fnamemodify(bufname, ':~:.:h')
      current_buf_shorten.fname = string.format('%%#SLActiveBuffer#%s', fname)
      if fpath == '' or fpath == '.' or vim.startswith(bufname, 'term://') then
        file_display = current_buf_shorten.fname
        current_buf_shorten.path = file_display
      else
        file_display = string.format('%%#SLInactiveBuffer#%s/%%#SLActiveBuffer#%s', fpath, fname)
        current_buf_shorten.path =
          string.format('%%#SLInactiveBuffer#%s/%%#SLActiveBuffer#%s', vim.fn.pathshorten(fpath), fname)
      end
      current_buf_shorten.pos = #buffer_names + 1
    end
    if i > #pinbufs.get_pinbufs() then
      file_display = string.format('%s[t]', file_display)
    elseif i == pinbufs.get_active_pinbuf() and buffers[i] ~= current_bufnr then
      file_display = string.format('%s[*]', file_display)
    end
    vim.list_extend(buffer_names, { file_display })
    ::continue::
  end
  if #buffer_names == 0 then
    return ''
  end
  local ret = string.format(' %s ', table.concat(buffer_names, ' %#SLSeparator#| '))
  local max_columns = vim.o.columns
  local ret_length = #ret - 18 * #buffer_names
  if ret_length < max_columns then
    return ret
  elseif ret_length - #buffer_names[current_buf_shorten.pos] + #current_buf_shorten.path < max_columns then
    buffer_names[current_buf_shorten.pos] = current_buf_shorten.path
    return string.format(' %s ', table.concat(buffer_names, ' %#SLSeparator#| '))
  elseif ret_length - #buffer_names[current_buf_shorten.pos] + #current_buf_shorten.fname < max_columns then
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

---- GIT ----
local gstatus = { head = '', ahead = '0', behind = '0', modified = false }

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
  vim.system(git_command({ 'fetch' }), {}, function()
    vim.system(git_command({ 'status', '--porcelain=v2', '--branch' }), {}, function(branch_status_output)
      if branch_status_output.code ~= 0 then
        return
      end
      local lines = vim.split(branch_status_output.stdout, '\n', { plain = true })
      if #lines < 3 then
        return
      end
      local upstream_branch = lines[2]:sub(1 + #'# branch.head ')
      gstatus.head = upstream_branch
      local has_upstream = lines[3]:sub(1, 1) == '#'
      if not has_upstream then
        return
      end

      local _, _, commits_ahead, commits_behind = lines[4]:find('%+(%d+) %-(%d+)')
      gstatus.ahead = commits_ahead
      gstatus.behind = commits_behind
      gstatus.modified = not vim.startswith(lines[#lines - 1], '#')
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
  _G.Gstatus_timer:start(0, 2000, vim.schedule_wrap(update_git))
end

local head = ''
local function git()
  if not is_git then
    return ''
  end
  local git_info = vim.b.gitsigns_status_dict
  if git_info then
    head = git_info.head
  end
  local ahead = gstatus.ahead ~= '0' and '' or ''
  local behind = gstatus.behind ~= '0' and '' or ''
  local modified = (gstatus.modified or vim.o.modified) and '~' or ''
  if ahead == '' and behind == '' and modified == '' then
    return string.format('%%#SLBranch#%s', head)
  end
  return string.format('%%#SLBranch#%s%%#SLDiff#[%s%s%s]', head, ahead, behind, modified)
end

---- DIAGNOSTICS ----
local diagnostics_data = {
  { icon = ' ', hi = 'SLDiagError' },
  { icon = ' ', hi = 'SLDiagWarn' },
  { icon = ' ', hi = 'SLDiagInfo' },
  { icon = ' ', hi = 'SLDiagHint' },
}

local local_diagnostics = ''
local workspace_diagnostics = ''
local function custom_diagnostics()
  if vim.fn.mode() ~= 'n' then
    return ''
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
    return table.concat({
      mode(),
      custom_diagnostics(),
      '%#StatusLineSeparator#%=',
      -- "%#StatusLineSeparator#├%=┤",
      file(),
      '%#StatusLineSeparator#%=',
      git(),
    })
  end,
}

vim.g.qf_disable_statusline = true
vim.opt.statusline = '%!v:lua.Statusline.active()'
vim.opt.laststatus = 3
vim.opt.fillchars:append({
  stl = '─',
  stlnc = '─',
})
vim.opt.ruler = false
-- TODO: should I have cmdheigth = 0? (and increase waybar height)
