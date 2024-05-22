return {
  "mfussenegger/nvim-dap",
  dependencies = {
    -- Fancy UI for the debugger
    {
      "rcarriga/nvim-dap-ui",
      dependencies = "nvim-neotest/nvim-nio",
      keys = {
        {
          "<leader>de",
          function()
            -- Calling this twice to open and jump into the window.
            require("dapui").eval()
            require("dapui").eval()
          end,
          desc = "[D]ebug: [E]valuate Expression",
        },
      },
      opts = {
        icons = { expanded = "▾", collapsed = "▸", current_frame = "*" },
        controls = {
          icons = {
            pause = "⏸",
            play = "▶",
            step_into = "⏎",
            step_over = "⏭",
            step_out = "⏮",
            step_back = "b",
            run_last = "▶▶",
            terminate = "⏹",
            disconnect = "⏏",
          },
        },
        floating = { border = "rounded" },
        layouts = {
          {
            elements = {
              { id = "stacks", size = 0.30 },
              { id = "breakpoints", size = 0.20 },
              { id = "scopes", size = 0.50 },
            },
            position = "right",
            size = 40,
          },
        },
      },
    },

    -- Virtual text.
    {
      "theHamsta/nvim-dap-virtual-text",
      opts = { virt_text_pos = "eol" },
    },

    -- JS/TS debugging.
    {
      "mxsdev/nvim-dap-vscode-js",
      opts = {
        debugger_path = vim.fn.stdpath("data") .. "/lazy/vscode-js-debug",
        adapters = { "pwa-node", "pwa-chrome", "pwa-msedge", "node-terminal", "pwa-extensionHost" },
      },
    },
    {
      "microsoft/vscode-js-debug",
      build = "npm i && npm run compile vsDebugServerBundle && rm -rf out && mv -f dist out",
    },

    -- Lua adapter.
    {
      "jbyuki/one-small-step-for-vimkind",
      -- stylua: ignore
      keys = {
        { "<leader>dl", function() require("osv").launch({ port = 8086 }) end, desc = "[D]ebug: [L]ua",},
      },
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
    sign("DapBreakpoint", { text = "●", texthl = "DapBreakpoint", linehl = "", numhl = "" })
    sign("DapBreakpointCondition", { text = "●", texthl = "DapBreakpointCondition", linehl = "", numhl = "" })
    sign("DapLogPoint", { text = "◆", texthl = "DapLogPoint", linehl = "", numhl = "" })
    local dap = require("dap")
    local dapui = require("dapui")

    -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
    vim.keymap.set("n", "<leader>ds", dapui.toggle, { desc = "[D]ebug: See Last [S]ession Result" })

    dap.listeners.after.event_initialized["dapui_config"] = dapui.open
    dap.listeners.before.event_terminated["dapui_config"] = dapui.close
    dap.listeners.before.event_exited["dapui_config"] = dapui.close

    -- Lua configurations.
    dap.adapters.nlua = function(callback, config)
      callback({ type = "server", host = config.host or "127.0.0.1", port = config.port or 8086 })
    end
    dap.configurations["lua"] = {
      {
        type = "nlua",
        request = "attach",
        name = "Attach to running Neovim instance",
      },
    }

    -- C configurations.
    dap.adapters.codelldb = {
      type = "server",
      host = "localhost",
      port = "${port}",
      executable = {
        command = "codelldb",
        args = { "--port", "${port}" },
      },
    }

    -- Add configurations from launch.json
    require("dap.ext.vscode").load_launchjs(nil, {
      ["codelldb"] = { "c" },
      ["pwa-node"] = { "typescript", "javascript" },
    })
  end,
}
