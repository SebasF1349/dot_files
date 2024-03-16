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

function Set_user_var(key, value)
  io.write(string.format("\027]1337;SetUserVar=%s=%s\a", key, base64(value)))
end

local function on_complete(picker)
  -- remove this on_complete callback
  picker:clear_completion_callbacks()
  -- if we have exactly one match, select it
  if picker.manager.linked_states.size == 1 then
    require("telescope.actions").select_default(picker.prompt_bufnr)
  end
end

local is_inside_work_tree = {}
function Telescope_git_or_files()
  local cwd = vim.fn.getcwd()
  if is_inside_work_tree[cwd] == nil then
    vim.fn.system("git rev-parse --is-inside-work-tree")
    is_inside_work_tree[cwd] = vim.v.shell_error == 0
  end
  if is_inside_work_tree[cwd] then
    require("telescope.builtin").git_files({
      use_git_root = false,
      show_untracked = true,
      on_complete = { on_complete },
    })
  else
    require("telescope.builtin").find_files({
      on_complete = { on_complete },
    })
  end
end
