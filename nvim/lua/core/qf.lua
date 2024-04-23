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

vim.opt.grepprg = "rg --vimgrep --smart-case"
vim.opt.grepformat = "%f:%l:%c:%m"

vim.api.nvim_create_user_command("Rg", function(opts)
  diagnostics_open = false
  vim.cmd('silent grep!"' .. opts.args .. '"')
  vim.cmd("copen")
end, { nargs = 1 })

-- https://github.com/oncomouse/dotfiles/blob/5abf79588d28379aa071fc7767dda46b9d90fb74/conf/vim/init.lua#L190-L205
local function grep_or_filter()
  if vim.opt.buftype:get() == "quickfix" then
    vim.cmd([[packadd cfilter]])
    local input = vim.fn.input("QFGrep/")
    if #input > 0 then
      local prefix = vim.fn.getwininfo(vim.fn.win_getid())[1].loclist == 1 and "L" or "C"
      vim.cmd(prefix .. "filter /" .. input .. "/")
    end
  else
    local input = vim.fn.input("Grep/")
    if #input > 0 then
      vim.cmd('silent! grep! "' .. input .. '"')
      vim.cmd("copen")
    end
  end
end

vim.keymap.set("n", "<leader>rg", grep_or_filter, { desc = "[R]ip[G]rep" })

--------------------------------------------------
-- Better Quickfix Window Style
--------------------------------------------------

---@diagnostic disable-next-line: duplicate-set-field
function _G.qftf(info)
  local items
  local ret = {}
  if info.quickfix == 1 then
    items = vim.fn.getqflist({ id = info.id, items = 0 }).items
  else
    items = vim.fn.getloclist(info.winid, { id = info.id, items = 0 }).items
  end
  local limit = math.floor(math.max(31, vim.o.columns / 3))
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
          fname = vim.fn.fnamemodify(fname, ":p:~:.")
          local file_name = vim.fn.fnamemodify(fname, ":p:t")
          local file_path = vim.fn.fnamemodify(fname, ":h")
          if #file_name > limit then
            fname = fnameFmt2:format(file_name:sub(1 - limit))
          elseif #file_path + #file_name + 2 > limit then
            file_path = fnameFmt2:format(file_path:sub(2 - limit + #file_name))
            fname = file_name .. " " .. file_path
          else
            fname = file_name .. " " .. (file_path ~= "." and file_path or "")
          end
        end
        fname = fnameFmt1:format(fname)
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
-- Quickfix Keymaps
--------------------------------------------------

--- type='c': qf toggle and send to bottom
--- type='d': qf toggle with diagnostics
--- type='l': loclist toggle (all windows)
local function list_toggle(type)
  local status
  if type == "c" or type == "d" then
    status = vim.fn.getqflist({ winid = 0 }).winid ~= 0
  else
    status = vim.fn.getloclist(0, { winid = 0 }).winid ~= 0
  end
  if status then
    if type == "c" or type == "d" then
      vim.cmd("cclose")
    else
      vim.cmd("lclose")
    end
    diagnostics_open = false
  elseif (type == "l" and #vim.fn.getloclist(0) == 0) or (type == "c" and #vim.fn.getqflist() == 0) or (type == "d" and #vim.diagnostic.get() == 0) then
    vim.cmd([[echohl ErrorMsg
			echo 'List is Empty.'
			echohl NONE]])
  else
    if type == "d" then
      vim.diagnostic.setqflist()
      diagnostics_open = true
    else
      vim.cmd(type .. "open")
    end
  end
end

vim.keymap.set("n", "<leader>tq", function()
  diagnostics_open = false
  list_toggle("c")
end, { desc = "[T]oggle [Q]uickfix" })
vim.keymap.set("n", "<leader>qd", function()
  diagnostics_open = false
  list_toggle("d")
end, { desc = "[Q]uickfix [D]iagnostics Toggle" })
vim.keymap.set("n", "]q", "<cmd>cnext<CR>", { desc = "Next [Q]uickfix Item" })
vim.keymap.set("n", "[q", "<cmd>cprev<CR>", { desc = "Previous [Q]uickfix Item" })

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
      syn match qfFileName /^[^ ]*/ nextgroup=qfFilePath
      syn match qfFilePath / [^│]*/ nextgroup=qfSeparatorRight
      syn match qfSeparatorRight '│' contained nextgroup=qfError,qfWarning,qfInfo,qfNote,qfManual
      syn match qfManual / .*$/ contained
      syn match qfError / %s.*$/ contained
      syn match qfWarning / %s.*$/ contained
      syn match qfNote / %s.*$/ contained
      syn match qfInfo / %s.*$/ contained

      hi def link qfFileName Directory
      hi def link qfFilePath NonText
      hi def link qfSeparatorRight Delimiter
      hi def link qfError DiagnosticError
      hi def link qfWarning DiagnosticWarn
      hi def link qfInfo DiagnosticInfo
      hi def link qfNote DiagnosticHint
      hi def link qfManual FloatTitle
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
