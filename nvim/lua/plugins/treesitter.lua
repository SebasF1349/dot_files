return {
  {
    'nvim-treesitter/nvim-treesitter',
    lazy = false,
    branch = 'main',
    build = ':TSUpdate',
    config = function()
      vim.filetype.add({
        extension = { rasi = 'rasi' },
        pattern = {
          ['.*/hypr/.*%.conf'] = 'hyprlang',
          ['.*/waybar/config'] = 'jsonc',
          ['%.env%.[%w_.-]+'] = 'sh',
        },
      })

      local parsers = {
        -- langs
        'c',
        'cpp',
        'go',
        'gomod',
        'gowork',
        'gosum',
        'lua',
        'python',
        'rust',
        -- web
        'javascript',
        'typescript',
        'css',
        'html',
        'svelte',
        -- config
        'json',
        'jsonc',
        'toml',
        'yaml',
        'markdown',
        'markdown_inline',
        -- specific config
        'bash',
        'hyprlang',
        'git_config',
        'gitcommit',
        'gitignore',
        'rasi',
        'readline',
        'powershell',
        'query',
        'vim',
        'vimdoc',
        -- misc
        'diff',
        'comment',
        'regex',
        'sql',
        -- work
        'php',
        'php_only',
        'phpdoc',
        'angular',
      }

      vim.api.nvim_create_autocmd('FileType', {
        pattern = { '*' },
        callback = function(args)
          -- if vim.api.nvim_buf_line_count(args.buf) > 40000 then
          --   return
          -- end
          local lang = vim.treesitter.language.get_lang(args.match)
          if lang and vim.treesitter.language.add(lang) then
            vim.treesitter.start(args.buf)
            vim.api.nvim_buf_call(args.buf, function()
              vim.wo[0][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
              vim.wo[0][0].foldmethod = 'expr'
              vim.cmd.normal('zx')
            end)
            -- vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })

      vim.api.nvim_create_user_command('TSInstallAll', function()
        require('nvim-treesitter').install(parsers)
      end, {})

      vim.api.nvim_create_user_command('TSInstallNew', function()
        local already_installed = require('nvim-treesitter').get_installed()
        local isnt_installed = function(parser)
          return not vim.tbl_contains(already_installed, parser)
        end
        local to_install = vim.tbl_filter(isnt_installed, parsers)
        if #to_install > 0 then
          require('nvim-treesitter').install(to_install)
        end
      end, {})

      -- more robust option (do I want the if/else behaviour?) : https://vimways.org/2018/transactions-pending/
      vim.keymap.set('v', 'iz', ':<C-U>silent! normal! [zV]zkoj<CR>', { desc = 'Fold Text-Object', silent = true })
      vim.keymap.set('o', 'iz', '<cmd>normal Viz<CR>', { desc = 'Fold Text-Object', remap = false, silent = true })
      vim.keymap.set('v', 'az', ':<C-U>silent! normal! [zV]z<CR>', { desc = 'Fold Text-Object', silent = true })
      vim.keymap.set('o', 'az', '<cmd>normal Vaz<CR>', { desc = 'Fold Text-Object', remap = false, silent = true })

      vim.api.nvim_set_hl(0, '@lsp.type.comment', {})
    end,
  },
}
