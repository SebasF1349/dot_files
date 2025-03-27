local root_files = {
  '.luarc.json',
  '.luarc.jsonc',
  '.luacheckrc',
  '.stylua.toml',
  'stylua.toml',
  'selene.toml',
  'selene.yml',
  '.git',
}

return {
  cmd = { 'lua-language-server' },
  filetypes = { 'lua' },
  root_markers = root_files,
  single_file_support = true,
  log_level = vim.lsp.protocol.MessageType.Warning,
  on_init = function(client)
    local path = client.workspace_folders[1].name
    if vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc') then
      return
    end

    client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
      runtime = { version = 'LuaJIT' },
      -- Make the server aware of Neovim runtime files
      workspace = {
        checkThirdParty = false,
        library = {
          '${3rd}/luv/library',
          vim.env.VIMRUNTIME,
          vim.fn.stdpath('data') .. '/lazy', -- plugins types
        },
      },
    })
  end,
  settings = {
    Lua = {
      format = { enable = false },
      completion = { callSnippet = 'Replace' },
      hint = { enable = true, arrayIndex = 'Disable' },
      telemetry = { enable = false },
    },
  },
}
