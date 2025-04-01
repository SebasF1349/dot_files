return {
  'windwp/nvim-ts-autotag',
  ft = { 'html', 'svelte', 'markdown', 'php' },
  config = function()
    require('nvim-ts-autotag').setup({
      opts = {
        enable_close_on_clash = true,
        filetypes = { 'svelte', 'html', 'markdown', 'php' },
      },
    })
  end,
}
