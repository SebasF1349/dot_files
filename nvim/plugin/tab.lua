-- https://github.com/TheLeoP/nvim-config/blob/master/plugin/tab.lua
local api, fn = vim.api, vim.fn

function _G._personal_tab()
  local last = fn.tabpagenr('$')
  local current = fn.tabpagenr()

  local out = {} ---@type string[]
  for i = 1, last do
    table.insert(out, i == current and '%#TabLineSel#' or '%#TabLine#')

    table.insert(out, (' %d: %%{v:lua._personal_tab_label(%d)} '):format(i, i))
  end

  return table.concat(out)
end

---@param i integer
function _G._personal_tab_label(i)
  local buflist = fn.tabpagebuflist(i) ---@type integer[]
  local winnr = fn.tabpagewinnr(i)
  local buf = buflist[winnr]
  if not buf then return end
  local name = api.nvim_buf_get_name(buf)
  local protocol = name:match('^(.*)://')
  if name == '' then
    return '[No name]'
  elseif protocol == 'fugitive' or protocol == 'health' then
    return protocol .. '://'
  elseif vim.endswith(name, '/') or vim.endswith(name, '\\') then
    local dirname = name:sub(1, -2)
    local tail = fn.fnamemodify(dirname, ':t')
    return tail .. '/'
  end
  local tail = fn.fnamemodify(name, ':t')
  return tail
end

vim.o.tabline = '%{%v:lua._personal_tab()%}'
