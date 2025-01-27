local oss = require('utils.os')

return {
  'mfussenegger/nvim-dap',
  dependencies = {
    -- Fancy UI for the debugger
    {
      'rcarriga/nvim-dap-ui',
      dependencies = 'nvim-neotest/nvim-nio',
      -- stylua: ignore
      keys = {
        { "<leader>du", function() require("dapui").toggle() end, desc = "[D]ebut: Toggle [U]I", },
        { "<leader>de", function() require("dapui").eval() require("dapui").eval() end, desc = "[D]ebug: [E]valuate Expression", },
      },
      config = function()
        local dap = require('dap')
        local dapui = require('dapui')
        dapui.setup()
        -- somehow the ui doesn't close the first time
        dap.listeners.after.event_initialized['dapui_config'] = function()
          dapui.open({})
        end
        dap.listeners.before.event_terminated['dapui_config'] = function()
          dapui.close({})
          dapui.close({})
        end
        dap.listeners.before.event_exited['dapui_config'] = function()
          dapui.close({})
          dapui.close({})
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
    { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "[D]ebug: Toggle [B]reakpoint",},
    { "<leader>dB", "<cmd>FzfLua dap_breakpoints<cr>", desc = "[D]ebug: List [B]reakpoints",},
    { "<leader>dC", function() require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: ")) end, desc = "[D]ebug: Breakpoint [C]ondition",},
    { "<leader>dc", function() require("dap").continue() end, desc = "[D]ebug: [C]ontinue",},
    { "<leader>dt", function() require("dap").terminate() end, desc = "[D]ebug: [T]erminate",},
    { "<leader>dO", function() require("dap").step_over() end, desc = "[D]ebug: Step [O]ver",},
    { "<leader>di", function() require("dap").step_into() end, desc = "[D]ebug: Step [I]nto",},
    { "<leader>do", function() require("dap").step_out() end, desc = "[D]ebug: Step [O]ut",},
  },
  config = function()
    local sign = vim.fn.sign_define
    sign('DapBreakpoint', { text = '●', texthl = 'DapBreakpoint', linehl = '', numhl = '' })
    sign('DapBreakpointCondition', { text = '●', texthl = 'DapBreakpointCondition', linehl = '', numhl = '' })
    sign('DapLogPoint', { text = '◆', texthl = 'DapLogPoint', linehl = '', numhl = '' })
    local dap = require('dap')
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
  end,
}
