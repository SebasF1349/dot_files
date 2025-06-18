return {
  {
    'mason-org/mason.nvim',
    cmd = { 'Mason', 'MasonInstall', 'MasonInstallAll', 'MasonInstallNew', 'MasonUpdate', 'MasonUninstallNotEnsured' },
    config = function()
      local servers = require('core.lsp').servers
      local ensure_installed = {}
      -- install rust-analyzer with `rustup component add rust-analyzer`
      for _, server in ipairs(servers) do
        if server ~= 'rust-analyzer' then
          table.insert(ensure_installed, server)
        end
      end

      vim.list_extend(ensure_installed, {
        -- web
        'eslint_d',
        'prettier',
        -- markdown
        'markdownlint',
        'markdown-toc',
        -- lua
        'stylua', -- formatter
        -- shell
        'shellcheck', -- linter
        'shfmt', -- formatter
        -- "yamllint", -- linter
        'yamlfmt', -- formatter
        -- json
        'jsonlint', -- linter
        -- text
        'vale', -- linter
        -- sql
        -- "sqlfluff", -- linter
        -- work
        'phpcs',
        'phpstan',
        'php-debug-adapter',
      })

      vim.api.nvim_create_user_command('MasonInstallNew', function()
        if not ensure_installed or #ensure_installed == 0 then
          return
        end
        local mason_registry = require('mason-registry')
        local installed_packages = mason_registry.get_installed_package_names()
        for _, package in ipairs(ensure_installed) do
          if not vim.tbl_contains(installed_packages, package) then
            vim.cmd('MasonInstall ' .. package)
          end
        end
      end, {})

      vim.api.nvim_create_user_command('MasonUninstallNotEnsured', function()
        local mason_registry = require('mason-registry')
        local installed_packages = mason_registry.get_installed_package_names()
        for _, package in ipairs(installed_packages) do
          if not vim.tbl_contains(ensure_installed, package) then
            vim.cmd('MasonUninstall ' .. package)
          end
        end
      end, {})

      require('mason').setup({
        ui = {
          icons = {
            package_installed = '✓',
            package_pending = '➜',
            package_uninstalled = '✗',
          },
          height = 0.8,
        },
      })
    end,
  },
}
