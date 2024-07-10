return { -- Collection of various small independent plugins/modules
  'echasnovski/mini.nvim',
  event = { 'BufReadPre', 'BufNewFile' },
  dependencies = { 'nvim-treesitter/nvim-treesitter-textobjects' },
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

    ---@param lhs string
    ---@param side "left"|"right"
    ---@param textobj_id string
    local map_previous = function(lhs, side, textobj_id)
      for _, mode in ipairs({ 'n', 'x', 'o' }) do
        vim.keymap.set(mode, lhs, function()
          ---@diagnostic disable-next-line: undefined-global
          MiniAi.move_cursor(side, 'a', textobj_id, { search_method = 'prev' })
        end, { desc = 'Move to Previous ' .. side .. ' [' .. textobj_id .. '] Text Object' })
      end
    end

    ---@param lhs string
    ---@param side "left"|"right"
    ---@param textobj_id string
    local map_next = function(lhs, side, textobj_id)
      for _, mode in ipairs({ 'n', 'x', 'o' }) do
        vim.keymap.set(mode, lhs, function()
          ---@diagnostic disable-next-line: undefined-global
          MiniAi.move_cursor(side, 'a', textobj_id, { search_method = 'next' })
        end, { desc = 'Move to Next ' .. side .. ' [' .. textobj_id .. '] Text Object' })
      end
    end

    for key, _ in pairs(custom_textobjects) do
      map_previous('[' .. key, 'left', key)
      map_previous('[' .. key:upper(), 'right', key)
      map_next(']' .. key, 'left', key)
      map_next(']' .. key:upper(), 'right', key)
    end

    -- Add/delete/replace surroundings (brackets, quotes, etc.)
    --
    -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
    -- - sd'   - [S]urround [D]elete [']quotes
    -- - sr)'  - [S]urround [R]eplace [)] [']
    -- require("mini.surround").setup()
    -- NOTE: mini-surround for better surroundings?

    require('mini.splitjoin').setup({ mappings = { toggle = '<leader>j', split = '', join = '' } })

    local test_icon = ''
    local js_table = { glyph = test_icon, hl = 'MiniIconsYellow' }
    local jsx_table = { glyph = test_icon, hl = 'MiniIconsAzure' }
    local ts_table = { glyph = test_icon, hl = 'MiniIconsAzure' }
    local tsx_table = { glyph = test_icon, hl = 'MiniIconsBlue' }
    local eslint = { glyph = '󰱺', hl = 'MiniIconsYellow' }
    local prettier = { glyph = '', hl = 'MiniIconsPurple' } -- change to  when I can see it
    require('mini.icons').setup({
      file = {
        ['.eslintrc.js'] = eslint,
        ['.eslintignore'] = eslint,
        ['eslint.config.js'] = eslint,
        ['.prettierrc'] = prettier,
        ['.prettierignore'] = prettier,
        ['.node-version'] = { glyph = '', hl = 'MiniIconsGreen' },
      },
      extension = {
        ['test.js'] = js_table,
        ['test.jsx'] = jsx_table,
        ['test.ts'] = ts_table,
        ['test.tsx'] = tsx_table,
        ['spec.js'] = js_table,
        ['spec.jsx'] = jsx_table,
        ['spec.ts'] = ts_table,
        ['spec.tsx'] = tsx_table,
        ['cy.js'] = js_table,
        ['cy.jsx'] = jsx_table,
        ['cy.ts'] = ts_table,
        ['cy.tsx'] = tsx_table,
      },
    })
    require('mini.icons').mock_nvim_web_devicons()
  end,
}
