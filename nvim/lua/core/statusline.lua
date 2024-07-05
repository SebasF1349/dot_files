-- based on https://nuxsh.is-a.dev/blog/custom-nvim-statusline.html#orgbd5fcc4
local mocha = require('catppuccin.palettes').get_palette('mocha')

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

local modes_hi = {
  N = { fg = mocha.blue },
  I = { fg = mocha.green },
  T = { fg = mocha.green },
  C = { fg = mocha.peach },
  V = { fg = mocha.mauve },
  R = { fg = mocha.red },
  O = { fg = mocha.overlay2 },
}

for mode, hi in pairs(modes_hi) do
  vim.api.nvim_set_hl(0, 'StatusLineMode' .. mode, hi)
end

local function mode()
  local current_mode = vim.api.nvim_get_mode().mode
  local first_char = modes[current_mode]:sub(1, 1)
  local mode_hi = modes[current_mode] and ('StatusLineMode' .. first_char) or 'StatusLineModeO'
  return string.format(' %%#%s#%s', mode_hi, modes[current_mode]:sub(1, 1))
end

---- FILENAME ----
local function file()
  local buftype = vim.bo.buftype
  local ftype = vim.o.filetype
  local label, title
  -- TODO: Change filename in special buffers (dap)
  if buftype == 'help' then
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
  elseif vim.list_contains({ 'lazy', 'mason', 'TelescopePrompt' }, ftype) then
    return ''
  end
  if label then
    return string.format('%%#NonText# [%s] %%#Normal#%s ', label, title)
  end
  local buffers = {}
  local current_bufnr = vim.api.nvim_get_current_buf()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) and vim.api.nvim_get_option_value('buflisted', { buf = bufnr }) then
      local bufname = vim.api.nvim_buf_get_name(bufnr)
      local fname = vim.fn.fnamemodify(bufname, ':t')
      if fname == '' then
        fname = vim.fn.fnamemodify(vim.uv.cwd() or '', ':t')
      end
      if bufnr == current_bufnr then
        local fpath = vim.fn.fnamemodify(bufname, ':~:.:h')
        if fpath == '' or fpath == '.' or vim.startswith(bufname, 'term://') then
          vim.list_extend(buffers, { string.format('%%#Normal#%s', fname) })
        else
          vim.list_extend(buffers, { string.format('%%#NonText#%s/%%#Normal#%s', fpath, fname) })
        end
      else
        vim.list_extend(buffers, { string.format('%%#NonText#%s', fname) })
      end
    end
  end
  if #buffers == 0 then
    return ''
  end
  return string.format(' %s ', table.concat(buffers, ' %#FloatBorder#| '))
end

---- GIT ----
local gstatus = { ahead = '0', behind = '0', modified = 0 }

local function git_modified()
  local git_info = vim.b.gitsigns_status_dict
  if git_info and (git_info.added ~= 0 or git_info.changed ~= 0 or git_info.removed ~= 0) then
    gstatus.modified = 1
  end
end
git_modified()

local function update_gstatus()
  local Job = require('plenary.job')
  Job:new({
    command = 'git',
    args = { 'fetch' },
  }):start()
  Job:new({
    command = 'git',
    args = { 'rev-list', '--left-right', '--count', 'HEAD...@{upstream}' },
    on_exit = function(job, _)
      local res = job:result()[1]
      if type(res) ~= 'string' then
        gstatus.ahead, gstatus.behind = '0', '0'
        return
      end
      local ok, ahead, behind = pcall(string.match, res, '(%d+)%s*(%d+)')
      if not ok then
        ahead, behind = '0', '0'
      end
      gstatus.ahead, gstatus.behind = ahead, behind
    end,
  }):start()
  Job:new({
    command = 'git',
    args = { 'status', '--porcelain' },
    on_exit = function(job, _)
      local res = job:result()[1]
      gstatus.modified = res and #res or 0
    end,
  }):start()
end

if _G.Gstatus_timer == nil then
  _G.Gstatus_timer = vim.uv.new_timer()
else
  _G.Gstatus_timer:stop()
end
_G.Gstatus_timer:start(0, 2000, vim.schedule_wrap(update_gstatus))

local head = ''
local function git()
  local git_info = vim.b.gitsigns_status_dict
  if git_info then
    head = git_info.head
  end
  local ahead = gstatus.ahead ~= '0' and '' or ''
  local behind = gstatus.behind ~= '0' and '' or ''
  local modified = gstatus.modified ~= 0 and '~' or ''
  if ahead == '' and behind == '' and modified == '' then
    return string.format(' %%#Special#%s ', head)
  end
  return string.format(' %%#Special#%s%%#Error#[%s%s%s] ', head, ahead, behind, modified)
end

---- DIAGNOSTICS ----
local diagnostics_data = {
  { icon = ' ', hi = 'DiagnosticError' },
  { icon = ' ', hi = 'DiagnosticWarn' },
  { icon = ' ', hi = 'DiagnosticInfo' },
  { icon = ' ', hi = 'DiagnosticHint' },
}

local local_diagnostics = ''
local workspace_diagnostics = ''
local function custom_diagnostics()
  if vim.fn.mode() == 'n' then
    local_diagnostics = ''
    workspace_diagnostics = ''
    local workspace_count = vim.diagnostic.count(nil)
    local local_count = vim.diagnostic.count(0)
    for i, data in ipairs(diagnostics_data) do
      local local_diag = local_count[i] or 0
      local works_diag = workspace_count[i] or 0
      if #local_diagnostics == 0 and local_diag > 0 then
        local_diagnostics = string.format('%%#%s#%s', data.hi, data.icon)
      end
      if #workspace_diagnostics == 0 and works_diag > local_diag then
        workspace_diagnostics = string.format('%%#Conceal#%s', data.icon)
      end
    end
  end

  return string.format(' %s%s', local_diagnostics, workspace_diagnostics)
end

---- GRAPPLE ----
-- TODO: idk if I would still use grapple

---- STATUSLINE ----
Statusline = {
  active = function()
    return table.concat({
      mode(),
      custom_diagnostics(),
      '%#FloatBorder#%=',
      -- "%#FloatBorder#├%=┤",
      file(),
      '%#FloatBorder#%=',
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
-- TODO: should I have cmdheigth = 0? (and increase waybar height)
