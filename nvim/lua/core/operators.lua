local function opfunc(func_name)
  return function()
    vim.o.operatorfunc = 'v:lua.' .. func_name
    return 'g@'
  end
end

--------------------------------------------------
-- Substitute
--------------------------------------------------

-- based on https://www.reddit.com/r/neovim/comments/xrwo05/comment/ja7oyqy/
---@param mode "char"|"line"|"block"
function _G.Substitute(mode)
  local reg = vim.fn.getreg()
  local text = vim.split(reg, '\n')
  if text[text] == '' then
    table.remove(text)
  end
  local starting = vim.api.nvim_buf_get_mark(0, '[')
  local ending = vim.api.nvim_buf_get_mark(0, ']')
  if mode == 'char' then
    vim.api.nvim_buf_set_text(0, starting[1] - 1, starting[2], ending[1] - 1, ending[2] + 1, text)
  elseif mode == 'line' then
    vim.api.nvim_buf_set_lines(0, starting[1] - 1, ending[1], true, text)
  elseif mode == 'block' then
    for i = starting[1] - 1, ending[1] - 1 do
      vim.api.nvim_buf_set_text(0, i, starting[2], i, ending[2] + 1, text)
    end
  end
end

vim.keymap.set({ 'n', 'v' }, 'S', opfunc('_G.Substitute'), { desc = '[S]ubstitute', silent = true, expr = true })

--------------------------------------------------
-- MakeLists
--------------------------------------------------

function _G.MakeList()
  local starting = vim.api.nvim_buf_get_mark(0, '[')
  local ending = vim.api.nvim_buf_get_mark(0, ']')
  local line_start = starting[1]
  local line_end = ending[1]
  vim.cmd(line_start .. ',' .. line_end .. [[s/\v^(\s*)[^a-zA-Z]*(.*)/\1- \2]])
end

vim.keymap.set({ 'n', 'v' }, 'gl', opfunc('_G.MakeList'), { desc = 'Make Markdown [L]ist', silent = true, expr = true })
