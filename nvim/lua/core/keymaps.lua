-- Keymaps for better default experience
vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })

-- Remap Escape
vim.keymap.set("i", "jk", "<Esc>")

-- Select all
vim.keymap.set("n", "<C-a>", "gg<S-v>G")

-- Reselect latest changed, put, or yanked text
vim.keymap.set("n", "gV", '"`[" . strpart(getregtype(), 0, 1) . "`]"', { expr = true, replace_keycodes = false, desc = "Visually select changed text" })

-- Save
vim.keymap.set({ "n", "i", "x", "s" }, "<C-s>", "<cmd>w<CR>")

-- Remap for dealing with word wrap
vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

vim.keymap.set("n", "<leader>n", function()
  local function getPath(str)
    return str:match("(.*[/\\])")
  end
  local currentfile = getPath(vim.fn.expand("%:p"))
  vim.cmd("Lexplore!" .. currentfile)
end, { desc = "Open Explorer [N]etrw" })

--Move things around when in visual mode
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Press 'U' for redo
vim.keymap.set("n", "U", "<C-r>")

-- Add empty lines before and after cursor line
vim.keymap.set("n", "gO", "<Cmd>call append(line('.') - 1, repeat([''], v:count1))<CR>", { desc = "Create new line above" })
vim.keymap.set("n", "go", "<Cmd>call append(line('.'),     repeat([''], v:count1))<CR>", { desc = "Create new line below" })

vim.keymap.set("n", "<leader>rp", ":%s/\\<<C-r><C-w>\\>/<C-r><C-w>/gcI<Left><Left><Left><Left>", {
  desc = "Search and [R]e[P]lace current word",
})

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
local terms = {}
local function toggle_term(num)
  local term = terms[num]
  if term.buf_num == -1 then
    vim.cmd("vsplit | vertical resize 50 | term")
    vim.cmd("startinsert")
    term.buf_num = vim.fn.bufnr()
    term.win_id = vim.fn.win_getid()
    term.is_hidden = 0
  elseif term.is_hidden == 1 then
    vim.cmd("vsplit | vertical resize 50 | b" .. term.buf_num)
    vim.cmd("startinsert")
    term.win_id = vim.fn.win_getid()
    term.is_hidden = 0
  else
    vim.api.nvim_win_close(term.win_id, true)
    term.is_hidden = 1
  end
end
for pos = 1, 2 do
  terms[pos] = { buf_num = -1 }
  vim.keymap.set({ "n", "t" }, "t" .. pos, function()
    toggle_term(pos)
  end, { desc = "Toggle [T]erminal [" .. pos .. "]" })
end
vim.keymap.set({ "n", "t" }, "tt", function()
  toggle_term(1)
end, { desc = "[T]oggle [T]erminal 1" })

-- window management
vim.keymap.set("n", "<C-\\>", "<C-w>v", { desc = "Split Window [|]Vertically" })
vim.keymap.set("n", "<C-->", "<C-w>s", { desc = "Split Window [-]Horizontally" })
vim.keymap.set("n", "<C-e>", "<C-w>=", { desc = "Window [E]qual Size" })
vim.keymap.set("n", "<C-q>", "<cmd>close<CR>", { desc = "Window [Q]uit" })
-- Resize window
vim.keymap.set("n", "<C-<>", "5<C-w><", { desc = "Resize Window [<]Smaller Vertically" })
vim.keymap.set("n", "<C->>", "5<C-w>>", { desc = "Resize Window [>]Bigger Vertically" })
vim.keymap.set("n", "<C-,>", "5<C-w>-", { desc = "Resize Window [<]Smaller Horizontally" })
vim.keymap.set("n", "<C-.>", "5<C-w>+", { desc = "Resize Window [<]Bigger Horizontally" })
-- Move (rotate) window on row
vim.keymap.set("n", "<C-r>", "<C-w><C-r>", { desc = "Window [R]otate" })
-- Move split to main position
vim.keymap.set("n", "<C-H>", "<C-w>H", { desc = "Move Window [h]Left" })
vim.keymap.set("n", "<C-K>", "<C-w>K", { desc = "Move Window [k]Up" })
vim.keymap.set("n", "<C-J>", "<C-w>J", { desc = "Move Window [j]Down" })
vim.keymap.set("n", "<C-L>", "<C-w>L", { desc = "Move Window [l]right" })

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

require("utils.setVar").Set_user_var("IS_NVIM", true)

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
  vim.keymap.set("n", "<leader>" .. pair[1], "diwi" .. pair[1] .. "<ESC>pa" .. pair[2], { desc = "Surround with " .. pair[1] })
  vim.keymap.set("v", "<leader>" .. pair[1], function()
    if vim.fn.mode() == "v" then
      return "c" .. pair[1] .. pair[2] .. "<ESC>hp" .. "<ESC>"
    elseif vim.fn.mode() == "V" then
      return "<ESC>I" .. pair[1] .. "<ESC>A" .. pair[2] .. "<ESC>"
    end
  end, { desc = "Surround with " .. pair[1], expr = true })
end

-- notetaking
local notes_cache = {}
local function open_notes()
  if not notes_cache.buf then
    local notes_directory = vim.env.HOME .. "/notes"
    if vim.fn.isdirectory(notes_directory) == 0 then
      os.execute("mkdir " .. notes_directory)
    end
    local projects_notes_directory = vim.env.HOME .. "/notes/projects"
    if vim.fn.isdirectory(projects_notes_directory) == 0 then
      os.execute("mkdir " .. projects_notes_directory)
    end
    local project_dir = vim.fn.system("git rev-parse --show-toplevel")
    if project_dir:match("fatal:") then
      project_dir = vim.fn.getcwd()
    end
    local project_file_name = project_dir:gsub("%s+", ""):gsub(vim.env.HOME, ""):gsub("/", "__") .. ".md"
    local note_file_path = vim.fs.normalize(projects_notes_directory .. "/" .. project_file_name)
    if vim.tbl_isempty(vim.fs.find(project_file_name, { type = "file", path = projects_notes_directory })) then
      os.execute("touch " .. note_file_path)
    end
    local note_buf = vim.api.nvim_create_buf(true, false)
    local note_win = vim.api.nvim_open_win(note_buf, true, { split = "right" })
    vim.cmd("edit " .. note_file_path)
    notes_cache = { buf = note_buf, win = note_win, is_hidden = false }
  elseif notes_cache.is_hidden then
    local note_win = vim.api.nvim_open_win(notes_cache.buf, true, { split = "right" })
    notes_cache.win = note_win
    notes_cache.is_hidden = false
  else
    vim.cmd("w")
    vim.api.nvim_win_close(notes_cache.win, true)
    notes_cache.is_hidden = true
  end
end
vim.keymap.set("n", "<leader>tn", open_notes, { desc = "[T]oggle [N]otes" })
