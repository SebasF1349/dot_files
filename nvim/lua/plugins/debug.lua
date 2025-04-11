local oss = require('utils.os')

return {
  'mfussenegger/nvim-dap',
  dependencies = {
    -- Fancy UI for the debugger
    {
      'igorlfs/nvim-dap-view',
      config = function()
        local dap = require('dap')
        local dapview = require('dap-view')
        dap.listeners.before.attach['dap-view-config'] = function()
          dapview.open()
        end
        dap.listeners.before.launch['dap-view-config'] = function()
          dapview.open()
        end
        dap.listeners.before.event_terminated['dap-view-config'] = function()
          dapview.close()
        end
        dap.listeners.before.event_exited['dap-view-config'] = function()
          dapview.close()
        end
      end,
    },
    -- Virtual text.
    {
      'theHamsta/nvim-dap-virtual-text',
      opts = { virt_text_pos = 'eol' },
    },

    -- JS/TS debugging.
    {
      'mxsdev/nvim-dap-vscode-js',
      opts = {
        debugger_path = vim.fn.stdpath('data') .. '/lazy/vscode-js-debug',
        adapters = { 'pwa-node', 'pwa-chrome', 'pwa-msedge', 'node-terminal', 'pwa-extensionHost' },
      },
    },
    {
      'microsoft/vscode-js-debug',
      build = function()
        if not oss.is_win then
          return 'npm clean-install --legacy-peer-deps && npx gulp vsDebugServerBundle && move dist out'
        else
          return 'npm clean-install --legacy-peer-deps && npx gulp vsDebugServerBundle && mv dist out'
        end
      end,
    },
  },

  -- stylua: ignore
  keys = {
    { '<leader>db', function() require('dap').toggle_breakpoint() end, desc = '[D]ebug: Toggle [B]reakpoint',},
    { '<leader>dB', function() require('dap').set_breakpoint(vim.fn.input('Breakpoint condition: ')) end, desc = '[D]ebug: [B]reakpoint Condition',},
    { '<leader>dc', function() require('dap').continue() end, desc = '[D]ebug: [C]ontinue',},
  },
  config = function()
    local sign = vim.fn.sign_define
    sign('DapBreakpoint', { text = '●', texthl = 'DapBreakpoint', linehl = '', numhl = '' })
    sign('DapBreakpointCondition', { text = '●', texthl = 'DapBreakpointCondition', linehl = '', numhl = '' })
    sign('DapLogPoint', { text = '◆', texthl = 'DapLogPoint', linehl = '', numhl = '' })
    sign('DapStopped', { text = '→', texthl = 'DapStopped', linehl = '', numhl = '' })
    sign('DapBreakpointRejected', { text = '✗', texthl = 'DapBreakpointRejected', linehl = '', numhl = '' })
    local dap = require('dap')
    local widgets = require('dap.ui.widgets')

    vim.keymap.set('n', '<leader>dC', dap.clear_breakpoints, { desc = '[D]ebug: [C]lear Breakpoint' })
    vim.keymap.set('n', '<leader>dt', dap.terminate, { desc = '[D]ebug: [T]erminate' })
    vim.keymap.set('n', '<leader>dr', dap.restart, { desc = '[D]ebug: [R]estart' })
    vim.keymap.set('n', '<leader>dO', dap.step_over, { desc = '[D]ebug: Step [O]ver' })
    vim.keymap.set('n', '<leader>di', dap.step_into, { desc = '[D]ebug: Step [I]nto' })
    vim.keymap.set('n', '<leader>do', dap.step_out, { desc = '[D]ebug: Step [O]ut' })
    vim.keymap.set('n', '<leader>dk', function()
      widgets.hover(nil, { border = 'solid' })
    end, { desc = '[D]ebug: [K]Hover' })

    -- C configurations.
    dap.adapters.codelldb = {
      type = 'server',
      host = 'localhost',
      port = '${port}',
      executable = {
        command = 'codelldb',
        args = { '--port', '${port}' },
      },
    }

    -- NOTE: needs to install Xdebug following these instructions: https://github.com/xdebug/vscode-php-debug?tab=readme-ov-file#installation
    dap.adapters.php = {
      type = 'executable',
      command = 'node',
      args = { vim.fn.stdpath('data') .. '/mason/packages/php-debug-adapter/extension/out/phpDebug.js' },
    }
    dap.configurations.php = {
      {
        type = 'php',
        request = 'launch',
        name = 'Listen for Xdebug',
        port = 9003,
      },
    }

    -- Close terminal on exit (maybe it close on error too?)
    dap.listeners.after.event_initialized['custom.terminal-autoclose'] = function(session)
      session.on_close['custom.terminal-autoclose'] = function()
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          local bufname = vim.api.nvim_buf_get_name(buf)
          if bufname:find('%[dap%-terminal%]') then
            vim.api.nvim_buf_delete(buf, { force = true })
          end
        end
      end
    end
  end,
}
