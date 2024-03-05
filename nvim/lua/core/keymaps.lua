-- Keymaps for better default experience
vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })

--Remap Escape
vim.keymap.set("i", "jk", "<Esc>")

-- Select all
vim.keymap.set("n", "<C-a>", "gg<S-v>G")

-- Reselect latest changed, put, or yanked text
vim.keymap.set("n", "gV", '"`[" . strpart(getregtype(), 0, 1) . "`]"', { expr = true, replace_keycodes = false, desc = "Visually select changed text" })

-- Save all
vim.keymap.set({ "n", "i", "x", "s" }, "<C-s>", "<Esc>:wa<cr>")

-- Remap for dealing with word wrap
vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Diagnostic keymaps
vim.keymap.set("n", "[d", function()
  vim.diagnostic.goto_prev()
  vim.api.nvim_feedkeys("zz", "n", false)
end, { desc = "Go to previous diagnostic message" })
vim.keymap.set("n", "]d", function()
  vim.diagnostic.goto_next()
  vim.api.nvim_feedkeys("zz", "n", false)
end, { desc = "Go to next diagnostic message" })
vim.keymap.set("n", "[e", function()
  vim.diagnostic.goto_prev({ namespace = 0, severity = vim.diagnostic.severity.ERROR })
  vim.api.nvim_feedkeys("zz", "n", false)
end, { desc = "Go to previous error message" })
vim.keymap.set("n", "]e", function()
  vim.diagnostic.goto_next({ namespace = 0, severity = vim.diagnostic.severity.ERROR })
  vim.api.nvim_feedkeys("zz", "n", false)
end, { desc = "Go to next error message" })
vim.keymap.set("n", "[w", function()
  vim.diagnostic.goto_prev({ namespace = 0, severity = vim.diagnostic.severity.WARN })
  vim.api.nvim_feedkeys("zz", "n", false)
end, { desc = "Go to previous warning message" })
vim.keymap.set("n", "]w", function()
  vim.diagnostic.goto_next({ namespace = 0, severity = vim.diagnostic.severity.WARN })
  vim.api.nvim_feedkeys("zz", "n", false)
end, { desc = "Go to next warning message" })
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Open floating diagnostic message" })
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostics list" })

--Open explorer
vim.keymap.set("n", "<leader>pv", function()
  local function getPath(str)
    return str:match("(.*[/\\])")
  end
  local currentfile = getPath(vim.fn.expand("%:p"))
  vim.cmd("Lexplore!" .. currentfile)
end, { desc = "Open Explorer Netrw" })

--Move things around when in visual mode
vim.keymap.set("n", "J", ":m .+1<CR>==")
vim.keymap.set("n", "K", ":m .-2<CR>==")
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Press 'H', 'L' to jump to start/end of a line (first/last char)
vim.keymap.set("n", "L", "$")
vim.keymap.set("n", "H", "^")

-- Press 'U' for undo
vim.keymap.set("n", "U", "<C-r>")

-- Add empty lines before and after cursor line
vim.keymap.set("n", "gO", "<Cmd>call append(line('.') - 1, repeat([''], v:count1))<CR>")
vim.keymap.set("n", "go", "<Cmd>call append(line('.'),     repeat([''], v:count1))<CR>")

vim.keymap.set("n", "<leader>re", ":%s/\\<<C-r><C-w>\\>/<C-r><C-w>/gcI<Left><Left><Left><Left>", { desc = "Quick search and [RE]place on the current word" })

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
vim.keymap.set("n", "<leader>+x", "<cmd>!chmod +x %<CR>", { silent = true, desc = "Make files executable" })

-- Stay in indent mode
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")

-- Do things without affecting the registers
vim.keymap.set({ "n", "v" }, "x", '"_x')
vim.keymap.set({ "n", "v" }, "X", '"_X')
vim.keymap.set({ "n", "v" }, "c", '"_c')
vim.keymap.set({ "n", "v" }, "C", '"_C')
vim.keymap.set("n", "dd", function()
  if vim.fn.getline(".") == "" then
    return '"_dd'
  end
  return "dd"
end, { desc = "Only yank from non-empty lines", expr = true })

-- Copy/paste with system clipboard
vim.keymap.set({ "n", "x" }, "gy", '"+y', { desc = "Copy to system clipboard" })
vim.keymap.set("n", "gp", '"+p', { desc = "Paste from system clipboard" })
vim.keymap.set("x", "gp", '"+P', { desc = "Paste from system clipboard" })

-- Terminal
local function get_term_buf()
  for _, buf_hndl in ipairs(vim.fn.getbufinfo() or {}) do
    if buf_hndl.name:find("^term://") ~= nil then
      return buf_hndl.bufnr, buf_hndl.hidden, buf_hndl.windows[1]
    end
  end
  return -1, -1, -1
end
vim.keymap.set({ "n", "t" }, "tt", function()
  local term_buf_num, is_hidden, term_win_id = get_term_buf()
  if term_buf_num == -1 then
    vim.cmd("vsplit | vertical resize 50 | term")
    vim.cmd("startinsert")
  elseif is_hidden == 1 then
    vim.cmd("vsplit | vertical resize 50 | b" .. term_buf_num)
    vim.cmd("startinsert")
  else
    vim.api.nvim_win_close(term_win_id, true)
  end
end, { desc = "[T]oggle [T]erminal" })

-- Move only sideways in command mode. Using `silent = false` makes movements
-- to be immediately shown.
vim.keymap.set("c", "<A-h>", "<Left>", { silent = false, desc = "Left" })
vim.keymap.set("c", "<A-l>", "<Right>", { silent = false, desc = "Right" })
-- Don't `noremap` in insert mode to have these keybindings behave exactly
-- like arrows (crucial inside TelescopePrompt)
vim.keymap.set("i", "<A-h>", "<Left>", { noremap = false, desc = "Left" })
vim.keymap.set("i", "<A-j>", "<Down>", { noremap = false, desc = "Down" })
vim.keymap.set("i", "<A-k>", "<Up>", { noremap = false, desc = "Up" })
vim.keymap.set("i", "<A-l>", "<Right>", { noremap = false, desc = "Right" })
vim.keymap.set("t", "<A-h>", "<Left>", { desc = "Left" })
vim.keymap.set("t", "<A-j>", "<Down>", { desc = "Down" })
vim.keymap.set("t", "<A-k>", "<Up>", { desc = "Up" })
vim.keymap.set("t", "<A-l>", "<Right>", { desc = "Right" })

-- window management
vim.keymap.set("n", "<A-|>", "<C-w>v", { desc = "Split Window [|]Vertically" })
vim.keymap.set("n", "<A-->", "<C-w>s", { desc = "Split Window [-]Horizontally" })
vim.keymap.set("n", "<A-e>", "<C-w>=", { desc = "Window [E]qual Size" })
vim.keymap.set("n", "<A-q>", "<cmd>close<CR>", { desc = "Window [Q]uit" })
-- Resize window
vim.keymap.set("n", "<A-<>", "5<C-w><", { desc = "Resize Window [<]Smaller Vertically" })
vim.keymap.set("n", "<A->>", "5<C-w>>", { desc = "Resize Window [>]Bigger Vertically" })
vim.keymap.set("n", "<A-,>", "5<C-w>-", { desc = "Resize Window [<]Smaller Horizontally" })
vim.keymap.set("n", "<A-.>", "5<C-w>+", { desc = "Resize Window [<]Bigger Horizontally" })
-- Move (rotate) window on row
vim.keymap.set("n", "<A-r>", "<C-w><C-r>", { desc = "Window [R]otate" })
-- Move split to main position
vim.keymap.set("n", "<A-h>", "<C-w>H", { desc = "Move Window [h]Left" })
vim.keymap.set("n", "<A-k>", "<C-w>K", { desc = "Move Window [k]Up" })
vim.keymap.set("n", "<A-j>", "<C-w>J", { desc = "Move Window [j]Down" })
vim.keymap.set("n", "<A-l>", "<C-w>L", { desc = "Move Window [l]right" })

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

set_user_var("IS_NVIM", true)

-- Move to window using the movement keys
for key, _ in pairs(nav) do
  vim.keymap.set({ "n", "t" }, "<C-" .. key .. ">", navigate(key))
end

local surround = {
  { "(", ")" },
  { "[", "]" },
  { "{", "}" },
  { "'", "'" },
  { '"', '"' },
  { "`", "`" },
  { "<", ">" },
  { "*", "*" },
  { "_", "_" },
}
for _, pair in ipairs(surround) do
  vim.keymap.set("n", "<leader>" .. pair[1], "diwi" .. pair[1] .. "<ESC>pa" .. pair[2])
  vim.keymap.set("v", "<leader>" .. pair[1], "di" .. pair[1] .. "<ESC>pa" .. pair[2])
end
