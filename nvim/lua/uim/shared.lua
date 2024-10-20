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

---@param bufnr number
---@param on_close function
---@param closing_keys (string | uim.OptsClosingKeys)[]
function M.close_mappings(bufnr, on_close, closing_keys)
  for _, key in ipairs(closing_keys) do
    if type(key) == 'string' then
      vim.keymap.set({ 'n' }, key, function()
        on_close(nil)
      end, { buffer = bufnr })
    elseif type(key) == 'table' then
      vim.keymap.set(key.modes, key[1], function()
        vim.api.nvim_input('<ESC>')
        on_close(nil)
      end, { buffer = bufnr })
    end
  end

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
