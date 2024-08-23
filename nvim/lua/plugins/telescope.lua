return {
  'nvim-telescope/telescope.nvim',
  keys = { '<leader>f', '<leader>/' },
  dependencies = {
    'nvim-lua/plenary.nvim',
    {
      'nvim-telescope/telescope-fzf-native.nvim',
      build = 'make',
      cond = function()
        return vim.fn.executable('make') == 1
      end,
    },
    -- 'nvim-telescope/telescope-ui-select.nvim',
  },
  config = function()
    local telescope = require('telescope')
    local actions = require('telescope.actions')
    local actions_state = require('telescope.actions.state')

    telescope.setup({
      defaults = {
        mappings = {
          i = {
            ['<leader>q'] = function(bufnr)
              local picker = actions_state.get_current_picker(bufnr)
              if #picker:get_multi_selection() > 0 then
                actions.send_selected_to_qflist(bufnr)
                actions.open_qflist(bufnr)
              else
                actions.send_to_qflist(bufnr)
                actions.open_qflist(bufnr)
              end
            end,
          },
        },
        prompt_prefix = ' ',
        selection_caret = ' ',
        border = false,
        -- borderchars = { '', '', '', '', '', '', '', '' },
        layout_strategy = 'bottom_pane',
        layout_config = {
          prompt_position = 'bottom',
          height = 0.25,
        },
        -- dynamic_preview_title = true,
        path_display = { 'filename_first' },
        file_ignore_patterns = {
          '%.jpg',
          '%.jpeg',
          '%.png',
          '%.otf',
          '%.ttf',
          '%.DS_Store',
          '%.git/',
          '%.mypy_cache/',
          'dist/',
          'node_modules/',
          'site-packages/',
          '__pycache__/',
          'migrations/',
          'package-lock.json',
          'yarn.lock',
          'pnpm-lock.yaml',
        },
        -- extensions = {
        --   ['ui-select'] = {
        --     require('telescope.themes').get_dropdown({}),
        --   },
        -- },
      },
    })

    -- Enable telescope extensions, if installed
    telescope.load_extension('fzf')
    -- telescope.load_extension('ui-select')

    local builtin = require('telescope.builtin')

    -- Browsing
    local is_git = require('utils.is-git')()
    vim.keymap.set('n', '<leader>ff', function()
      if is_git then
        builtin.git_files({ use_git_root = false, show_untracked = true })
      else
        builtin.find_files({ follow = true, hidden = true })
      end
    end, { desc = '[F]ind [F]iles' })

    -- Searching
    vim.keymap.set('n', '<leader>fg', function()
      builtin.live_grep({ disable_coordinates = true })
    end, { desc = '[F]ind by [G]rep' })
    vim.keymap.set('n', '<leader>/', function()
      builtin.live_grep({
        disable_coordinates = true,
        search_dirs = { vim.api.nvim_buf_get_name(0) },
        prompt_title = 'Live Grep in Current Buffer',
      })
    end, { desc = 'Find [/] in Current Buffer' })

    -- Miscelaneous
    vim.keymap.set('n', '<leader>fn', function()
      builtin.grep_string({
        disable_coordinates = true,
        search = '(note|todo|fix):',
        use_regex = true,
      })
    end, { desc = '[F]ind [N]otes' })
    vim.keymap.set('n', '<leader>fb', builtin.git_branches, { desc = '[F]ind Git [B]ranch' })
    vim.keymap.set('n', '<leader>fs', builtin.git_status, { desc = '[F]ind Git [S]tatus' })
    vim.keymap.set('n', '<leader>fr', builtin.resume, { desc = '[F]ind [R]esume' })
    vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = '[F]ind [H]elp' })
  end,
}
