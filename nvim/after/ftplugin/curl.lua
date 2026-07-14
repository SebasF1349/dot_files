vim.bo.commentstring = '# %s'

vim.api.nvim_set_hl(0, '@curl.program', { link = '@function' })
vim.api.nvim_set_hl(0, '@flag', { link = '@keyword' })
vim.api.nvim_set_hl(0, '@http.method', { link = '@operator' })
vim.api.nvim_set_hl(0, '@url', { link = '@text' })
vim.api.nvim_set_hl(0, '@string.value', { link = '@string' })

vim.treesitter.language.register('bash', 'curl')

local function get_lines_between_blanks()
  local cursor_row = vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

  local bottom = cursor_row
  while bottom <= #lines and lines[bottom] ~= '' do
    bottom = bottom + 1
  end

  local top = cursor_row
  while top >= 1 do
    if vim.startswith(lines[top], 'curl') then
      break
    end
    top = top - 1
  end
  if top < 1 then
    top = cursor_row
  end

  local slice = {}
  for i = top, bottom - 1 do
    table.insert(slice, lines[i])
  end
  return table.concat(slice, '\n')
end

local function starts_with_bracket(line)
  if not line then return false end
  local first_char = (vim.trim(line)):sub(1, 1)
  return first_char == '[' or first_char == '{'
end

vim.keymap.set('n', '<CR>', function()
  local get_timing = ' --write-out "\nTotal time: %{time_total}s"'
  local cmd = get_lines_between_blanks()

  local output = vim.fn.systemlist(cmd .. get_timing)
  local is_json = starts_with_bracket(output[1])

  if is_json and vim.fn.executable('jq') then
    local timing = table.remove(output)
    local json_formatted = vim.system({ 'jq', '.' }, { text = true, stdin = output }):wait(10000).stdout
    if json_formatted then
      output = vim.split(json_formatted, '\n')
    end
    table.insert(output, timing)
  end

  local buf = vim.api.nvim_create_buf(false, true)

  vim.api.nvim_open_win(buf, true, { split = 'below', win = 0 })

  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].swapfile = false
  if is_json then
    vim.bo[buf].filetype = 'json'
  end

  vim.api.nvim_buf_set_lines(0, 0, -1, false, output)
end, { silent = true, desc = 'Execute Curl', buf = 0 })

local request_opts = {
  GET = [[curl -s "https://${1:url}"]],
  POST_JSON = [[curl -s -X POST "https://${1:url}" \
    -H "Content-Type: application/json" \
    -d '{${2:body}}']],
}

vim.api.nvim_create_user_command('CurlCreate', function(opts)
  local arg = opts.args

  if request_opts[arg] == nil then
    vim.notify('Invalid option: ' .. arg, vim.log.levels.ERROR)
    return
  end

  vim.snippet.expand(request_opts[arg])
end, {
  nargs = 1,
  complete = function(arg_lead)
    local keys = vim.tbl_keys(request_opts)
    return vim.tbl_filter(function(key)
      return key:lower():find(arg_lead:lower(), 1, true) ~= nil
    end, keys)
  end,
  desc = 'Create a template for a curl command',
})

vim.keymap.set('n', '<leader>c', ':CurlCreate ', { desc = '[C]reate Curl', buf = 0 })

-- <CR> keymap heavily inspired by https://github.com/oysandvik94/curl.nvim/tree/3ee14fbafc8169fc803e80562ce7ac5b4474bdff
