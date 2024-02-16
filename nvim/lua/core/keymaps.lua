-- Keymaps for better default experience
vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })

--Remap Escape
vim.keymap.set("i", "jk", "<Esc>")

-- Select all
vim.keymap.set("n", "<C-a>", "gg<S-v>G")

-- Save all
vim.keymap.set({ "n", "i", "x", "s" }, "<C-s>", "<Esc>:wa<cr>")

-- Remap for dealing with word wrap
vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Diagnostic keymaps
vim.keymap.set("n", "[d", function()
  vim.diagnostic.goto_prev({})
  vim.api.nvim_feedkeys("zz", "n", false)
end, { desc = "Go to previous diagnostic message" })
vim.keymap.set("n", "]d", function()
  vim.diagnostic.goto_next({})
  vim.api.nvim_feedkeys("zz", "n", false)
end, { desc = "Go to next diagnostic message" })
vim.keymap.set("n", "[e", function()
  vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.ERROR })
  vim.api.nvim_feedkeys("zz", "n", false)
end, { desc = "Go to previous error message" })
vim.keymap.set("n", "]e", function()
  vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR })
  vim.api.nvim_feedkeys("zz", "n", false)
end, { desc = "Go to next error message" })
vim.keymap.set("n", "[w", function()
  vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.WARN })
  vim.api.nvim_feedkeys("zz", "n", false)
end, { desc = "Go to previous warning message" })
vim.keymap.set("n", "]w", function()
  vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.WARN })
  vim.api.nvim_feedkeys("zz", "n", false)
end, { desc = "Go to next warning message" })
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Open floating diagnostic message" })
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostics list" })

--Open explorer
--vim.keymap.set("n", "<leader>E", "vim.cmd.Ex")
-- vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)
vim.keymap.set("n", "<leader>pv", function()
  local function getPath(str)
    return str:match("(.*[/\\])")
  end
  local currentfile = getPath(vim.fn.expand("%:p"))
  vim.cmd("Lexplore!" .. currentfile)
end)

--Move things around when in visual mode
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Press 'H', 'L' to jump to start/end of a line (first/last char)
vim.keymap.set("n", "L", "$")
vim.keymap.set("n", "H", "^")

-- Press 'U' for undo
vim.keymap.set("n", "U", "<C-r>")

--Quick search and replace on the current word
vim.keymap.set("n", "S", function()
  local cmd = ":%s/<C-r><C-w>//gI<Left><Left><Left>"
  local keys = vim.api.nvim_replace_termcodes(cmd, true, false, true)
  vim.api.nvim_feedkeys(keys, "n", false)
end)

-- Center buffer while navigating
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "{", "{zz")
vim.keymap.set("n", "}", "}zz")
vim.keymap.set("n", "G", "Gzz")
vim.keymap.set("n", "gg", "ggzz")
vim.keymap.set("n", "<C-i>", "<C-i>zz")
vim.keymap.set("n", "<C-o>", "<C-o>zz")
vim.keymap.set("n", "%", "%zz")
vim.keymap.set("n", "*", "*zz")
vim.keymap.set("n", "#", "#zz")

vim.keymap.set("n", "Q", "<nop>")

--Make files executable
vim.keymap.set("n", "<leader>+x", "<cmd>!chmod +x %<CR>", { silent = true })

-- split screen and navigation
--[[ vim.keymap.set('n', '<leader>v', ':vsplit<CR><C-w>l', { noremap = true })
vim.keymap.set('n', '<leader>h', ':wincmd h<CR>', { noremap = true })
vim.keymap.set('n', '<leader>l', ':wincmd l<CR>', { noremap = true }) ]]

-- buffer movement
-- vim.keymap.set("n", "<C-n>", "<C-i>", { desc = "Change to [N]ext buffer" })
-- vim.keymap.set("n", "<C-p>", "<C-o>", { desc = "Change to [P]revious buffer" })
-- vim.keymap.set("n", "<leader>,", "<C-^>", { desc = "Switch to last buffer" })

-- window management
vim.keymap.set("n", "<A-i>", "<C-w>v", { desc = "[S]plit Window [i]Vertically" }) -- split window vertically
vim.keymap.set("n", "<A-->", "<C-w>s", { desc = "[S]plit Window [-]Horizontally" }) -- split window horizontally
vim.keymap.set("n", "<A-e>", "<C-w>=", { desc = "[S]plits [E]qual Size" }) -- make split windows equal width & height
vim.keymap.set("n", "<A-x>", "<cmd>close<CR>", { desc = "[S]plit [x]Close" }) -- close current split window
-- -- Change active window
-- vim.keymap.set("n", "sh", "<C-w>h", { desc = "Move cursor to [S]plit [h]Left" })
-- vim.keymap.set("n", "sk", "<C-w>k", { desc = "Move cursor to [S]plit [k]Up" })
-- vim.keymap.set("n", "sj", "<C-w>j", { desc = "Move cursor to [S]plit [j]Down" })
-- vim.keymap.set("n", "sl", "<C-w>l", { desc = "Move cursor to [S]plit [l]right" })
-- -- Resize window
-- vim.keymap.set("n", "s<", "5<C-w><", { desc = "Resize [S]plit [<]Smaller Vertically" })
-- vim.keymap.set("n", "s>", "5<C-w>>", { desc = "Resize [S]plit [>]Bigger Vertically" })
-- vim.keymap.set("n", "s.", "5<C-w>-", { desc = "Resize [S]plit [<]Smaller Horizontally" })
-- vim.keymap.set("n", "s,", "5<C-w>+", { desc = "Resize [S]plit [<]Bigger Horizontally" })
-- -- Move (rotate) window on row
-- vim.keymap.set("n", "sr", "<C-w><C-r>", { desc = "[S]plit [R]otate" })
-- -- Move split to main position
-- vim.keymap.set("n", "sH", "<C-w>H", { desc = "Move [S]plit [h]Left" })
-- vim.keymap.set("n", "sK", "<C-w>K", { desc = "Move [S]plit [k]Up" })
-- vim.keymap.set("n", "sJ", "<C-w>J", { desc = "Move [S]plit [j]Down" })
-- vim.keymap.set("n", "sL", "<C-w>L", { desc = "Move [S]plit [l]right" })

-- Stay in indent mode
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")

-- Do things without affecting the registers
vim.keymap.set("n", "<Leader>c", '"_c')
vim.keymap.set("n", "<Leader>C", '"_C')
vim.keymap.set("v", "<Leader>c", '"_c')
vim.keymap.set("v", "<Leader>C", '"_C')
vim.keymap.set("n", "<Leader>d", '"_d')
vim.keymap.set("n", "<Leader>D", '"_D')
vim.keymap.set("v", "<Leader>d", '"_d')
vim.keymap.set("v", "<Leader>D", '"_D')

-- Terminal
vim.keymap.set("n", "tt", ":vsplit | vertical resize 50 | term<cr>i")
vim.keymap.set("t", "jk", "<C-\\><C-n><C-w>w")
vim.keymap.set("t", "sx", "<cmd>close<CR>")

local nav = {
  h = "Left",
  j = "Down",
  k = "Up",
  l = "Right",
}

local function navigate(dir)
  return function()
    local win = vim.api.nvim_get_current_win()
    vim.cmd.wincmd(dir)
    -- local pane = vim.env.WEZTERM_PANE
    local pane = vim.loop.os_uname().release:find("WSL")
    if not pane and win == vim.api.nvim_get_current_win() then
      local pane_dir = nav[dir]
      vim.system({ "wezterm", "cli", "activate-pane-direction", pane_dir }, { text = true }, function(p)
        if p.code ~= 0 then
          vim.notify("Failed to move to pane " .. pane_dir .. "\n" .. p.stderr, vim.log.levels.ERROR, { title = "Wezterm" })
        end
      end)
    end
  end
end

local function base64(data)
  data = tostring(data)
  local bit = require("bit")
  local b64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
  local b64, len = "", #data
  local rshift, lshift, bor = bit.rshift, bit.lshift, bit.bor

  for i = 1, len, 3 do
    local a, b, c = data:byte(i, i + 2)
    b = b or 0
    c = c or 0

    local buffer = bor(lshift(a, 16), lshift(b, 8), c)
    for j = 0, 3 do
      local index = rshift(buffer, (3 - j) * 6) % 64
      b64 = b64 .. b64chars:sub(index + 1, index + 1)
    end
  end

  local padding = (3 - len % 3) % 3
  b64 = b64:sub(1, -1 - padding) .. ("="):rep(padding)

  return b64
end

local function set_user_var(key, value)
  io.write(string.format("\027]1337;SetUserVar=%s=%s\a", key, base64(value)))
end
set_user_var("IS_NVIM", true)

-- Move to window using the movement keys
for key, dir in pairs(nav) do
  vim.keymap.set("n", "<" .. dir .. ">", navigate(key))
  vim.keymap.set("n", "<C-" .. key .. ">", navigate(key))
end
