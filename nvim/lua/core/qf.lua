--------------------------------------------------
-- Types
--------------------------------------------------

---@diagnostic disable-next-line: duplicate-doc-alias
---@alias ListType
---| '"c"' # quickfix list
---| '"l"' # location list

--------------------------------------------------
-- "Global" variables in this file
--------------------------------------------------

local signs = {
  E = " ",
  W = " ",
  H = "",
  I = " ",
}

local highlights = {
  E = "DiagnosticError",
  W = "DiagnosticWarn",
  H = "DiagnosticHint",
  I = "DiagnosticInfo",
}

--------------------------------------------------
-- Utils
--------------------------------------------------

---@param linenr number
local function getPath(linenr)
  local qflist = vim.fn.getqflist()
  if linenr > #qflist then
    return ""
  end
  local item = qflist[linenr]
  local path = vim.fn.bufname(item.bufnr)
  return path
end

--------------------------------------------------
-- Better Grep
--------------------------------------------------

vim.opt.grepprg = "rg --vimgrep --smart-case"
vim.opt.grepformat = "%f:%l:%c:%m"

vim.api.nvim_create_user_command("Rg", function(opts)
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

local qfim_namespace = vim.api.nvim_create_namespace("qfim")

---@diagnostic disable-next-line: duplicate-set-field
function _G.qftf(info)
  local list
  local ret = {}
  if info.quickfix == 1 then
    list = vim.fn.getqflist({ id = info.id, items = 1, qfbufnr = 1, winid = 1 })
  else
    list = vim.fn.getloclist(info.winid, { id = info.id, items = 1, qfbufnr = 1, winid = 1 })
  end
  local qfwinid = list.winid
  vim.api.nvim_set_option_value("foldmethod", "expr", { win = qfwinid, scope = "local" })
  -- vim.api.nvim_set_option_value("fillchars", "eob: ,fold: ", { win = qfwinid })
  vim.api.nvim_set_option_value("foldexpr", "v:lua._G.qffoldexprfunc()", { win = qfwinid, scope = "local" })
  vim.api.nvim_set_option_value("foldtext", "v:lua._G.qffoldtextfunc()", { win = qfwinid, scope = "local" })
  local qfbufnr = list.qfbufnr
  list = list.items
  if info.start_idx == 1 then
    vim.api.nvim_buf_clear_namespace(qfbufnr, qfim_namespace, 0, -1)
  end
  local items = {}
  local limit = 0
  for i = info.start_idx, info.end_idx do
    local item = { index = i }
    local e = list[i]
    if e.valid == 1 then
      if e.bufnr > 0 then
        local fname = vim.fn.bufname(e.bufnr)
        if fname == "" then
          item.name = " "
        else
          fname = vim.fn.fnamemodify(fname, ":p:~:.")
          item.name = vim.fn.fnamemodify(fname, ":p:t")
          item.path = vim.fn.fnamemodify(fname, ":h")
          if item.path == "." then
            item.path = ""
          end
          if #item.name + #item.path > limit then
            limit = #item.name + #item.path
          end
        end
      end
      item.type = e.type
      item.message = vim.fn.trim(e.text)
    else
      item.name = " "
      item.message = e.text
    end
    table.insert(items, item)
  end
  limit = math.floor(math.min(limit + 1, 2 * vim.o.columns / 3))
  local fnameFmt1, fnameFmt2 = "%-" .. limit .. "s", "…%." .. (limit - 1) .. "s"
  local validFmt = "%s │ %s%s"
  local highlighting = {}
  for _, item in ipairs(items) do
    local fname = ""
    local str
    if #item.name > limit then
      item.name = fnameFmt2:format(item.name:sub(1 - limit))
      item.path = ""
      fname = item.name
    elseif #item.path == 0 then
      fname = item.name
    elseif #item.path + #item.name + 1 > limit then
      item.path = fnameFmt2:format(item.path:sub(1 - limit + #item.name))
      fname = item.name .. " " .. item.path
    else
      fname = item.name .. " " .. item.path
    end
    fname = fnameFmt1:format(fname)
    local type = item.type == "" and "" or (signs[item.type] and signs[item.type] or signs.I)
    str = validFmt:format(fname, type, vim.fn.trim(item.message))
    table.insert(highlighting, {
      group = "Directory",
      line = item.index - 1,
      col = 0,
      end_col = #item.name,
    })
    table.insert(highlighting, {
      group = "Comment",
      line = item.index - 1,
      col = #item.name + 1,
      end_col = limit + 4,
    })
    table.insert(highlighting, {
      group = highlights[item.type] or "FloatTitle",
      line = item.index - 1,
      col = limit + 4,
      end_col = limit + 4 + #type + 2 + #item.message,
    })
    table.insert(ret, str)
  end
  vim.schedule(function()
    for _, hl in ipairs(highlighting) do
      vim.highlight.range(qfbufnr, qfim_namespace, hl.group, { hl.line, hl.col }, { hl.line, hl.end_col })
    end
  end)
  return ret
end

vim.o.qftf = "{info -> v:lua._G.qftf(info)}"

--------------------------------------------------
-- Keymaps
--------------------------------------------------

---@param list ListType
---@param diagnostics? boolean
local function list_toggle(list, diagnostics)
  local status
  if list == "c" then
    status = vim.fn.getqflist({ winid = 0 }).winid ~= 0
  else
    status = vim.fn.getloclist(0, { winid = 0 }).winid ~= 0
  end
  if status then
    if list == "c" then
      vim.cmd("cclose")
    else
      vim.cmd("lclose")
    end
  elseif
    (list == "l" and not diagnostics and #vim.fn.getloclist(0) == 0)
    or (list == "l" and diagnostics and #vim.diagnostic.get(0) == 0)
    or (list == "c" and not diagnostics and #vim.fn.getqflist() == 0)
    or (list == "c" and diagnostics and #vim.diagnostic.get() == 0)
  then
    vim.notify("List is Empty", vim.log.levels.WARN)
  else
    if not diagnostics then
      vim.cmd(list .. "open")
    elseif list == "c" then
      vim.diagnostic.setqflist({ title = "All Diagnostics" })
    else
      vim.diagnostic.setloclist({ title = "Local Diagnostics" })
    end
  end
end

vim.keymap.set("n", "<leader>tq", function()
  list_toggle("c")
end, { desc = "[T]oggle [Q]uickfix" })
vim.keymap.set("n", "<leader>qd", function()
  list_toggle("c", true)
end, { desc = "[Q]uickfix [D]iagnostics Toggle" })

vim.keymap.set("n", "<leader>tl", function()
  list_toggle("l")
end, { desc = "[T]oggle [L]ocation List" })
vim.keymap.set("n", "<leader>ld", function()
  list_toggle("l", true)
end, { desc = "[L]ocation List [D]iagnostics Toggle" })

local function cnext_wrap()
  ---@diagnostic disable-next-line: param-type-mismatch
  local ok, _ = pcall(vim.cmd, "cnext")
  if not ok then
    vim.cmd("cfirst")
  end
end

local function cprev_wrap()
  ---@diagnostic disable-next-line: param-type-mismatch
  local ok, _ = pcall(vim.cmd, "cprev")
  if not ok then
    vim.cmd("clast")
  end
end

vim.keymap.set("n", "]q", cnext_wrap, { desc = "Next [Q]uickfix Item Wrapping" })
vim.keymap.set("n", "[q", cprev_wrap, { desc = "Previous [Q]uickfix Item Wrapping" })

--------------------------------------------------
-- Quickfix Autocmds
--------------------------------------------------

local qf_group = vim.api.nvim_create_augroup("qflist", { clear = true })

-- https://github.com/neovim/nvim-lspconfig/issues/69#issuecomment-1877781941
-- NOTE: extend to update location list too
vim.api.nvim_create_autocmd({ "DiagnosticChanged" }, {
  group = vim.api.nvim_create_augroup("user_diagnostic_qflist", {}),
  callback = function(args)
    local qf_info = vim.fn.getqflist({ title = 0, id = 0 })
    if qf_info.title ~= "All Diagnostics" then
      return
    end
    local diagnostics = vim.diagnostic.get()
    if #diagnostics == 0 then
      vim.cmd("cclose")
    end
    local qf_items = vim.diagnostic.toqflist(
      -- TODO: Can the event data have items not returned by vim.diagnostic.get?
      -- If not, we don't need to extend the diagnostics variable here.
      vim.tbl_deep_extend("force", diagnostics, args.data.diagnostics)
    )

    vim.schedule(function()
      vim.fn.setqflist({}, qf_info.title == "All Diagnostics" and "r" or " ", {
        title = "All Diagnostics",
        items = qf_items,
      })

      -- Don't steal focus from other qflists. For example, when working through
      -- vimgrep results, you likely want :cnext to take you to the next match,
      -- rather than the next diagnostic. Use :cnew to switch to the diagnostic
      -- qflist when you want it.
      if qf_info.id ~= 0 and qf_info.title ~= "All Diagnostics" then
        vim.cmd.cold()
      end
    end)
  end,
})

---@param listType ListType
---@return number
local function getHeight(listType)
  local list
  if listType == "c" then
    list = vim.fn.getqflist({ size = 1 })
  else
    list = vim.fn.getloclist(0, { size = 1 })
  end
  return math.max(math.min(list.size, 10), 5)
end

---@diagnostic disable-next-line: duplicate-set-field
function _G.qffoldexprfunc()
  local line = getPath(vim.v.lnum)
  local next_line = getPath(vim.v.lnum + 1)
  if line == next_line then
    return "1"
  else
    return "<1"
  end
end

---@diagnostic disable-next-line: duplicate-set-field
function _G.qffoldtextfunc()
  local line = vim.fn.getline(vim.v.foldstart)
  local splitted = vim.split(line, "│")
  local path = vim.split(splitted[1], " ")
  local whitespace = #path[2] ~= 0 and #splitted[1] - #vim.trim(splitted[1]) or #splitted[1] - #vim.trim(splitted[1]) - 1
  local highlighting = {
    { path[1] .. " ", "DiagnosticInfo" },
    { path[2] .. (" "):rep(whitespace), "Comment" },
    { "│", "Comment" },
    { " +-- " .. vim.v.foldend - vim.v.foldstart + 1 .. " lines", "DiagnosticInfo" },
  }
  return highlighting
end

vim.api.nvim_create_autocmd("BufWinEnter", {
  group = qf_group,
  pattern = "quickfix",
  callback = function()
    vim.opt.number = true
    vim.opt_local.relativenumber = false
    vim.opt_local.statuscolumn = ""
    -- vim.opt_local.wrap = true
    vim.opt_local.hidden = true
    vim.bo.modifiable = true
    vim.bo.buflisted = false
    vim.wo.winfixheight = true
    vim.api.nvim_win_set_height(0, getHeight("c"))
    -- :vimgrep's quickfix window display format now includes start and end column (in vim and nvim) so adding 2nd format to match that
    vim.bo.errorformat = "%f|%l col %c| %m,%f|%l col %c-%k| %m"
    vim.keymap.set(
      "n",
      "<C-s>",
      '<Cmd>cgetbuffer|set nomodified|echo "quickfix/location list updated"<CR>',
      { buffer = true, desc = "Update quickfix/location list with changes made in quickfix window" }
    )
  end,
  desc = "Qf syntax + options",
})

--------------------------------------------------
-- Keymaps inside Quickfix
--------------------------------------------------

---@param line string
local function getMessage(line)
  local path, _ = line:gsub("^.*│", "")
  return path
end

---@param move "up" | "down"
local function jumpFileChunk(move)
  local path = getPath(vim.fn.line("."))
  local direction = move == "down" and "j" or "k"
  local finish = move == "down" and "$" or 1

  while path == getPath(vim.fn.line(".")) and vim.fn.getline(".") ~= vim.fn.getline(finish) do
    vim.cmd("normal! " .. direction)
  end
  vim.cmd("normal o")
end

---@param item table | boolean
local function t_filter(item)
  return item ~= false
end

---@param bufnr number
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
    vim.fn.setqflist({}, "r", {
      title = "All Diagnostics",
      items = qfl,
    })
    vim.api.nvim_input("<Esc>")
  else
    local line = unpack(vim.api.nvim_win_get_cursor(0))
    table.remove(qfl, line)
    vim.fn.setqflist({}, "r", {
      title = "All Diagnostics",
      items = qfl,
    })
    vim.fn.setpos(".", { bufnr, line, 1, 0 })
  end
end

local function getPreview()
  local wins = vim.api.nvim_list_wins()
  for _, win in ipairs(wins) do
    local preview = vim.api.nvim_get_option_value("previewwindow", { win = win })
    if preview then
      return win
    end
  end
  return nil
end

local function openPreview()
  local path = getPath(vim.fn.line("."))
  if not path then
    -- NOTE: this should be improved checking the actual qflist
    vim.print("Not possible to get path")
    return
  end
  local preview = getPreview()
  vim.cmd("pedit " .. path)
  if preview == nil then
    local key = vim.api.nvim_replace_termcodes("<C-w>", true, false, true)
    vim.api.nvim_feedkeys(key .. "J", "n", false)
  end
end

local function hover()
  local message = getMessage(vim.fn.getline("."))
  vim.lsp.util.open_floating_preview(vim.split(vim.trim(message), "\n"), "markdown", { border = "rounded" })
end

vim.api.nvim_create_autocmd("BufWinEnter", {
  group = qf_group,
  pattern = "quickfix",
  callback = function()
    -- vim.keymap.set("n", "j", "<down><CR><C-w>p", { buffer = 0, desc = "Next QF Item" })
    -- vim.keymap.set("n", "k", "<up><CR><C-w>p", { buffer = 0, desc = "Previous QF Item" })
    vim.keymap.set("n", "<CR>", "<CR>", { buffer = 0, desc = "Open QF item" }) -- idk why this is needed
    vim.keymap.set("n", "o", "<CR><C-w>p", { buffer = 0, desc = "Open and Stay in QF" })
    vim.keymap.set("n", "O", "<CR><cmd>cclose<CR>", { buffer = 0, desc = "Open and Close QF" })
    vim.keymap.set("n", "p", openPreview, { buffer = 0, desc = "Open and Close QF" })
    vim.keymap.set("n", "K", hover, { buffer = 0, desc = "Show full line on hover" })
    vim.keymap.set("n", "dd", delete, { buffer = 0, desc = "Delete QF Item" })
    vim.keymap.set({ "v" }, "d", delete, { buffer = 0, desc = "Delete QF Item" })
    vim.keymap.set("n", "]Q", function()
      jumpFileChunk("down")
    end, { desc = "Next [Q]uickfix File" })
    vim.keymap.set("n", "[Q", function()
      jumpFileChunk("up")
    end, { desc = "Previous [Q]uickfix File" })
  end,
  once = true,
  desc = "Keymaps inside quickfix window",
})

--------------------------------------------------
-- Ideas to Implement
--------------------------------------------------
-- quit Vim if the last window is a location/quickfix window (qf.vim)
-- maybe open the qf window automatically after :make, :grep, :lvimgrep
--          and friends if there are valid locations/errors (qf.vim)
-- shorten filepaths for better legibility (qf.vim)

-- location list
-- make every qf feature available for location windows too (qf.vim)
-- close the location window automatically when quitting parent window (qf.vim)

--------------------------------------------------
-- Credits
--------------------------------------------------
-- https://github.com/romainl/vim-qf (taken a lot of viml code of it)
-- https://github.com/yorickpeterse/nvim-pqf/tree/main (to make highlighting in lua)
-- https://github.com/ashfinal/qfview.nvim (for the folding code)
-- https://github.com/ten3roberts/qf.nvim (for some ideas)
-- https://github.com/folke/trouble.nvim (for the hover idea)
