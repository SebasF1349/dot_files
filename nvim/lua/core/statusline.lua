-- based on https://nuxsh.is-a.dev/blog/custom-nvim-statusline.html#orgbd5fcc4
local mocha = require("catppuccin.palettes").get_palette("mocha")

local background = mocha.surface0

---- MODE ----
local modes = {
  ["n"] = "Normal",
  ["no"] = "O-Pending",
  ["nov"] = "O-Pending",
  ["noV"] = "O-Pending",
  ["no\22"] = "O-Pending",
  ["niI"] = "Normal",
  ["niR"] = "Normal",
  ["niV"] = "Normal",
  ["nt"] = "Normal",
  ["ntT"] = "Normal",
  ["v"] = "Visual",
  ["vs"] = "Visual",
  ["V"] = "V-Line",
  ["\22"] = "V-Block",
  ["\22s"] = "V-Block",
  ["s"] = "Select",
  ["S"] = "S-Line",
  ["\19"] = "S-Block",
  ["i"] = "Insert",
  ["ic"] = "Insert",
  ["ix"] = "Insert",
  ["R"] = "Replace",
  ["Rc"] = "Replace",
  ["Rx"] = "Replace",
  ["Rv"] = "V-Replace",
  ["Rvc"] = "V-Replace",
  ["Rvx"] = "V-Replace",
  ["c"] = "Command",
  ["cv"] = "Ex",
  ["ce"] = "Ex",
  ["r"] = "Replace",
  ["rm"] = "More",
  ["r?"] = "Confirm",
  ["!"] = "Shell",
  ["t"] = "Terminal",
}

local modes_hi = {
  N = { bg = background, fg = mocha.blue },
  I = { bg = background, fg = mocha.green },
  T = { bg = background, fg = mocha.green },
  C = { bg = background, fg = mocha.peach },
  V = { bg = background, fg = mocha.mauve },
  R = { bg = background, fg = mocha.red },
  O = { bg = background, fg = mocha.overlay2 },
}

for mode, hi in pairs(modes_hi) do
  vim.api.nvim_set_hl(0, "StatusLineMode" .. mode, hi)
end

local function mode()
  local current_mode = vim.api.nvim_get_mode().mode
  return string.format(" %s ", modes[current_mode]:sub(1, 1))
end

local function update_mode_colors()
  local current_mode = vim.api.nvim_get_mode().mode
  local first_char = modes[current_mode]:sub(1, 1)
  if first_char then
    return string.format("%%#StatusLineMode%s#", first_char)
  else
    return "%#StatusLineModeO#"
  end
end

---- FILENAME ----
vim.api.nvim_set_hl(0, "StatusLineNormal", { bg = background, fg = mocha.text })
vim.api.nvim_set_hl(0, "StatusLineGhost", { bg = background, fg = mocha.overlay2 })

local function file()
  local buftype = vim.bo.buftype
  local ftype = vim.o.filetype
  local label, title
  if buftype == "terminal" then
    title, label = vim.fn.expand("%:t"), "Term"
  elseif buftype == "help" then
    title, label = vim.fn.expand("%:t:r:r"), "Help"
  elseif ftype == "netrw" then
    label = "Netrw"
    title = vim.fn.fnamemodify((vim.uv or vim.loop).cwd() or "", ":t")
    local target = vim.api.nvim_call_function("netrw#Expose", { "netrwmftgt" })
    if target ~= "n/a" then
      title = string.format("%s - Target: %s", title, target:gsub("^" .. vim.loop.os_homedir(), "~"))
    end
  elseif ftype == "fugitive" then
    title, label = vim.fn.expand("%:h:h:t"), "Fugitive"
  elseif ftype == "qf" then
    local isLoclist = vim.fn.getloclist(0, { filewinid = 1 }).filewinid ~= 0
    label = isLoclist and "Location List" or "Quickfix List"
    title = isLoclist and vim.fn.getloclist(0, { title = 0 }).title or vim.fn.getqflist({ title = 0 }).title
  elseif vim.list_contains({ "lazy", "mason", "TelescopePrompt" }, ftype) then
    return ""
  end
  if label then
    return string.format("%%#StatusLineGhost# [%s] %%#StatusLineNormal#%s", label, title)
  end
  local fname = vim.fn.expand("%:t")
  if fname == "" then
    fname = vim.fn.fnamemodify((vim.uv or vim.loop).cwd() or "", ":t")
  end
  local fpath = vim.fn.expand("%:~:.:h")
  if fpath == "" or fpath == "." then
    return string.format("%%#StatusLineNormal#%s", fname)
  end
  -- TODO: Maybe add icon
  -- TODO: Change filename in special buffers (dap)
  return string.format("%%#StatusLineGhost# %s/%%#StatusLineNormal#%s", fpath, fname)
end

---- GIT ----
vim.api.nvim_set_hl(0, "StatusLineGitBranch", { bg = background, fg = mocha.pink })

local head_cache = ""
local function git_branch()
  local git_info = vim.b.gitsigns_status_dict
  if git_info then
    head_cache = git_info.head
  end
  return head_cache
end

local gstatus = { ahead = "0", behind = "0", modified = 0 }

local function git_modified()
  local git_info = vim.b.gitsigns_status_dict
  if git_info and (git_info.added ~= 0 or git_info.changed ~= 0 or git_info.removed ~= 0) then
    gstatus.modified = 1
    return true
  end
  return false
end
git_modified()

local function update_gstatus()
  local Job = require("plenary.job")
  Job:new({
    command = "git",
    args = { "rev-list", "--left-right", "--count", "HEAD...@{upstream}" },
    on_exit = function(job, _)
      local res = job:result()[1]
      if type(res) ~= "string" then
        gstatus.ahead, gstatus.behind = "0", "0"
        return
      end
      local ok, ahead, behind = pcall(string.match, res, "(%d+)%s*(%d+)")
      if not ok then
        ahead, behind = "0", "0"
      end
      gstatus.ahead, gstatus.behind = ahead, behind
    end,
  }):start()
  Job:new({
    command = "git",
    args = { "status", "--porcelain" },
    on_exit = function(job, _)
      local res = job:result()[1]
      gstatus.modified = res and #res or 0
    end,
  }):start()
end

if _G.Gstatus_timer == nil then
  _G.Gstatus_timer = vim.loop.new_timer()
else
  _G.Gstatus_timer:stop()
end
_G.Gstatus_timer:start(0, 2000, vim.schedule_wrap(update_gstatus))

vim.api.nvim_set_hl(0, "StatusLineGit", { bg = background, fg = mocha.red })

local function git()
  local head = git_branch()
  local ahead = gstatus.ahead ~= "0" and "" or ""
  local behind = gstatus.behind ~= "0" and "" or ""
  local modified = gstatus.modified ~= 0 and "~" or ""
  if ahead == "" and behind == "" and modified == "" then
    return string.format(" %%#StatusLineGitBranch#%s ", head)
  end
  return string.format(" %%#StatusLineGitBranch#%s%%#StatusLineGit#[%s%s%s] ", head, ahead, behind, modified)
end

---- DIAGNOSTICS ----
local diagnostics_data = {
  { icon = " ", hi = "StatusLineError", fg = mocha.red },
  { icon = " ", hi = "StatusLineWarn", fg = mocha.yellow },
  { icon = "", hi = "StatusLineInfo", fg = mocha.sky },
  { icon = " ", hi = "StatusLineHint", fg = mocha.teal },
}
for _, data in ipairs(diagnostics_data) do
  vim.api.nvim_set_hl(0, data.hi, { fg = data.fg, bg = background })
end

local function local_diagnostics()
  for i, data in ipairs(diagnostics_data) do
    local count = vim.tbl_count(vim.diagnostic.get(0, { severity = i }))
    if count > 0 then
      return string.format("%%#%s#%s", data.hi, data.icon)
    end
  end

  return ""
end

vim.api.nvim_set_hl(0, "StatusLineWorkspace", { fg = mocha.comment, bg = mocha.surface0 })

local function workspace_diagnostics()
  for i, data in ipairs(diagnostics_data) do
    local count = vim.tbl_count(vim.diagnostic.get(nil, { severity = i }))
    local local_count = vim.tbl_count(vim.diagnostic.get(0, { severity = i }))
    if count > local_count then
      return "%#StatusLineWorkspace#" .. data.icon
    end
  end

  return ""
end

local function custom_diagnostics()
  local local_diag = local_diagnostics()
  local workspace_diag = workspace_diagnostics()
  if #local_diag == 0 then
    return workspace_diag
  elseif #workspace_diag == 0 then
    return local_diag
  else
    return local_diag .. " " .. workspace_diag
  end
end

---- GRAPPLE ----
-- TODO: idk if I would still use grapple

---- STATUSLINE ----
Statusline = {
  active = function()
    return table.concat({
      "%#StatusLineNormal#",
      update_mode_colors(),
      mode(),
      git(),
      file(),
      "%=",
      custom_diagnostics(),
    })
  end,
}

vim.g.qf_disable_statusline = true
vim.opt.statusline = "%!v:lua.Statusline.active()"
vim.opt.laststatus = 3
-- TODO: should I have cmdheigth = 0? (and increase waybar height)
