local M = {}

-- TODO: Implement ->
--     - completion (string|nil)
--               Specifies type of completion supported
--               for input. Supported types are the same
--               that can be supplied to a user-defined
--               command using the "-complete=" argument.
--               See |:command-completion|
--     - highlight (function)
--               Function that will be used for highlighting
--               user inputs.

---@generic T
---@param opts vim.ui.input.Opts
---@param on_confirm fun(input?: string)
function M.input(opts, on_confirm)
  local shared = require('uim.shared')

  vim.validate('opts', opts, 'table', true)
  vim.validate('on_confirm', on_confirm, 'function')

  opts = (opts and not vim.tbl_isempty(opts)) and opts or { prompt = '', default = '' }

  local current_win = vim.api.nvim_get_current_win()

  local title_bufnr = vim.api.nvim_create_buf(false, true)
  local title_win = shared.create_win(title_bufnr, {
    relative = 'laststatus',
    height = 1,
    width = #opts.prompt,
    border = 'none',
    row = 1,
    col = 0,
  })
  vim.api.nvim_buf_set_lines(title_bufnr, 0, 1, false, { opts.prompt .. ' ' })
  vim.api.nvim_set_option_value('filetype', 'uiinputtitle', { buf = title_bufnr })
  vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = title_bufnr })
  vim.api.nvim_set_option_value('winhighlight', 'NormalFloat:Normal', { win = title_win })
  vim.api.nvim_set_option_value('winblend', 0, { win = title_win })

  local input_bufnr = vim.api.nvim_create_buf(false, true)
  local input_win = shared.create_win(input_bufnr, {
    relative = 'laststatus',
    height = 1,
    width = vim.o.columns - #opts.prompt,
    border = 'none',
    title = opts.prompt,
    title_pos = 'left',
    row = 1,
    col = #opts.prompt,
  })
  if opts.default then
    vim.api.nvim_buf_set_lines(input_bufnr, 0, #opts.default, false, { opts.default })
    vim.api.nvim_win_set_cursor(input_win, { 1, #opts.default + 1 })
  else
    vim.cmd.startinsert()
  end
  vim.api.nvim_set_option_value('filetype', 'uiinput', { buf = input_bufnr })
  vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = input_bufnr })
  vim.api.nvim_set_option_value('winhighlight', 'NormalFloat:Normal', { win = input_win })
  vim.api.nvim_set_option_value('winblend', 0, { win = input_win })

  local function select_and_close(input)
    vim.api.nvim_del_autocmd(shared.autocmd_id)
    vim.api.nvim_win_close(input_win, true)
    if title_win and vim.api.nvim_win_is_valid(title_win) then
      vim.api.nvim_win_close(title_win, true)
    end
    vim.api.nvim_set_current_win(current_win)
    on_confirm(input)
  end

  vim.keymap.set({ 'n', 'i', 'x' }, '<CR>', function()
    vim.api.nvim_input('<ESC>')
    local line = vim.api.nvim_buf_get_lines(input_bufnr, 0, 1, false)[1]
    select_and_close(line)
  end, { buffer = input_bufnr })

  local closing_keys = { { 'q', modes = { 'n', 'v' } }, '<C-c>' }
  shared.close_mappings(input_bufnr, select_and_close, closing_keys)
end

return M
