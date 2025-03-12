-- Overrides the default behaviour (a pop-up) which is useless for reading documentation.
---@param contents string[]
---@param syntax string
---@param opts table
---@return integer, integer
---@diagnostic disable-next-line: duplicate-set-field
function vim.lsp.util.open_floating_preview(contents, syntax, opts)
  local orig_win = vim.api.nvim_get_current_win()

  vim.api.nvim_set_option_value('previewheight', math.min(#contents, 10), {})

  local preview_bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(preview_bufnr, 0, -1, false, contents)

  vim.api.nvim_command('pbuffer ' .. preview_bufnr)
  vim.api.nvim_command('wincmd P')
  local preview_win = vim.api.nvim_get_current_win()

  vim.api.nvim_buf_set_name(preview_bufnr, opts.focus_id or 'LSP Preview')
  vim.api.nvim_set_option_value('filetype', 'preview', { buf = preview_bufnr })
  -- Overwrites previous filetype, but ftplugin executed already anyway.
  vim.api.nvim_set_option_value('filetype', syntax, { buf = preview_bufnr })

  vim.api.nvim_set_current_win(orig_win)

  return preview_bufnr, preview_win
end
