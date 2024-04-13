-- https://gitlab.com/ranjithshegde/dotbare/-/blob/master/.config/nvim/lua/r/extensions/qf.lua
local function t_filter(item)
  return item ~= false
end

vim.opt.wrap = true

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
