-- based on https://nuxsh.is-a.dev/blog/custom-nvim-statusline.html#orgbd5fcc4

local mocha = require("catppuccin.palettes").get_palette("mocha")

local background = mocha.surface0

---- MODE ----
local modes = {
  ["n"] = "Normal",
  ["no"] = "Normal",
  ["v"] = "Visual",
  ["V"] = "Visual line",
  [""] = "Visual block",
  ["s"] = "Select",
  ["S"] = "Select line",
  [""] = "Select block",
  ["i"] = "Insert",
  ["ic"] = "Insert",
  ["R"] = "Replace",
  ["Rv"] = "Visual replace",
  ["c"] = "Command",
  ["cv"] = "Vim ex",
  ["ce"] = "Ex",
  ["r"] = "Prompt",
  ["rm"] = "Moar",
  ["r?"] = "Confirm",
  ["!"] = "Shell",
  ["t"] = "Terminal",
}

local modes_hi = {
  Normal = { bg = background, fg = mocha.blue },
  Insert = { bg = background, fg = mocha.green },
  Terminal = { bg = background, fg = mocha.green },
  Command = { bg = background, fg = mocha.peach },
  Visual = { bg = background, fg = mocha.mauve },
  Replace = { bg = background, fg = mocha.red },
  Inactive = { bg = background, fg = mocha.surface1 },
}

for mode, hi in pairs(modes_hi) do
  vim.api.nvim_set_hl(0, "StatusLineMode" .. mode, hi)
end

local function mode()
  local current_mode = vim.api.nvim_get_mode().mode
  return string.format(" %s ", modes[current_mode]):upper()
end

local function update_mode_colors()
  local current_mode = vim.api.nvim_get_mode().mode
  if modes[current_mode] then
    return string.format("%%#StatusLineMode%s#", modes[current_mode])
  else
    return "%#StatusLineModeInactive#"
  end
end

---- FILENAME ----
vim.api.nvim_set_hl(0, "StatusLineFile", { fg = mocha.text, bg = background })

local function file()
  local fpath = vim.fn.fnamemodify(vim.fn.expand("%"), ":~:.:h")
  if fpath == "" or fpath == "." then
    fpath = " "
  end
  local fname = vim.fn.expand("%:t")
  -- TODO: Maybe add icon
  return string.format("%%#StatusLineFile# %s/%s", fpath, fname)
end

---- GIT ----
-- TODO: show git status & branch

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
      "%#Statusline#",
      update_mode_colors(),
      mode(),
      -- "%#Normal# ",
      file(),
      -- "%#Normal#",
      "%=%#StatusLineExtra#",
      custom_diagnostics(),
    })
  end,

  inactive = function()
    return " %F"
  end,

  -- TODO: check integration with special buffers
  NvimTree = function()
    return "%#StatusLineNC#   NvimTree"
  end,
}

-- vim.api.nvim_exec2(
--   [[
--   augroup Statusline
--   au!
--   au WinEnter,BufEnter * setlocal statusline=%!v:lua.Statusline.active()
--   au WinLeave,BufLeave * setlocal statusline=%!v:lua.Statusline.inactive()
--   au WinEnter,BufEnter,FileType NvimTree setlocal statusline=%!v:lua.Statusline.short()
--   augroup END
--   ]],
--   {}
-- )

vim.opt.statusline = "%!v:lua.Statusline.active()"
vim.opt.laststatus = 3
-- TODO: should I have cmdheigth = 0? (and increase waybar height)
