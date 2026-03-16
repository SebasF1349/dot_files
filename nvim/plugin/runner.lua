local bufnr, winid

local function set_playground_opts(ft)
  vim.bo.filetype = ft
  vim.bo.buflisted = false
  vim.wo.statuscolumn = ''
  vim.wo.winfixbuf = true
  vim.keymap.set('n', 'q', '<cmd>bd! | pclose<cr>', { buffer = bufnr, desc = '[Q]uit' })
  vim.keymap.set({ 'n', 'x' }, '<CR>', ':RunCode<CR>', { buffer = bufnr, desc = '[R]un Code' })
end

local function create_playground(ft)
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    bufnr = vim.api.nvim_create_buf(false, true)
    winid = vim.api.nvim_open_win(bufnr, true, { split = 'right', win = 0, width = 100 })
    set_playground_opts(ft)
    if vim.b.runners.prefix then
      vim.api.nvim_buf_set_lines(bufnr, 0, 0, false, { vim.b.runners.prefix, '' })
    end
    vim.cmd.startinsert()
  else
    winid = vim.api.nvim_open_win(bufnr, true, { split = 'right', win = 0, width = 100 })
  end
end

local function toggle_playground()
  if not winid or not vim.api.nvim_win_is_valid(winid) then
    local runners = vim.b.runners
    if not runners or vim.tbl_isempty(runners) then
      vim.notify('Runner not setup for this filetype', vim.log.levels.ERROR)
      return
    end
    create_playground(vim.bo.filetype)
  else
    vim.api.nvim_win_hide(winid)
    vim.cmd('pclose')
  end
end

local function run_code(opts)
  opts = opts or {}
  local version = opts.args and opts.args ~= '' and opts.args or nil

  local runners = vim.b.runners
  if not runners or vim.tbl_isempty(runners) then
    vim.notify('Runner not setup for this filetype', vim.log.levels.ERROR)
    return
  end

  local cmd = version and runners[version] or runners.default or runners[next(runners)]

  if not cmd then
    vim.notify("Cmd '" .. cmd .. "' not found in vim.b.runners", vim.log.levels.ERROR)
    return
  end

  local lines
  if opts.range > 0 then
    lines = vim.api.nvim_buf_get_lines(0, opts.line1 - 1, opts.line2, false)
  else
    lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  end

  if lines[1] ~= runners.prefix then
    table.insert(lines, 1, runners.prefix)
  end

  local result = vim.system({ cmd }, { stdin = lines, text = true, timeout = 1000 }):wait()

  vim.cmd('belowright pedit Code\\ Output')

  local preview_win = nil
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_get_option_value('previewwindow', { win = win }) then
      preview_win = win
      break
    end
  end

  if not preview_win then
    vim.notify('Failed to create preview window', vim.log.levels.ERROR)
    return
  end

  local preview_buf = vim.api.nvim_win_get_buf(preview_win)

  vim.api.nvim_set_option_value('buftype', 'nofile', { buf = preview_buf })
  vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = preview_buf })
  vim.api.nvim_set_option_value('buflisted', false, { buf = preview_buf })
  vim.api.nvim_set_option_value('swapfile', false, { buf = preview_buf })

  local output = result.code == 0 and result.stdout or result.stderr or ''
  local output_lines = vim.split(output, '\n')
  vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, output_lines)

  local height = math.max(5, math.min(15, #output_lines))
  vim.api.nvim_win_set_height(preview_win, height)
end

local function get_completions(arg_lead)
  local completions = {}
  local runners = vim.b.runners
  for version, _ in pairs(runners) do
    if version ~= 'default' and version:find('^' .. arg_lead) then
      table.insert(completions, version)
    end
  end
  return completions
end

vim.api.nvim_create_user_command('RunCode', function(opts)
  run_code({ line1 = opts.line1, line2 = opts.line2, args = opts.args, range = opts.range })
end, { nargs = '?', range = true, complete = get_completions, desc = 'Run code in current buffer or range' })

vim.keymap.set('n', '<leader>p', toggle_playground, { desc = '[P]layground' })
