local M = {}

---@param bufnr number
---@param winOpts vim.api.keyset.win_config
---@return integer
function M.create_win(bufnr, winOpts)
  local winnr = vim.api.nvim_open_win(bufnr, true, {
    relative = winOpts.relative or 'editor',
    width = winOpts.width,
    height = winOpts.height,
    row = winOpts.row,
    col = winOpts.col,
    zindex = 1000,
    style = 'minimal',
    border = winOpts.border,
    title = winOpts.title and { { winOpts.title, 'Title' } },
    title_pos = winOpts.title_pos,
    footer = winOpts.footer and { { winOpts.footer, 'Title' } },
    noautocmd = true,
  })
  return winnr
end

M.autocmd_id = nil

---@class uim.OptsClosingKeys
---@field [1] string
---@field modes string[]

---@param bufnr number
---@param on_close function
---@param closing_keys (string | uim.OptsClosingKeys)[]
function M.close_mappings(bufnr, on_close, closing_keys)
  for _, key in ipairs(closing_keys) do
    if type(key) == 'string' then
      vim.keymap.set({ 'n', 'i', 'x' }, key, function()
        vim.cmd.stopinsert()
        on_close(nil)
      end, { buffer = bufnr })
    elseif type(key) == 'table' then
      vim.keymap.set(key.modes, key[1], function()
        vim.cmd.stopinsert()
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
