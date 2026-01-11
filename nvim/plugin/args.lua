local api, fn, map = vim.api, vim.fn, vim.keymap.set
local args = require('modules.args')

map('n', ']a', args.cycle_next, { desc = 'Next [A]rg' })
map('n', '[a', args.cycle_prev, { desc = 'Previous [A]rg' })
map('n', 'gaa', function()
  local count = vim.v.count
  if count ~= 0 and count <= fn.argc() then
    args.move(count)
  else
    args.select()
  end
end, { desc = 'Select [A]rg Buffer' })
map('n', 'gai', args.insert, { desc = '[A]rg [I]nsert' })
map('n', 'gad', ':argdo ', { desc = '[A]rg[D]o' })
map('n', 'gar', args.remove, { desc = '[A]rg [R]emove' })
map('n', 'gaR', args.remove_select, { desc = '[A]rg [R]emove Selected' })
map('n', 'gao', args.only, { desc = '[A]rg [O]nly' })
map('n', 'gac', '<cmd>%argdelete<CR>', { desc = '[A]arglist [C]lean', silent = true })

--------------------------------------------------
-- Update Arglist
--------------------------------------------------

local args_augroup = api.nvim_create_augroup('Arglist', { clear = true })
api.nvim_create_autocmd({ 'BufEnter' }, {
  group = args_augroup,
  callback = function()
    local buf = args.getBufName(0)
    for i, a in ipairs(args.getArgs()) do
      if a == buf and i ~= fn.argidx() + 1 then
        args.move(i)
      end
    end
  end,
  desc = 'Update arglist when changing buffers',
})
