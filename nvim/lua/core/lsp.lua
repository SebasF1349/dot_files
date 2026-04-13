local oss = require('utils.os')
vim.env.PATH = vim.fn.stdpath('data') .. '/mason/bin' .. (oss.is_win and ';' or ':') .. vim.env.PATH

local M = {}

vim.api.nvim_create_autocmd('LspProgress', {
  callback = function(ev)
    local value = ev.data.params.value
    local clientId = ev.data.client_id
    local client = assert(vim.lsp.get_clients({ id = clientId })[1])

    local msgId = ('progress-lsp-%s-%s'):format(clientId, value.title)
    local title = ('[%s] %s'):format(client.name or clientId, value.title)
    local msg = value.message or 'finished'

    vim.api.nvim_echo({ { msg } }, false, {
      id = msgId,
      kind = 'progress',
      source = 'lsp',
      status = 'success',
      title = title,
      percent = value.percentage,
    })
  end,
})

vim.diagnostic.config({
  underline = false,
  float = {
    severity_sort = true,
    header = '',
    prefix = '',
    format = function(d)
      return '- ' .. d.message
    end,
    suffix = function(d)
      return string.format('[%s: %s]', d.source, d.code), ''
    end,
  },
  jump = {
    on_jump = function(diagnostic, bufnr)
      if not diagnostic then
        return
      end
      vim.diagnostic.open_float({ bufnr = bufnr, scope = 'cursor', focus = false, header = 'Cursor Diagnostics:' })
    end,
  },
  severity_sort = true,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = '',
      [vim.diagnostic.severity.WARN] = '',
      [vim.diagnostic.severity.INFO] = '',
      [vim.diagnostic.severity.HINT] = '',
    },
    numhl = {
      [vim.diagnostic.severity.ERROR] = 'DiagnosticSignError',
      [vim.diagnostic.severity.WARN] = 'DiagnosticSignWarn',
      [vim.diagnostic.severity.INFO] = 'DiagnosticSignInfo',
      [vim.diagnostic.severity.HINT] = 'DiagnosticSignHint',
    },
  },
})

-- copied from https://github.com/neovim/nvim-lspconfig/blob/2163c54bb6cfec53e3e555665ada945b8c8331b9/lua/lspconfig/util.lua#L393-L398
-- until https://github.com/neovim/neovim/issues/33225 gets resolved
local function bufname_valid(bufname)
  if
    bufname:match('^/')
    or bufname:match('^[a-zA-Z]:')
    or bufname:match('^zipfile://')
    or bufname:match('^tarfile:')
  then
    return true
  end
  return false
end

vim.lsp.codelens.enable(true)

---@param client_id integer
---@param buf integer
local function on_attach(client_id, buf)
  local client = assert(vim.lsp.get_client_by_id(client_id))

  local bufname = vim.api.nvim_buf_get_name(buf)
  if #bufname ~= 0 and not bufname_valid(bufname) then
    return
  end

  local Kind = vim.lsp.protocol.CompletionItemKind
  local completion_kinds = {
    Class = '󰠱',
    Color = '󰏘',
    Constant = '󰏿',
    Constructor = '',
    Enum = '',
    EnumMember = '',
    Event = '',
    Field = '󰜢',
    File = '󰈙',
    Folder = '󰉋',
    Function = '󰊕',
    Interface = '',
    Keyword = '󰌋',
    Method = '󰆧',
    Module = '',
    Operator = '󰆕',
    Property = '󰜢',
    Reference = '󰈇',
    Snippet = '',
    Struct = '󰙅',
    Text = '󰉿',
    TypeParameter = '',
    Unit = '󰑭',
    Value = '󰎠',
    Variable = '󰀫',
  }

  vim.lsp.completion.enable(true, client_id, buf, {
    autotrigger = true,
    convert = function(item)
      local label = item.label
      if vim.o.filetype == 'php' then
        label = label:gsub('%s*%b[]', '')
      end
      local kind = Kind[item.kind]
      local detail = item.labelDetails and item.labelDetails.detail or item.detail
      if detail and #detail > 40 then
        detail = detail:sub(1, 40) .. '…'
      end
      return {
        abbr = label,
        menu = detail,
        kind = completion_kinds[kind],
        kind_hlgroup = kind and 'CmpItemKind' .. kind or 'CmpItemKindUnit',
      }
    end,
  })

  vim.o.pumheight = 6
  vim.o.completeopt = 'menuone,popup,noselect,fuzzy'
  vim.o.completeitemalign = 'kind,abbr,menu'

  vim.keymap.set('s', '<BS>', '<C-O>s', { desc = 'Delete Selected Text', buf = buf })
  vim.keymap.set('i', '<C-n>', function()
    if vim.fn.pumvisible() ~= 0 then
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-n>', true, false, true), 'n', false)
    elseif next(vim.lsp.get_clients({ bufnr = 0, method = 'textDocument/completion' })) then
      vim.lsp.completion.get()
    elseif vim.bo.omnifunc == '' then
      vim.api.nvim_input('<C-x><C-n>')
    else
      vim.api.nvim_input('<C-x><C-o>')
    end
  end, { desc = 'Trigger And Select Next Completion' })

  vim.keymap.set('n', ']e', function()
    vim.diagnostic.jump({ count = vim.v.count, severity = vim.diagnostic.severity.ERROR })
  end, { desc = 'LSP: Go to next [E]rror message', buf = buf })
  vim.keymap.set('n', '[e', function()
    vim.diagnostic.jump({ count = -vim.v.count, severity = vim.diagnostic.severity.ERROR })
  end, { desc = 'LSP: Go to prev [E]rror message', buf = buf })

  local function jump_to_reference(direction)
    return function()
      vim.lsp.buf.references(nil, {
        on_list = function(options)
          if not options or not options.items or #options.items == 0 then
            vim.notify('No references found', vim.log.levels.WARN)
            return
          end

          local next_location = 1
          local lnum = vim.fn.line('.')
          local col = vim.fn.col('.')
          for i, item in ipairs(options.items) do
            if item.lnum == lnum and col >= item.col and col <= item.end_col then
              next_location = i + direction
              break
            end
          end

          if next_location == 0 then
            next_location = #options.items
          elseif next_location > #options.items then
            next_location = 1
          end

          local item = options.items[next_location]
          vim.api.nvim_win_set_cursor(0, { item.lnum, item.col - 1 })
        end,
      })
    end
  end

  vim.keymap.set('n', '[r', jump_to_reference(-1), { desc = 'Jump to previous [R]eference' })
  vim.keymap.set('n', ']r', jump_to_reference(1), { desc = 'Jump to next [R]eference' })

  local ns_hl = vim.api.nvim_create_namespace('hlreferences')
  local function hl_references()
    vim.lsp.buf.references(nil, {
      on_list = function(options)
        if not options or not options.items or #options.items == 0 then
          vim.notify('No references found', vim.log.levels.WARN)
          return
        end

        local extmarks = {}
        for i, item in ipairs(options.items) do
          extmarks[i] = vim.api.nvim_buf_set_extmark(0, ns_hl, item.lnum - 1, item.col - 1, {
            hl_group = 'LspReferenceText',
            end_col = item.end_col - 1,
            virt_text_pos = 'overlay',
          })
          vim.defer_fn(function()
            vim.api.nvim_buf_del_extmark(0, ns_hl, extmarks[i])
          end, 10 * 1000)
        end
      end,
    })
  end

  vim.keymap.set('n', '<leader>8', hl_references, { desc = 'LSP: Select all references', buf = buf })

  vim.keymap.set('n', 'gr', '<NOP>', { desc = 'LSP mappings', buf = buf })
  vim.keymap.set('n', '<C-w>d', function()
    if
      vim.diagnostic.open_float({ scope = 'c', header = 'Cursor Diagnostics:' })
      or vim.diagnostic.open_float({ scope = 'l', header = 'Line Diagnostics:' })
    then
      return
    end
    vim.notify('No diagnostics found', vim.log.levels.INFO)
  end, { desc = 'Floating Diagnostics' })

  vim.keymap.set('n', 'gro', function()
    if vim.fn.exists(':OrganizeImports') > 0 then
      vim.cmd('OrganizeImports')
    else
      vim.lsp.buf.code_action({
        ---@diagnostic disable-next-line: missing-fields
        context = { only = { 'source.organizeImports' } },
        apply = true,
      })
    end
  end, { desc = 'LSP: [O]rganize Imports', buf = buf })

  for _, key in ipairs({ '<C-u>', '<C-d>' }) do
    vim.keymap.set({ 'n', 'i' }, key, function()
      local winnr = vim.b.lsp_floating_preview
      if not winnr or not vim.api.nvim_win_is_valid(winnr) then
        vim.api.nvim_feedkeys(vim.keycode(key), 'n', true)
        return
      end
      local cursor_pos = vim.api.nvim_win_get_cursor(winnr)
      local win_config = vim.api.nvim_win_get_config(winnr)
      local bufnr = vim.api.nvim_win_get_buf(winnr)
      local buflns = vim.api.nvim_buf_line_count(bufnr)
      if win_config.height >= buflns then
        vim.api.nvim_feedkeys(vim.keycode(key), 'n', true)
        return
      end
      local new_row = key == '<C-u>' and math.max(cursor_pos[1] - win_config.height + 1, 1)
        or math.min(cursor_pos[1] + win_config.height - 1, vim.fn.line('$', winnr))
      vim.api.nvim_win_set_cursor(winnr, { new_row, cursor_pos[2] })
    end, { desc = 'Scroll Docs' })
  end

  local ok_wd, wd = pcall(require, 'workspace-diagnostics', function()
    local cmd = { 'fd', '--type', 'file', '--full-path', '--color', 'never', vim.uv.cwd() }
    local files = vim.system(cmd, { text = true }):wait()
    if not files.stdout then
      return {}
    end
    return vim.split(vim.trim(files.stdout), '\n')
  end)
  if ok_wd then
    wd.populate_workspace_diagnostics(client, buf)
  end

  -- NOTE: only works on html, not in intelephense
  if client.server_capabilities.linkedEditingRangeProvider then
    vim.lsp.linked_editing_range.enable(true, { client_id = client_id })
  end
end

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
  callback = function(args)
    on_attach(args.data.client_id, args.buf)
  end,
})
local register_capability = vim.lsp.handlers[methods.client_registerCapability]
vim.lsp.handlers[methods.client_registerCapability] = function(err, res, ctx)
  local return_value = register_capability(err, res, ctx)
  on_attach(ctx.client_id, vim.api.nvim_get_current_buf())
  return return_value
end

local function float_config()
  local max_height = vim.fn.screenrow() == vim.o.scrolloff + 1 and vim.o.scrolloff - 1 or 8
  return {
    anchor_bias = 'above',
    max_height = max_height,
    max_width = math.floor(vim.o.columns * 0.4),
  }
end
local hover = vim.lsp.buf.hover
---@diagnostic disable-next-line: duplicate-set-field
vim.lsp.buf.hover = function()
  hover(float_config())
end
local signature_help = vim.lsp.buf.signature_help
---@diagnostic disable-next-line: duplicate-set-field
vim.lsp.buf.signature_help = function()
  signature_help(float_config())
end

M.servers = {}
for _, v in ipairs(vim.api.nvim_get_runtime_file('lsp/*', true)) do
  local name = vim.fn.fnamemodify(v, ':t:r')
  M.servers[name] = true
end

vim.lsp.enable(vim.tbl_keys(M.servers))

vim.lsp.commands['editor.action.triggerParameterHints'] = vim.lsp.buf.signature_help
vim.lsp.commands['editor.action.triggerSuggest'] = vim.lsp.completion.get

return M
