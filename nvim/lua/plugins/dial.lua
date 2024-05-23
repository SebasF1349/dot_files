---@type table<string, string>>
local dials_by_ft = {}

---@param increment boolean
---@param g? boolean
local function dial(increment, g)
  local mode = vim.fn.mode(true)
  -- Use visual commands for VISUAL 'v', VISUAL LINE 'V' and VISUAL BLOCK '\22'
  local is_visual = mode == "v" or mode == "V" or mode == "\22"
  local func = (increment and "inc" or "dec") .. (g and "_g" or "_") .. (is_visual and "visual" or "normal")
  local group = dials_by_ft[vim.bo.filetype] or "default"
  return require("dial.map")[func](group)
end

return {
  "monaqa/dial.nvim",
  -- stylua: ignore
  keys = {
    { "<C-a>", function() return dial(true) end, expr = true, desc = "Increment", mode = {"n", "v"} },
    { "<C-x>", function() return dial(false) end, expr = true, desc = "Decrement", mode = {"n", "v"} },
    { "g<C-a>", function() return dial(true, true) end, expr = true, desc = "Increment", mode = {"n", "v"} },
    { "g<C-x>", function() return dial(false, true) end, expr = true, desc = "Decrement", mode = {"n", "v"} },
  },
  config = function()
    local augend = require("dial.augend")

    local logical_alias = augend.constant.new({
      elements = { "&&", "||" },
      word = false,
      cyclic = true,
    })

    local order = augend.constant.new({
      elements = { ">", "<", "=", "!" },
      word = false,
      cyclic = true,
    })

    local ordinal_numbers = augend.constant.new({
      elements = {
        "first",
        "second",
        "third",
        "fourth",
        "fifth",
        "sixth",
        "seventh",
        "eighth",
        "ninth",
        "tenth",
      },
      word = false,
      cyclic = true,
    })

    local weekdays = augend.constant.new({
      elements = {
        "Monday",
        "Tuesday",
        "Wednesday",
        "Thursday",
        "Friday",
        "Saturday",
        "Sunday",
      },
      word = true,
      cyclic = true,
    })

    local months = augend.constant.new({
      elements = {
        "January",
        "February",
        "March",
        "April",
        "May",
        "June",
        "July",
        "August",
        "September",
        "October",
        "November",
        "December",
      },
      word = true,
      cyclic = true,
    })

    dials_by_ft = {
      css = "css",
      javascript = "typescript",
      javascriptreact = "typescript",
      json = "json",
      lua = "lua",
      markdown = "markdown",
      python = "python",
      sass = "css",
      scss = "css",
      typescript = "typescript",
      typescriptreact = "typescript",
      svelte = "typescript",
    }

    local groups = {
      default = {
        augend.integer.alias.decimal,
        augend.constant.alias.bool,
        augend.paren.alias.quote,
        logical_alias,
        ordinal_numbers,
        weekdays,
        months,
        order,
      },
      css = {
        augend.integer.alias.decimal,
        augend.hexcolor.new({ case = "lower" }),
        augend.hexcolor.new({ case = "upper" }),
      },
      markdown = {
        augend.misc.alias.markdown_header,
        augend.date.alias["%Y/%m/%d"],
        augend.date.alias["%d/%m/%y"],
        augend.date.alias["%Y-%m-%d"],
        ordinal_numbers,
        weekdays,
        months,
        order,
      },
      json = {
        augend.integer.alias.decimal,
        augend.semver.alias.semver,
      },
      typescript = {
        augend.integer.alias.decimal,
        augend.constant.alias.bool,
        augend.constant.new({ elements = { "let", "const" } }),
        augend.paren.alias.quote,
        logical_alias,
        ordinal_numbers,
        weekdays,
        months,
        order,
      },
      lua = {
        augend.integer.alias.decimal,
        augend.constant.alias.bool,
        augend.constant.new({
          elements = { "and", "or" },
          word = true,
          cyclic = true,
        }),
        augend.paren.alias.quote,
        ordinal_numbers,
        weekdays,
        months,
        order,
      },
      python = {
        augend.integer.alias.decimal,
        augend.constant.new({
          elements = { "True", "False" },
          word = true,
          cyclic = true,
        }),
        augend.paren.alias.quote,
        logical_alias,
        ordinal_numbers,
        weekdays,
        months,
        order,
      },
    }

    require("dial.config").augends:register_group(groups)
  end,
}
