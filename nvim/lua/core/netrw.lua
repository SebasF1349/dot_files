-- netrw options
vim.g.netrw_liststyle = 0
vim.g.netrw_banner = 0
vim.g.netrw_sort_options = "i"
vim.g.netrw_winsize = 20

vim.keymap.set("n", "<leader>n", function()
  local function getPath(str)
    return str:match("(.*[/\\])")
  end
  local currentfile = getPath(vim.fn.expand("%:p"))
  vim.cmd("Lexplore! " .. currentfile)
end, { desc = "Open Explorer [N]etrw" })

local netrw = vim.api.nvim_create_augroup("NetRW", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  group = netrw,
  pattern = "netrw",
  callback = function()
    vim.o.nu = true
    vim.o.rnu = true
    vim.keymap.set("n", "w", "<cmd>Ex " .. vim.fn.getcwd() .. "<CR>", { noremap = true, silent = true, buffer = true })
    vim.keymap.set("n", "<C-C>", "<cmd>bdel<CR>", { noremap = true, silent = true, buffer = true })
    vim.keymap.set("n", "q", "<cmd>bdel<CR>", { noremap = true, silent = true, buffer = true })
    vim.keymap.set("n", "h", "gh", { remap = true, silent = true, buffer = true })
    vim.keymap.set("n", "r", "R", { remap = true, silent = true, buffer = true })
    local unbinds = {
      "<del>",
      "<c-h>",
      "<c-r>",
      "<c-tab>",
      "a",
      "C",
      "gb",
      "gd",
      "gf",
      "gn",
      "gp",
      "i",
      "I",
      "mb",
      "mc",
      "md",
      "me",
      "mf",
      "mF",
      "mg",
      "mh",
      "mm",
      "mr",
      "mt",
      "mT",
      "mu",
      "mv",
      "mx",
      "mX",
      "mz",
      "o",
      "O",
      "p",
      "P",
      "qb",
      "qf",
      "qF",
      "qL",
      "s",
      "S",
      "t",
      "u",
      "U",
      "v",
      "x",
      "X",
    }
    for _, value in pairs(unbinds) do
      vim.keymap.set("n", value, function()
        vim.notify("Keybind '" .. value .. "' has been removed", vim.log.levels.WARN)
      end, { noremap = true, silent = true, buffer = true })
    end
  end,
  desc = "NetRW keymaps and options",
})
