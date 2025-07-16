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
---@param opts { prompt: string|nil, default: string|nil, completion: string|nil, highlight: fun(item: T): string } Additional options
---@param on_confirm fun(input: string|nil)
function M.input(opts, on_confirm)
  local config = require('uim.config').opts
  local shared = require('uim.shared')

  vim.validate({
    opts = { opts, 'table', true },
    on_confirm = { on_confirm, 'function', false },
  })

  opts = (opts and not vim.tbl_isempty(opts)) and opts or vim.empty_dict()

  local current_win = vim.api.nvim_get_current_win()

  local column = 0
  local row = vim.o.lines - 1 - vim.o.cmdheight - (vim.o.laststatus ~= 0 and 1 or 0)
  local title_win

  local input_bufnr = vim.api.nvim_create_buf(false, true)
  ---@type WinOpts
  local win_opts = {
    bufnr = input_bufnr,
    height = 1,
    width = vim.o.columns - column,
    border = config.input.border,
    title = opts.prompt,
    title_pos = config.input.title_pos,
    row = row,
    col = column,
  }
  if config.input.position == 'cmdline' then
    local title_bufnr = vim.api.nvim_create_buf(false, true)
    title_win = shared.create_win({
      bufnr = title_bufnr,
      height = 1,
      width = #opts.prompt,
      border = 'none',
      row = vim.o.lines,
      col = 0,
    })
    vim.api.nvim_buf_set_lines(title_bufnr, 0, 1, false, { opts.prompt .. ' ' })
    vim.api.nvim_set_option_value('filetype', 'uiinputtitle', { buf = title_bufnr })
    vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = title_bufnr })
    vim.api.nvim_set_option_value('winhighlight', 'NormalFloat:Normal', { win = title_win })
    vim.api.nvim_set_option_value('winblend', 0, { win = title_win })
    win_opts.col = #opts.prompt
    win_opts.row = vim.o.lines
    win_opts.width = vim.o.columns - win_opts.col
    win_opts.border = 'none'
  elseif config.input.position == 'bottom' then
    win_opts.width = vim.o.columns
    win_opts.row = vim.o.lines
      - win_opts.height
      - vim.o.cmdheight
      - (vim.o.laststatus ~= 0 and 1 or 0)
      - (win_opts.border ~= 'none' and 2 or 0)
    win_opts.col = 0
  elseif config.input.position == 'right' then
    win_opts.width = math.floor(vim.o.columns / 3)
    win_opts.row = vim.o.lines
      - win_opts.height
      - vim.o.cmdheight
      - (vim.o.laststatus ~= 0 and 1 or 0)
      - (win_opts.border ~= 'none' and 2 or 0)
    win_opts.col = vim.o.columns - win_opts.width
  elseif config.input.position == 'center' then
    win_opts.width = math.floor(vim.o.columns / 3)
    win_opts.row = vim.o.lines / 4
    win_opts.col = (vim.o.columns - win_opts.width) / 2
  elseif config.input.position == 'cursor' then
    win_opts.relative = 'cursor'
    win_opts.width = math.floor(vim.o.columns / 4)
    win_opts.row = 1
    win_opts.col = 0
  end

  local input_win = shared.create_win(win_opts)

  if opts.default then
    vim.api.nvim_buf_set_lines(input_bufnr, 0, #opts.default, false, { opts.default })
    vim.api.nvim_win_set_cursor(input_win, { 1, #opts.default + 1 })
  else
    vim.cmd.startinsert()
  end
  vim.api.nvim_set_option_value('filetype', 'uiinput', { buf = input_bufnr })
  vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = input_bufnr })
  if config.input.position == 'cmdline' then
    vim.api.nvim_set_option_value('winhighlight', 'NormalFloat:Normal', { win = input_win })
    vim.api.nvim_set_option_value('winblend', 0, { win = input_win })
  end

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

  shared.close_mappings(input_bufnr, select_and_close, config.input.closing_keys)
end

return M
