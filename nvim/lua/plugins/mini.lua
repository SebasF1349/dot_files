return {
  -- Collection of various small independent plugins/modules
  "echasnovski/mini.nvim",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    -- Better Around/Inside textobjects
    --
    -- Examples:
    --  - va)  - [V]isually select [A]round [)]parenthen
    --  - yinq - [Y]ank [I]nside [N]ext [']quote
    --  - ci'  - [C]hange [I]nside [']quote
    local ai = require("mini.ai")
    ai.setup({
      n_lines = 500,
      custom_textobjects = {
        o = ai.gen_spec.treesitter({
          a = { "@block.outer", "@conditional.outer", "@loop.outer" },
          i = { "@block.inner", "@conditional.inner", "@loop.inner" },
        }, {}),
        f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }, {}),
        c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }, {}),
        t = { "<([%p%w]-)%f[^<%w][^<>]->.-</%1>", "^<.->().*()</[^/]->$" },
      },
    })

    -- Add/delete/replace surroundings (brackets, quotes, etc.)
    --
    -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
    -- - sd'   - [S]urround [D]elete [']quotes
    -- - sr)'  - [S]urround [R]eplace [)] [']
    -- local surround = require("mini.surround")
    -- surround.setup({
    --   mappings = {
    --     add = "<leader>aa", -- Add surrounding in Normal and Visual modes
    --     delete = "<leader>ad", -- Delete surrounding
    --     find = "<leader>af", -- Find surrounding (to the right)
    --     find_left = "<leader>aF", -- Find surrounding (to the left)
    --     highlight = "<leader>ah", -- Highlight surrounding
    --     replace = "<leader>ar", -- Replace surrounding
    --     update_n_lines = "<leader>an", -- Update `n_lines`
    --   },
    -- })

    -- ... and there is more!
    --  Check out: https://github.com/echasnovski/mini.nvim
  end,
}
