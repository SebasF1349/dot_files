return {
  {
    'jakewvincent/mkdnflow.nvim',
    ft = { 'markdown' },
    config = function()
      vim.keymap.set(
        'n',
        '<leader>mt',
        'i<!-- toc --><ESC><cmd>w<CR>',
        { desc = 'Add [M]arkdown [T]OC using markdown-toc' }
      )

      require('mkdnflow').setup({
        modules = {
          bib = false,
          buffers = true,
          conceal = false,
          cursor = true,
          folds = true,
          links = true,
          lists = true,
          maps = true,
          paths = true,
          tables = true,
          yaml = false,
          cmp = false,
        },
        filetypes = { md = true, rmd = true, markdown = true },
        create_dirs = true,
        perspective = {
          priority = 'first',
          fallback = 'current',
          root_tell = 'index.md',
          nvim_wd_heel = false,
          update = false,
        },
        wrap = false,
        bib = {
          default_path = nil,
          find_in_root = true,
        },
        silent = false,
        cursor = {
          jump_patterns = nil,
        },
        links = {
          style = 'markdown',
          name_is_source = false,
          conceal = false,
          context = 0,
          implicit_extension = nil,
          transform_implicit = false,
          transform_explicit = function(text)
            text = text:gsub(' ', '-')
            text = text:lower()
            if text:find('date') then
              text = text:gsub('date-', os.date('%Y-%m-%d_'))
            end
            return text
          end,
        },
        -- Check how to use
        new_file_template = {
          use_template = false,
          placeholders = {
            before = {
              title = 'link_title',
              date = 'os_date',
            },
            after = {},
          },
          template = '# {{ title }}',
        },
        to_do = {
          symbols = { ' ', '-', 'X' },
          update_parents = true,
          not_started = ' ',
          in_progress = '-',
          complete = 'X',
        },
        tables = {
          trim_whitespace = true,
          format_on_move = true,
          auto_extend_rows = false,
          auto_extend_cols = false,
          style = {
            cell_padding = 1,
            separator_padding = 1,
            outer_pipes = true,
            mimic_alignment = true,
          },
        },
        yaml = {
          bib = { override = false },
        },
        mappings = {
          MkdnEnter = { { 'n', 'x', 'i' }, '<CR>' },
          MkdnTab = { 'i', '>' },
          MkdnSTab = { 'i', '<' },
          MkdnNextLink = { 'n', '<Tab>' },
          MkdnPrevLink = { 'n', '<S-Tab>' },
          MkdnNextHeading = { 'n', ']]' },
          MkdnPrevHeading = { 'n', '[[' },
          MkdnGoBack = false,
          MkdnGoForward = false,
          MkdnCreateLink = false,
          MkdnCreateLinkFromClipboard = false, -- { { 'n', 'x' }, '<leader>mp' }, -- see MkdnEnter
          MkdnFollowLink = false,
          MkdnDestroyLink = { 'n', '<A-CR>' },
          MkdnTagSpan = { 'x', '<A-CR>' },
          MkdnMoveSource = { 'n', '<F2>' },
          MkdnYankAnchorLink = { 'n', 'yaa' },
          MkdnYankFileAnchorLink = { 'n', 'yfa' },
          MkdnIncreaseHeading = { 'n', '+' },
          MkdnDecreaseHeading = { 'n', '-' },
          MkdnToggleToDo = { { 'n', 'x' }, '<leader>ml' },
          MkdnNewListItem = false,
          MkdnNewListItemBelowInsert = false,
          MkdnNewListItemAboveInsert = false,
          MkdnExtendList = false,
          MkdnUpdateNumbering = { 'n', '<leader>mn' },
          MkdnTableNextCell = { 'i', '<Tab>' },
          MkdnTablePrevCell = { 'i', '<S-Tab>' },
          MkdnTableNextRow = false,
          MkdnTablePrevRow = { 'i', '<A-CR>' },
          MkdnTableNewRowBelow = { 'n', '<leader>mr' },
          MkdnTableNewRowAbove = { 'n', '<leader>mR' },
          MkdnTableNewColAfter = { 'n', '<leader>mc' },
          MkdnTableNewColBefore = { 'n', '<leader>mC' },
          MkdnFoldSection = false,
          MkdnUnfoldSection = false,
        },
      })
    end,
  },
  {
    'iamcco/markdown-preview.nvim',
    cmd = { 'MarkdownPreviewToggle', 'MarkdownPreview', 'MarkdownPreviewStop' },
    ft = { 'markdown' },
    build = function()
      vim.fn['mkdp#util#install']()
    end,
    config = function()
      vim.keymap.set('n', '<leader>mp', '<cmd>MarkdownPreviewToggle<CR>', { desc = '[M]arkdown [P]review Toggle' })
    end,
  },
  {
    'HakonHarnes/img-clip.nvim',
    opts = {
      default = {
        dir_path = 'img',
      },
      markdown = {
        download_images = true,
      },
    },
    keys = {
      { '<leader>p', '<cmd>PasteImage<cr>', desc = 'Paste image from system clipboard' },
    },
  },
}
