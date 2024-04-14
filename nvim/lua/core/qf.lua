--------------------------------------------------
-- "Global" variables in this file
--------------------------------------------------

local signs = {
  E = "",
  W = "",
  H = "",
  I = "",
}
local diagnostics_open = false

--------------------------------------------------
-- Better Grep
--------------------------------------------------

vim.opt.grepprg = "rg --vimgrep"
vim.opt.grepformat = "%f:%l:%c:%m"

vim.api.nvim_create_user_command("Grep", function(opts)
  diagnostics_open = false
  vim.cmd("silent grep! --smart-case " .. opts.args)
  vim.cmd("copen")
end, { nargs = 1 })

--------------------------------------------------
-- Better Quickfix Window Style
--------------------------------------------------

---@diagnostic disable-next-line: duplicate-set-field
function _G.qftf(info)
  local items
  local ret = {}
  -- The name of item in list is based on the directory of quickfix window.
  -- Change the directory for quickfix window make the name of item shorter.
  -- It's a good opportunity to change current directory in quickfixtextfunc :)
  --
  -- local alterBufnr = fn.bufname('#') -- alternative buffer is the buffer before enter qf window
  -- local root = getRootByAlterBufnr(alterBufnr)
  -- vim.cmd(('noa lcd %s'):format(fn.fnameescape(root)))
  --
  if info.quickfix == 1 then
    items = vim.fn.getqflist({ id = info.id, items = 0 }).items
  else
    items = vim.fn.getloclist(info.winid, { id = info.id, items = 0 }).items
  end
  local limit = 31
  local fnameFmt1, fnameFmt2 = "%-" .. limit .. "s", "…%." .. (limit - 1) .. "s"
  local validFmt = "%s │ %s %s"
  for i = info.start_idx, info.end_idx do
    local e = items[i]
    local fname = ""
    local str
    if e.valid == 1 then
      if e.bufnr > 0 then
        fname = vim.fn.bufname(e.bufnr)
        if fname == "" then
          fname = "[No Name]"
        else
          fname = fname:gsub("^" .. vim.env.HOME, "~")
        end
        -- char in fname may occur more than 1 width, ignore this issue in order to keep performance
        if #fname <= limit then
          fname = fnameFmt1:format(fname)
        else
          fname = fnameFmt2:format(fname:sub(1 - limit))
        end
      end
      local qtype = e.type == "" and "" or ((signs[e.type] and signs[e.type] or signs.I) .. " ")
      str = validFmt:format(fname, qtype, vim.fn.trim(e.text))
    else
      str = e.text
    end
    table.insert(ret, str)
  end
  return ret
end

vim.o.qftf = "{info -> v:lua._G.qftf(info)}"

--------------------------------------------------
-- Quickfix Toggle Keymaps
--------------------------------------------------

-- based on https://gitlab.com/ranjithshegde/dotbare/-/blob/master/.config/nvim/lua/r/extensions/qf.lua
local function find_qf(type)
  local wininfo = vim.fn.getwininfo()
  local win_tbl = {}
  for _, win in pairs(wininfo) do
    local found = false
    if type == "l" and win["loclist"] == 1 then
      found = true
    end
    -- loclist window has 'quickfix' set, eliminate those
    if (type == "q" or type == "d") and win["quickfix"] == 1 and win["loclist"] == 0 then
      found = true
    end
    if found then
      table.insert(win_tbl, { winid = win["winid"], bufnr = win["bufnr"] })
    end
  end
  return win_tbl
end

-- open quickfix if not empty
local function open_qf()
  if not vim.tbl_isempty(vim.fn.getqflist()) then
    vim.cmd.copen()
    vim.cmd.wincmd("J")
  else
    vim.notify("qflist is empty.")
  end
end

-- loclist on current window where not empty
local function open_loclist()
  if not vim.tbl_isempty(vim.fn.getloclist(0)) then
    vim.cmd.lopen()
  else
    vim.notify("loclist is empty.")
  end
end

--- type='q': qf toggle and send to bottom
--- type='d': qf toggle with diagnostics
--- type='l': loclist toggle (all windows)
local function toggle_qf(type)
  local windows = find_qf(type)
  if not vim.tbl_isempty(windows) then
    -- hide all visible windows
    for _, win in pairs(windows) do
      vim.api.nvim_win_hide(win.winid)
    end
  else
    -- no windows are visible, attempt to open
    if type == "l" then
      open_loclist()
    elseif type == "d" then
      vim.diagnostic.setqflist()
      diagnostics_open = true
    else
      open_qf()
    end
  end
end

vim.keymap.set("n", "<leader>tq", function()
  diagnostics_open = false
  toggle_qf("q")
end, { desc = "[T]oggle [Q]uickfix" })
vim.keymap.set("n", "<leader>qd", function()
  diagnostics_open = false
  toggle_qf("d")
end, { desc = "[Q]uickfix [D]iagnostics Toggle" })

--------------------------------------------------
-- Quickfix Autocmds
--------------------------------------------------

local qf_group = vim.api.nvim_create_augroup("qflist", { clear = true })

vim.api.nvim_create_autocmd("DiagnosticChanged", {
  group = qf_group,
  callback = function()
    if diagnostics_open then
      vim.diagnostic.setqflist({
        open = false,
      })
    end
  end,
  desc = "Update quickfix diagnostics",
})

vim.api.nvim_create_autocmd("BufWinEnter", {
  group = qf_group,
  pattern = "quickfix",
  callback = function()
    local syntax = [[
      syn match qfFileName /^[^│]*/ nextgroup=qfSeparatorRight
      syn match qfSeparatorRight '│' contained nextgroup=qfError,qfWarning,qfInfo,qfNote,qfManual
      syn match qfManual / .*$/ contained
      syn match qfError / %s.*$/ contained
      syn match qfWarning / %s.*$/ contained
      syn match qfNote / %s.*$/ contained
      syn match qfInfo / %s.*$/ contained

      hi def link qfFileName Directory
      hi def link qfSeparatorRight Delimiter
      hi def link qfError DiagnosticError
      hi def link qfWarning DiagnosticWarn
      hi def link qfInfo DiagnosticInfo
      hi def link qfNote DiagnosticHint
      hi def link qfManual DiagnosticHint
      ]]
    local command = syntax:format(signs.E, signs.W, signs.H, signs.I)
    vim.cmd(command)

    vim.opt.wrap = true
    vim.bo.modifiable = true
    -- :vimgrep's quickfix window display format now includes start and end column (in vim and nvim) so adding 2nd format to match that
    vim.bo.errorformat = "%f|%l col %c| %m,%f|%l col %c-%k| %m"
    vim.keymap.set(
      "n",
      "<C-s>",
      '<Cmd>cgetbuffer|set nomodified|echo "quickfix/location list updated"<CR>',
      { buffer = true, desc = "Update quickfix/location list with changes made in quickfix window" }
    )
  end,
  desc = "Allow updating quickfix window",
})

vim.api.nvim_create_autocmd("BufWinEnter", {
  group = qf_group,
  pattern = "quickfix",
  callback = function()
    -- https://gitlab.com/ranjithshegde/dotbare/-/blob/master/.config/nvim/lua/r/extensions/qf.lua
    local function t_filter(item)
      return item ~= false
    end

    local function delete(bufnr)
      bufnr = bufnr or vim.api.nvim_get_current_buf()
      local qfl = vim.fn.getqflist()

      local mode = vim.fn.mode()
      if mode == "v" or mode == "V" then
        local _, ls, _ = unpack(vim.fn.getpos("v"))
        local _, le, _ = unpack(vim.fn.getpos("."))
        for i = ls, le do
          qfl[i] = false
        end
        qfl = vim.tbl_filter(t_filter, qfl)
        vim.fn.setqflist({}, "r", { items = qfl })
        vim.api.nvim_input("<Esc>")
      else
        local line = unpack(vim.api.nvim_win_get_cursor(0))
        table.remove(qfl, line)
        vim.fn.setqflist({}, "r", { items = qfl })
        vim.fn.setpos(".", { bufnr, line, 1, 0 })
      end
    end

    vim.keymap.set("n", "j", "<down><CR><C-w>p", { buffer = 0, desc = "Next QF Item" })
    vim.keymap.set("n", "k", "<up><CR><C-w>p", { buffer = 0, desc = "Previous QF Item" })
    vim.keymap.set("n", "dd", delete, { buffer = 0, desc = "Delete QF Item" })
    vim.keymap.set({ "v" }, "d", delete, { buffer = 0, desc = "Delete QF Item" })
  end,
  once = true,
  desc = "Keymaps inside quickfix window",
})
