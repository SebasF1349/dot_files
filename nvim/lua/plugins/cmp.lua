return {
  'hrsh7th/nvim-cmp',
  event = { 'InsertEnter' },
  dependencies = {
    {
      'L3MON4D3/LuaSnip',
      build = (function()
        -- Build Step is needed for regex support in snippets
        -- This step is not supported in many windows environments
        -- Remove the below condition to re-enable on windows
        if vim.fn.has('win32') == 1 or vim.fn.executable('make') == 0 then
          return
        end
        return 'make install_jsregexp'
      end)(),
      dependencies = {
        {
          'rafamadriz/friendly-snippets',
          config = function()
            require('luasnip.loaders.from_vscode').lazy_load()
          end,
        },
      },
    },
    'saadparwaiz1/cmp_luasnip',
    'hrsh7th/cmp-nvim-lsp',
    'hrsh7th/cmp-nvim-lsp-signature-help',
    'hrsh7th/cmp-buffer',
    'hrsh7th/cmp-path',
    -- 'hrsh7th/cmp-cmdline',
  },
  config = function()
    local cmp = require('cmp')
    local luasnip = require('luasnip')

    -- allows jump back from last position, although is deprecated (!)
    -- TODO: find out why is deprecated
    luasnip.setup({
      history = true,
    })

    cmp.setup({
      snippet = {
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end,
      },
      completion = { completeopt = 'menu,menuone' },
      window = {
        completion = {
          border = 'rounded',
          scrollbar = false,
          winhighlight = 'Normal:Pmenu,FloatBorder:FloatBorder,CursorLine:Visual,Search:None',
        },
        documentation = {
          border = 'rounded',
          scrollbar = false,
          max_height = math.floor(vim.o.lines * 0.5),
          max_width = math.floor(vim.o.columns * 0.4),
          winhighlight = 'Normal:NormalFloat,FloatBorder:FloatBorder,CursorLine:Visual,Search:None',
        },
      },
      view = {
        entries = {
          follow_cursor = true,
          selection_order = 'near_cursor',
        },
      },
      formatting = {
        expandable_indicator = false,
        fields = { 'abbr', 'kind', 'menu' },
        format = function(entry, item)
          item.menu = ({
            luasnip = '[Snip]',
            nvim_lsp = '[LSP]',
            buffer = '[Buf]',
            path = '[Path]',
            cmdline = '[Cmd]',
          })[entry.source.name] or entry.source.name
          return item
        end,
      },
      mapping = cmp.mapping.preset.insert({
        ['<C-p>'] = cmp.mapping.select_prev_item(),
        ['<C-n>'] = cmp.mapping.select_next_item(),
        ['<C-b>'] = cmp.mapping.scroll_docs(-4),
        ['<C-f>'] = cmp.mapping.scroll_docs(4),
        ['<C-Space>'] = cmp.mapping.complete(),
        ['<C-e>'] = cmp.mapping.abort(),
        ['<C-y>'] = cmp.mapping.confirm({
          behavior = cmp.ConfirmBehavior.Replace,
          select = true,
        }),
        ['<C-l>'] = cmp.mapping(function(fallback)
          if luasnip.expand_or_locally_jumpable() then
            luasnip.expand_or_jump()
          else
            fallback()
          end
        end, { 'i', 's' }),
        ['<C-h>'] = cmp.mapping(function(fallback)
          if luasnip.locally_jumpable(-1) then
            luasnip.jump(-1)
          else
            fallback()
          end
        end, { 'i', 's' }),
      }),
      sources = {
        { name = 'nvim_lsp_signature_help' },
        { name = 'nvim_lsp' },
        { name = 'luasnip' },
        { name = 'path' },
        { name = 'buffer', keyword_length = 2 },
      },
    })

    -- cmp.setup.cmdline({ '/', '?' }, {
    --   mapping = cmp.mapping.preset.cmdline(),
    --   sources = {
    --     { name = 'buffer' },
    --   },
    -- })

    -- cmp.setup.cmdline(':', {
    --   mapping = cmp.mapping.preset.cmdline(),
    --   sources = cmp.config.sources({
    --     --   { name = 'path' },
    --     -- }, {
    --     {
    --       name = 'cmdline',
    --       option = {
    --         ignore_cmds = { 'Man', '!' },
    --       },
    --     },
    --   }),
    -- })

    vim.api.nvim_create_autocmd('CmdWinEnter', {
      callback = function()
        require('cmp').close()
      end,
    })

    -- Inside a snippet, use backspace to remove the placeholder.
    vim.keymap.set('s', '<BS>', '<C-O>s')
  end,
}
