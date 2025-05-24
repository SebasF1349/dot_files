return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'master',
    event = { 'BufReadPost', 'BufNewFile' },
    build = ':TSUpdate',
    init = function(plugin)
      -- PERF: add nvim-treesitter queries to the rtp and it's custom query predicates early
      -- This is needed because a bunch of plugins no longer `require("nvim-treesitter")`, which
      -- no longer trigger the **nvim-treesitter** module to be loaded in time.
      -- Luckily, the only things that those plugins need are the custom queries, which we make available
      -- during startup.
      require('lazy.core.loader').add_to_rtp(plugin)
      require('nvim-treesitter.query_predicates')
    end,
    config = function()
      vim.filetype.add({
        extension = { rasi = 'rasi' },
        pattern = {
          ['.*/hypr/.*%.conf'] = 'hyprlang',
          ['.*/waybar/config'] = 'jsonc',
          ['%.env%.[%w_.-]+'] = 'sh',
        },
      })

      require('nvim-treesitter.configs').setup({
        -- NOTE: maybe replace with a custom function to reduce startup time
        ensure_installed = {
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
          'tsx',
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
        },
        auto_install = true,
        sync_install = false,
        ignore_install = {},
        modules = {},
        highlight = { enable = true },
        -- indent = { enable = true }, -- doesn't work properly
      })

      -- can use ['az'] = { query = '@fold', query_group = 'folds' , silent =true }, but needs an offset for iz
      -- more robust option (do I want the if/else behaviour?) : https://vimways.org/2018/transactions-pending/
      vim.keymap.set('v', 'iz', ':<C-U>silent! normal! [zV]zkoj<CR>', { desc = 'Fold Text-Object', silent = true })
      vim.keymap.set('o', 'iz', '<cmd>normal Viz<CR>', { desc = 'Fold Text-Object', remap = false, silent = true })
      vim.keymap.set('v', 'az', ':<C-U>silent! normal! [zV]z<CR>', { desc = 'Fold Text-Object', silent = true })
      vim.keymap.set('o', 'az', '<cmd>normal Vaz<CR>', { desc = 'Fold Text-Object', remap = false, silent = true })

      vim.api.nvim_set_hl(0, '@lsp.type.comment', {})

      local function enable_foldexpr(bufnr)
        if vim.api.nvim_buf_line_count(bufnr) > 40000 then
          return
        end
        vim.api.nvim_buf_call(bufnr, function()
          vim.wo[0][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
          vim.wo[0][0].foldmethod = 'expr'
          vim.cmd.normal('zx')
        end)
      end

      vim.api.nvim_create_autocmd('FileType', {
        callback = function(args)
          if not pcall(vim.treesitter.start, args.buf) then
            return
          end

          enable_foldexpr(args.buf)
        end,
      })
    end,
  },
}
