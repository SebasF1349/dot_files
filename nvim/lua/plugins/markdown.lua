return {
  {
    "jakewvincent/mkdnflow.nvim",
    ft = { "markdown" },
    config = function()
      require("mkdnflow").setup({
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
          tables = false,
          yaml = false,
          cmp = false,
        },
        filetypes = { md = true, rmd = true, markdown = true },
        create_dirs = true,
        perspective = {
          priority = "root",
          fallback = "current",
          root_tell = "index.md",
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
          style = "markdown",
          name_is_source = false,
          conceal = false,
          context = 0,
          implicit_extension = nil,
          transform_implicit = false,
          transform_explicit = function(text)
            text = text:gsub(" ", "-")
            text = text:lower()
            if text:find("date") then
              text = text:gsub("date-", os.date("%Y-%m-%d_"))
            end
            return text
          end,
        },
        -- Check how to use
        new_file_template = {
          use_template = false,
          placeholders = {
            before = {
              title = "link_title",
              date = "os_date",
            },
            after = {},
          },
          template = "# {{ title }}",
        },
        to_do = {
          symbols = { " ", "-", "X" },
          update_parents = true,
          not_started = " ",
          in_progress = "-",
          complete = "X",
        },
        tables = {
          trim_whitespace = true,
          format_on_move = false,
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
          MkdnEnter = { { "n", "v" }, "<CR>" },
          MkdnTab = false,
          MkdnSTab = false,
          MkdnNextLink = { "n", "<Tab>" },
          MkdnPrevLink = { "n", "<S-Tab>" },
          MkdnNextHeading = { "n", "]]" },
          MkdnPrevHeading = { "n", "[[" },
          MkdnGoBack = { "n", "<BS>" },
          MkdnGoForward = { "n", "<Del>" },
          MkdnCreateLink = false, -- see MkdnEnter
          MkdnCreateLinkFromClipboard = { { "n", "v" }, "<leader>mp" }, -- see MkdnEnter
          MkdnFollowLink = false, -- see MkdnEnter
          MkdnDestroyLink = { "n", "<A-CR>" },
          MkdnTagSpan = { "v", "<A-CR>" },
          MkdnMoveSource = { "n", "<F2>" },
          MkdnYankAnchorLink = { "n", "yaa" },
          MkdnYankFileAnchorLink = { "n", "yfa" },
          MkdnIncreaseHeading = { "n", "+" },
          MkdnDecreaseHeading = { "n", "-" },
          MkdnToggleToDo = { { "n", "v" }, "<leader>ml" },
          MkdnNewListItem = false,
          MkdnNewListItemBelowInsert = { "n", "o" },
          MkdnNewListItemAboveInsert = { "n", "O" },
          MkdnExtendList = false,
          MkdnUpdateNumbering = { "n", "<leader>mn" },
          MkdnTableNextCell = { "i", "<Tab>" },
          MkdnTablePrevCell = { "i", "<S-Tab>" },
          MkdnTableNextRow = false,
          MkdnTablePrevRow = { "i", "<A-CR>" },
          MkdnTableNewRowBelow = { "n", "<leader>mr" },
          MkdnTableNewRowAbove = { "n", "<leader>mR" },
          MkdnTableNewColAfter = { "n", "<leader>mc" },
          MkdnTableNewColBefore = { "n", "<leader>mC" },
          MkdnFoldSection = { "n", "<leader>mf" },
          MkdnUnfoldSection = { "n", "<leader>mF" },
        },
      })
    end,
  },
  {
    -- preferably replace it with mkdnflow when they fix their tables
    "Myzel394/easytables.nvim",
    ft = { "markdown" },
    config = function()
      local easytables = require("easytables")
      easytables.setup({
        table = {
          -- Whether to enable the header by default
          header_enabled_by_default = true,
          window = {
            preview_title = "Table Preview",
            prompt_title = "Cell content",
            -- Either "auto" to automatically size the window, or a string
            -- in the format of "<width>x<height>" (e.g. "20x10")
            size = "auto",
          },
          cell = {
            -- Min width of a cell (excluding padding)
            min_width = 3,
            -- Filler character for empty cells
            filler = " ",
            align = "left",
          },
          -- Characters used to draw the table
          -- Do not worry about multibyte characters, they are handled correctly
          border = {
            top_left = "┌",
            top_right = "┐",
            bottom_left = "└",
            bottom_right = "┘",
            horizontal = "─",
            vertical = "│",
            left_t = "├",
            right_t = "┤",
            top_t = "┬",
            bottom_t = "┴",
            cross = "┼",
            header_left_t = "╞",
            header_right_t = "╡",
            header_bottom_t = "╧",
            header_cross = "╪",
            header_horizontal = "═",
          },
        },
        export = {
          markdown = {
            -- Padding around the cell content, applied BOTH left AND right
            -- E.g: padding = 1, content = "foo" -> " foo "
            padding = 1,
            -- What markdown characters are used for the export, you probably
            -- don't want to change these
            characters = {
              horizontal = "-",
              vertical = "|",
              -- Filler for padding
              filler = " ",
            },
          },
        },
        set_mappings = function(buf)
          vim.api.nvim_buf_set_keymap(buf, "n", "<Left>", "<cmd>JumpLeft<CR>", {})
          vim.api.nvim_buf_set_keymap(buf, "n", "<S-Left>", "<cmd>SwapWithLeftCell<CR>", {})

          vim.api.nvim_buf_set_keymap(buf, "n", "<Right>", "<cmd>JumpRight<CR>", {})
          vim.api.nvim_buf_set_keymap(buf, "n", "<S-Right>", "<cmd>SwapWithRightCell<CR>", {})

          vim.api.nvim_buf_set_keymap(buf, "n", "<Up>", "<cmd>JumpUp<CR>", {})
          vim.api.nvim_buf_set_keymap(buf, "n", "<S-Up>", "<cmd>SwapWithUpperCell<CR>", {})

          vim.api.nvim_buf_set_keymap(buf, "n", "<Down>", "<cmd>JumpDown<CR>", {})
          vim.api.nvim_buf_set_keymap(buf, "n", "<S-Down>", "<cmd>SwapWithLowerCell<CR>", {})

          vim.api.nvim_buf_set_keymap(buf, "n", "<Tab>", "<cmd>JumpToNextCell<CR>", {})
          vim.api.nvim_buf_set_keymap(buf, "n", "<S-Tab>", "<cmd>JumpToPreviousCell<CR>", {})

          vim.api.nvim_buf_set_keymap(buf, "n", "<C-Left>", "<cmd>SwapWithLeftColumn<CR>", {})
          vim.api.nvim_buf_set_keymap(buf, "n", "<C-Right>", "<cmd>SwapWithRightColumn<CR>", {})
          vim.api.nvim_buf_set_keymap(buf, "n", "<C-Up>", "<cmd>SwapWithUpperRow<CR>", {})
          vim.api.nvim_buf_set_keymap(buf, "n", "<C-Down>", "<cmd>SwapWithLowerRow<CR>", {})
        end,
      })
      vim.keymap.set("n", "<leader>mi", "<cmd>EasyTablesImportThisTable<CR>", { desc = "[M]arkdown Table [I]mport" })
      vim.keymap.set("n", "<leader>me", "<cmd>ExportTable<CR>", { desc = "[M]arkdown Table [E]xport" })
    end,
  },
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    build = function()
      vim.fn["mkdp#util#install"]()
    end,
    config = function()
      vim.keymap.set("n", "<leader>mt", "<cmd>MarkdownPreviewToggle<CR>", { desc = "[M]arkdown Preview [T]oggle" })
    end,
  },
  {
    "HakonHarnes/img-clip.nvim",
    opts = {
      default = {
        dir_path = "img",
      },
      markdown = {
        download_images = true,
      },
    },
    keys = {
      { "<leader>p", "<cmd>PasteImage<cr>", desc = "Paste image from system clipboard" },
    },
  },
}
