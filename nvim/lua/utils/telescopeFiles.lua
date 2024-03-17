local M = {}

local function on_complete(picker)
  -- remove this on_complete callback
  picker:clear_completion_callbacks()
  -- if we have exactly one match, select it
  if picker.manager.linked_states.size == 1 then
    require("telescope.actions").select_default(picker.prompt_bufnr)
  end
end

local is_inside_work_tree = {}

local customPickers = require("utils.telescopePickers")

function M.Telescope_git_or_files()
  local cwd = vim.fn.getcwd()
  if is_inside_work_tree[cwd] == nil then
    vim.fn.system("git rev-parse --is-inside-work-tree")
    is_inside_work_tree[cwd] = vim.v.shell_error == 0
  end
  if is_inside_work_tree[cwd] then
    customPickers.prettyFilesPicker({
      picker = "git_files",
      options = {
        use_git_root = false,
        show_untracked = true,
        on_complete = { on_complete },
      },
    })
  else
    customPickers.prettyFilesPicker({
      picker = "find_files",
      options = { on_complete = { on_complete } },
    })
  end
end

return M
