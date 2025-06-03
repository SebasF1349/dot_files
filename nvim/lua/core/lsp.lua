local ui = require('utils.ui')
local signs = ui.diagnostic_icons_num
local get_diagnostic_hl = ui.get_diagnostic_hl
local methods = vim.lsp.protocol.Methods

local oss = require('utils.os')
vim.env.PATH = vim.fn.stdpath('data') .. '/mason/bin' .. (oss.is_win and ';' or ':') .. vim.env.PATH

local M = {}

-- Diagnostics
vim.diagnostic.config({
  underline = false,
  float = {
    scope = 'cursor',
    severity_sort = true,
    source = false,
    header = '',
    prefix = '',
    format = function(d)
      return '- ' .. d.message
    end,
    suffix = function(d)
      return string.format('[%s: %s]', d.source, d.code), ''
    end,
  },
  jump = { float = true },
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

-- LSP progress messages on cmdline
---@diagnostic disable-next-line: duplicate-set-field
vim.lsp.handlers['$/progress'] = function(_, progress, ctx)
  local msg = progress.value

  if msg.kind ~= 'end' and msg.kind ~= 'begin' then
    return
  end

  local client = vim.lsp.get_client_by_id(ctx.client_id)
  local client_name = client and client.name and '[' .. client.name .. ']' or ''

  local title = msg.title and ' ' .. msg.title or ''

  local kind = msg.kind == 'end' and 'done' or 'starting...'

  local out = string.format('%s%s %s', client_name, title, kind)

  vim.notify(out, vim.log.levels.INFO)
end

-- copied from https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/util.lua#L23C1-L28C4
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

---@param client_id integer
---@param buf integer
local function on_attach(client_id, buf)
  local client = assert(vim.lsp.get_client_by_id(client_id))

  local bufname = vim.api.nvim_buf_get_name(buf)
  if #bufname ~= 0 and not bufname_valid(bufname) then
    client:stop()
    return
  end

  if client:supports_method('completionItem/resolve') then
    local cancel_prev = function() end
    vim.api.nvim_create_autocmd('CompleteChanged', {
      buffer = buf,
      callback = function()
        cancel_prev()
        local info = vim.fn.complete_info({ 'selected' })
        local completionItem = vim.tbl_get(vim.v.completed_item, 'user_data', 'nvim', 'lsp', 'completion_item')
        if nil == completionItem then
          return
        end
        _, cancel_prev = vim.lsp.buf_request(buf, methods.completionItem_resolve, completionItem, function(_, item, _)
          if not item then
            return
          end
          local docs = (item.documentation or {}).value
          local win = vim.api.nvim__complete_set(info['selected'], { info = docs })
          if win.winid and vim.api.nvim_win_is_valid(win.winid) then
            vim.treesitter.start(win.bufnr, 'markdown')
            vim.wo[win.winid].conceallevel = 3
          end
        end)
      end,
    })
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

  -- TODO: more languages: https://github.com/xzbdmw/colorful-menu.nvim/blob/master/lua/colorful-menu/languages/lua.lua
  ---@param completion_item lsp.CompletionItem
  local function intelephense(completion_item)
    local label = completion_item.label
    local detail = completion_item.labelDetails and completion_item.labelDetails.detail or completion_item.detail
    local kind = completion_item.kind

    if (kind == Kind.Function or kind == Kind.Method) and detail and #detail > 0 then
      local signature = detail:sub(#label + 1)
      return string.format('%s fn %s {}', label, signature)
    elseif kind == Kind.EnumMember and detail and #detail > 0 then
      return string.format('%s %s', label, detail)
    elseif (kind == Kind.Property or kind == Kind.Variable) and detail and #detail > 0 then
      detail = string.gsub(detail, '.*\\(.)', '%1')
      return string.format('%s %s', label, detail)
    elseif kind == Kind.Constant and detail and #detail > 0 then
      return string.format('%s %s', label, detail)
    else
      return label
    end
  end

  vim.lsp.completion.enable(true, client_id, buf, {
    autotrigger = true,
    convert = function(item)
      local label = intelephense(item)
      if #label > 60 then
        label = label:sub(1, 60) .. '…'
      end
      local kind = Kind[item.kind]
      return {
        abbr = label,
        menu = '',
        kind = completion_kinds[kind],
        kind_hlgroup = kind and 'CmpItemKind' .. kind or 'CmpItemKindUnit',
      }
    end,
  })

  vim.o.pumheight = 6
  vim.opt.completeopt = { 'menuone', 'popup', 'noselect', 'fuzzy' }
  vim.o.completeitemalign = 'kind,abbr,menu'

  vim.keymap.set('s', '<BS>', '<C-O>s', { desc = 'Delete Selected Text', buffer = buf })
  vim.keymap.set('i', '<C-n>', function()
    if vim.fn.pumvisible() ~= 0 then
      vim.api.nvim_input('<C-n>')
    elseif next(vim.lsp.get_clients({ bufnr = 0, method = 'textDocument/completion' })) then
      vim.lsp.completion.get()
    elseif vim.bo.omnifunc == '' then
      vim.api.nvim_input('<C-x><C-n>')
    else
      vim.api.nvim_input('<C-x><C-o>')
    end
  end, { desc = 'Trigger And Select Next Completion' })
  -- NOTE: nice pum styling https://github.com/neovim/neovim/pull/25541

  -- if client and client.server_capabilities.inlayHintProvider and vim.lsp.inlay_hint then
  --   require('inlay-hint').setup()
  --   vim.lsp.inlay_hint.enable(true)
  --   vim.keymap.set('n', '<leader>ti', function()
  --     vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = 0 }))
  --   end, { desc = 'LSP: [T]oggle [I]nlay Hints', buffer = buf })
  -- end

  -- local reset_vl = vim.schedule_wrap(function()
  --   vim.diagnostic.config({ virtual_lines = { current_line = true } })
  --   vim.api.nvim_create_autocmd('CursorMoved', {
  --     once = true,
  --     callback = function()
  --       vim.diagnostic.config({ virtual_lines = false })
  --     end,
  --   })
  -- end)

  -- vim.keymap.set('n', ']d', function()
  --   vim.diagnostic.jump({ count = 1 })
  --   reset_vl()
  -- end, { desc = 'LSP: Go to next [D]iagnostic message' })
  -- vim.keymap.set('n', '[d', function()
  --   vim.diagnostic.jump({ count = -1 })
  --   reset_vl()
  -- end, { desc = 'LSP: Go to prev [D]iagnostic message' })
  vim.keymap.set('n', ']e', function()
    vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR })
  end, { desc = 'LSP: Go to next [E]rror message', buffer = buf })
  vim.keymap.set('n', '[e', function()
    vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR })
  end, { desc = 'LSP: Go to prev [E]rror message', buffer = buf })

  -- replaced my own implementation with Folke's which is more performant: https://github.com/folke/snacks.nvim/blob/main/lua/snacks/words.lua#L117
  local ns = vim.api.nvim_create_namespace('nvim.lsp.references')

  ---@alias LspWord {from:{[1]:number, [2]:number}, to:{[1]:number, [2]:number}} 1-0 indexed

  ---@return LspWord[] words, number? current
  local function get_lsp_word()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local current, ret = nil, {} ---@type number?, LspWord[]
    for _, extmark in ipairs(vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, { details = true })) do
      local w = {
        from = { extmark[2] + 1, extmark[3] },
        to = { extmark[4].end_row + 1, extmark[4].end_col },
      }
      ret[#ret + 1] = w
      if cursor[1] >= w.from[1] and cursor[1] <= w.to[1] and cursor[2] >= w.from[2] and cursor[2] <= w.to[2] then
        current = #ret
      end
    end
    return ret, current
  end

  ---@param count number
  ---@param direction 1 | -1
  ---@param cycle? boolean
  local function move_reference(count, direction, cycle)
    local words, idx = get_lsp_word()
    if not idx then
      return
    end
    idx = idx + count * direction
    if cycle then
      idx = (idx - 1) % #words + 1
    end
    local target = words[idx]
    if target then
      vim.api.nvim_win_set_cursor(0, target.from)
    end
  end

  vim.keymap.set('n', ']r', function()
    move_reference(vim.v.count1, 1, true)
  end, { desc = 'LSP: Go to next [R]eference', buffer = buf })
  vim.keymap.set('n', '[r', function()
    move_reference(vim.v.count1, -1, true)
  end, { desc = 'LSP: Go to previous [R]eference', buffer = buf })

  local ns_hl = vim.api.nvim_create_namespace('hlreferences')
  local function hl_references()
    local extmarks = {}
    for i, extmark in ipairs(vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, { details = true })) do
      extmarks[i] = vim.api.nvim_buf_set_extmark(
        0,
        ns_hl,
        extmark[2],
        extmark[3],
        { hl_group = 'LspReferenceShow', end_col = extmark[4].end_col, virt_text_pos = 'overlay' }
      )
      vim.defer_fn(function()
        vim.api.nvim_buf_del_extmark(0, ns_hl, extmarks[i])
      end, 10 * 1000)
    end
  end

  vim.keymap.set('n', '<leader>8', hl_references, { desc = 'LSP: Go to previous [R]eference', buffer = buf })

  vim.keymap.set('n', 'gr', '<NOP>', { desc = 'LSP mappings', buffer = buf })
  vim.keymap.set('n', '<C-w><C-d>', '<C-w>d', { desc = 'Make <C-w><C-d> also trigger float', remap = true })
  vim.keymap.set('n', '<C-w>d', function()
    if
      vim.diagnostic.open_float({ scope = 'c', header = 'Cursor Diagnostics:' })
      or vim.diagnostic.open_float({ scope = 'l', header = 'Line Diagnostics:' })
    then
      return
    end
    vim.notify('No diagnostics found', vim.log.levels.INFO)
  end, { desc = 'Floating Diagnostics' })
  vim.keymap.set('n', 'grt', vim.lsp.buf.type_definition, { desc = 'LSP: [G]oto [T]ype Definition', buffer = buf })

  local preview_namespace = vim.api.nvim_create_namespace('preview')
  vim.keymap.set('n', 'grp', function()
    local diag = vim.diagnostic.get(0, { lnum = vim.fn.line('.') - 1 })
    if #diag == 0 then
      return
    end
    local hls = {}
    diag = vim
      .iter(diag)
      :map(function(d)
        table.insert(hls, get_diagnostic_hl(d.severity))
        return signs[d.severity] .. ' ' .. d.code .. ': ' .. d.message
      end)
      :totable()
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(bufnr, 0, #diag, false, diag)
    vim.o.previewheight = math.min(#diag + 1, 5)
    for line, hl in ipairs(hls) do
      vim.hl.range(bufnr, preview_namespace, hl, { line - 1, 0 }, { line - 1, vim.o.columns })
    end
    vim.cmd('pbuffer ' .. bufnr)
  end, { desc = 'Open Diagnostics Preview' })

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
  end, { desc = 'LSP: [O]rganize Imports', buffer = buf })

  for _, key in ipairs({ '<C-u>', '<C-d>' }) do
    vim.keymap.set({ 'n', 'i' }, key, function()
      local winnr = vim.b.lsp_floating_preview
      if not winnr or not vim.api.nvim_win_is_valid(winnr) then
        local keys = vim.api.nvim_replace_termcodes(key, true, false, true)
        vim.api.nvim_feedkeys(keys, 'n', true)
        return
      end
      local cursor_pos = vim.api.nvim_win_get_cursor(winnr)
      local win_config = vim.api.nvim_win_get_config(winnr)
      local bufnr = vim.api.nvim_win_get_buf(winnr)
      local buflns = vim.api.nvim_buf_line_count(bufnr)
      if win_config.height >= buflns then
        local keys = vim.api.nvim_replace_termcodes(key, true, false, true)
        vim.api.nvim_feedkeys(keys, 'n', true)
        return
      end
      local new_row = key == '<C-u>' and math.max(cursor_pos[1] - win_config.height + 1, 1)
        or math.min(cursor_pos[1] + win_config.height - 1, vim.fn.line('$', winnr))
      vim.api.nvim_win_set_cursor(winnr, { new_row, cursor_pos[2] })
    end, { desc = 'Scroll Docs' })
  end

  -- based on https://github.com/mfussenegger/nvim-qwahl/blob/main/lua/qwahl.lua#L446C1-L468C4
  ---@param bufnr? integer 0 for current buffer; nil for all diagnostic
  ---@param opts? {lnum?: integer, severity?: vim.diagnostic.Severity} See vim.diagnostic.get
  local function select_diagnostic(bufnr, opts)
    local diagnostics = vim.diagnostic.get(bufnr, opts)
    local ui_opts = {
      prompt = 'Diagnostic: ',
      format_item = function(d)
        local new_line = d.message:find('\n')
        if new_line then
          d.message = d.message:sub(1, new_line - 1)
        end
        local bname = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(d.bufnr), ':p:.')
        local lnum = d.lnum or d.end_lnum
        return string.format('%s%s (%s:%s)', signs[d.severity], d.message, bname, lnum + 1)
      end,
    }
    local win = vim.api.nvim_get_current_win()
    vim.ui.select(diagnostics, ui_opts, function(d)
      if d then
        vim.api.nvim_set_current_buf(d.bufnr)
        vim.api.nvim_win_set_cursor(win, { d.lnum + 1, d.col })
        vim.api.nvim_win_call(win, function()
          vim.cmd('normal! zvzz')
        end)
      end
    end)
  end
  vim.keymap.set('n', 'grl', select_diagnostic, { desc = '[L]ist Diagnostics', buffer = buf })

  local ok_wd, wd = pcall(require, 'workspace-diagnostics')
  if ok_wd then
    wd.populate_workspace_diagnostics(client, buf)
  end

  -- if client:supports_method('textDocument/foldingRange') then
  --   vim.wo.foldmethod = 'expr'
  --   vim.wo.foldexpr = 'v:lua.vim.lsp.foldexpr()'
  -- end

  vim.lsp.document_color.enable(true, buf, { style = 'virtual' })

  if client.server_capabilities.documentHighlightProvider then
    local highlight_augroup = vim.api.nvim_create_augroup('lsp-highlight', { clear = false })
    -- Highlight references of the word under your cursor
    vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI', 'ModeChanged' }, {
      group = highlight_augroup,
      buffer = buf,
      callback = function()
        vim.schedule(function()
          vim.lsp.buf.clear_references()
          if vim.api.nvim_get_mode().mode == 'n' then
            vim.lsp.buf.document_highlight()
          end
        end)
      end,
    })

    -- Clear highlight when detaching lsp (fix some lsp errors)
    vim.api.nvim_create_autocmd('LspDetach', {
      group = vim.api.nvim_create_augroup('lsp-detach', { clear = true }),
      buffer = buf,
      callback = function(local_event)
        vim.lsp.buf.clear_references()
        vim.api.nvim_clear_autocmds({ group = 'lsp-highlight', buffer = local_event.buf })
      end,
    })
  end
end

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
  ---@param args {buf:integer, data:{client_id:integer}}
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

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem.snippetSupport = true
capabilities.textDocument.semanticTokens.multilineTokenSupport = true

vim.lsp.config('*', {
  capabilities = capabilities,
  root_markers = { '.git' },
})

M.servers = {}
for _, v in ipairs(vim.api.nvim_get_runtime_file('lsp/*', true)) do
  local name = vim.fn.fnamemodify(v, ':t:r')
  M.servers[name] = true
end

vim.lsp.enable(vim.tbl_keys(M.servers))

vim.lsp.commands['editor.action.triggerParameterHints'] = vim.lsp.buf.signature_help
vim.lsp.commands['editor.action.triggerSuggest'] = vim.lsp.completion.get

return M
