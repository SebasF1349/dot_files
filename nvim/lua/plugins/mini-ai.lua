return {
  'echasnovski/mini.ai',
  event = 'VeryLazy',
  config = function()
    local ai = require('mini.ai')
    ai.setup({
      n_lines = 500,
      mappings = {
        around_next = '',
        inside_next = '',
        goto_left = '[g',
        goto_right = ']g',
      },
      custom_textobjects = {
        t = { '<([%p%w]-)%f[^<%w][^<>]->.-</%1>', '^<.->().*()</[^/]->$' }, -- tags
        d = { '%f[%d%._][%d%._]+' }, -- digits with _ separator
        s = { -- subword (breaks sentence, but I never use it) https://github.com/echasnovski/mini.nvim/discussions/1434
          {
            -- Matches a single uppercase letter followed by 1+ lowercase letters.
            -- This covers:
            -- - PascalCaseWords (or the latter part of camelCaseWords)
            '%u[%l%d]+%f[^%l%d]', -- An uppercase letter, 1+ lowercase letters, to end of lowercase letters

            -- Matches lowercase letters up until not lowercase letter.
            -- This covers:
            -- - start of camelCaseWords (just the `camel`)
            -- - snake_case_words in lowercase
            -- - regular lowercase words
            '%f[^%s%p][%l%d]+%f[^%l%d]', -- after whitespace/punctuation, 1+ lowercase letters, to end of lowercase letters
            '^[%l%d]+%f[^%l%d]', -- after beginning of line, 1+ lowercase letters, to end of lowercase letters

            -- Matches uppercase or lowercase letters up until not letters.
            -- This covers:
            -- - SNAKE_CASE_WORDS in uppercase
            -- - Snake_Case_Words in titlecase
            -- - regular UPPERCASE words
            -- (it must be both uppercase and lowercase otherwise it will
            -- match just the first letter of PascalCaseWords)
            '%f[^%s%p][%a%d]+%f[^%a%d]', -- after whitespace/punctuation, 1+ letters, to end of letters
            '^[%a%d]+%f[^%a%d]', -- after beginning of line, 1+ letters, to end of letters
          },
          '^().*()$',
        },
        u = ai.gen_spec.function_call(), -- u for "Usage"
        U = ai.gen_spec.function_call({ name_pattern = '[%w_]' }), -- without dot in function name
        g = function() -- whole buffer
          local from = { line = 1, col = 1 }
          local to = {
            line = vim.fn.line('$'),
            col = math.max(vim.fn.getline('$'):len(), 1),
          }
          return { from = from, to = to, vis_mode = 'V' }
        end,
        ['-'] = { {
          '\n()%s*().-()\n()',
          '^()%s*().-()\n()',
        } },
        o = { -- chunk (as in from vim-textobj-chunk) ??
          '\n.-%b{}.-\n',
          '\n().-()%{\n.*\n.*%}().-\n()',
        },
        e = function()
          local diagnostics = vim.diagnostic.get(0)
          diagnostics = vim.tbl_map(function(diagnostic)
            local from_line = diagnostic.lnum + 1
            local from_col = diagnostic.col + 1
            local to_line = diagnostic.end_lnum + 1
            local to_col = diagnostic.end_col + 1
            return {
              from = { line = from_line, col = from_col },
              to = { line = to_line, col = to_col },
            }
          end, diagnostics)
          return diagnostics
        end,
      },
    })
  end,
}
