local M = {}

---@class WinOpts
---@field bufnr number
---@field height number
---@field width number
---@field border string
---@field row number
---@field col number
---@field title? string
---@field title_pos? string
---@field footer? string
---@field relative? string

---@param winOpts WinOpts
---@return integer
function M.create_win(winOpts)
  return vim.api.nvim_open_win(winOpts.bufnr, true, {
    relative = winOpts.relative or 'editor',
    width = winOpts.width,
    height = winOpts.height,
    row = winOpts.row,
    col = winOpts.col,
    zindex = 1000,
    style = 'minimal',
    border = winOpts.border,
    title = winOpts.title,
    title_pos = winOpts.title_pos,
    footer = winOpts.footer,
    noautocmd = true,
  })
end

M.autocmd_id = nil

-- TODO: remove other keymaps?
---@param bufnr number
---@param on_close function
function M.close_mappings(bufnr, on_close)
  vim.keymap.set('n', '<ESC>', function()
    on_close(nil)
  end, { buffer = bufnr })
  vim.keymap.set({ 'n', 'i' }, '<C-c>', function()
    vim.api.nvim_input('<ESC>')
    on_close(nil)
  end, { buffer = bufnr })

  local augroup = vim.api.nvim_create_augroup('ui', { clear = true })
  M.autocmd_id = vim.api.nvim_create_autocmd('BufLeave', {
    callback = function()
      on_close(nil)
    end,
    buffer = bufnr,
    once = true,
    group = augroup,
    desc = 'Close select',
  })
end

return M
