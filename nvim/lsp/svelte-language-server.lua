return {
  cmd = { 'svelteserver', '--stdio' },
  filetypes = { 'svelte' },
  root_markers = { 'package.json', '.git' },
  on_attach = function()
    local clients = vim.lsp.get_clients({
      bufnr = 0,
      name = 'svelte',
    })

    vim.api.nvim_buf_create_user_command(0, 'MigrateToSvelte5', function()
      for _, client in ipairs(clients) do
        client:exec_cmd({
          title = 'Migrate to Svelte 5',
          command = 'migrate_to_svelte_5',
          arguments = { vim.uri_from_bufnr(0) },
        })
      end
    end, { desc = 'Migrate Component to Svelte 5 Syntax' })

    vim.api.nvim_create_autocmd('BufWritePost', {
      group = vim.api.nvim_create_augroup('ts-svelte-sync', { clear = true }),
      pattern = { '*.js', '*.ts' },
      callback = function(ctx)
        -- this bad boy updates imports between svelte and ts/js files
        clients[1]:notify('$/onDidChangeTsOrJsFile', { uri = ctx.match })
      end,
    })
  end,
}
