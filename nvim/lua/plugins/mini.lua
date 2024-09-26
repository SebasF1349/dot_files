return {
  { 'nvim-treesitter/nvim-treesitter-textobjects' },
  {
    'echasnovski/mini.ai',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      local ai = require('mini.ai')
      local custom_textobjects = {
        o = ai.gen_spec.treesitter({
          a = { '@block.outer', '@conditional.outer', '@loop.outer' },
          i = { '@block.inner', '@conditional.inner', '@loop.inner' },
        }, {}),
        f = ai.gen_spec.treesitter({ a = '@function.outer', i = '@function.inner' }, {}),
        c = ai.gen_spec.treesitter({ a = '@class.outer', i = '@class.inner' }, {}),
        ['/'] = ai.gen_spec.treesitter({ a = '@comment.outer', i = '@comment.outer' }, {}),
        t = { '<([%p%w]-)%f[^<%w][^<>]->.-</%1>', '^<.->().*()</[^/]->$' },
        e = { -- subword (for camelCase or snake_case)
          {
            '%u[%l%d]+%f[^%l%d]',
            '%f[%S][%l%d]+%f[^%l%d]',
            '%f[%P][%l%d]+%f[^%l%d]',
            '^[%l%d]+%f[^%l%d]',
          },
          '^().*()$',
        },
        u = ai.gen_spec.function_call(), -- u for "Usage"
        U = ai.gen_spec.function_call({ name_pattern = '[%w_]' }), -- without dot in function name
      }
      ai.setup({
        n_lines = 500,
        custom_textobjects = custom_textobjects,
      })

      local ts_repeat_move = require('nvim-treesitter.textobjects.repeatable_move')

      for textobj_id, _ in pairs(custom_textobjects) do
        for _, mode in ipairs({ 'n', 'x', 'o' }) do
          for side, key in pairs({ left = textobj_id, right = textobj_id:upper() }) do
            local next_text_object, prev_text_object = ts_repeat_move.make_repeatable_move_pair(function()
              ---@diagnostic disable-next-line: undefined-global
              MiniAi.move_cursor(side, 'a', textobj_id, { search_method = 'next' })
            end, function()
              ---@diagnostic disable-next-line: undefined-global
              MiniAi.move_cursor(side, 'a', textobj_id, { search_method = 'prev' })
            end)
            -- stylua: ignore
            vim.keymap.set(mode, ']' .. key, next_text_object, { desc = 'Move to Next ' .. side .. ' [' .. textobj_id .. '] Text Object' })
            -- stylua: ignore
            vim.keymap.set(mode, '[' .. key, prev_text_object, { desc = 'Move to Previous ' .. side .. ' [' .. textobj_id .. '] Text Object' })
          end
        end
      end
    end,
  },
  {
    'echasnovski/mini.splitjoin',
    keys = { '<leader>j' },
    opts = { mappings = { toggle = '<leader>j', split = '', join = '' } },
  },
}
