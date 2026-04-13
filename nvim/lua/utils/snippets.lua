local M = {}

---Refer to <https://microsoft.github.io/language-server-protocol/specification/#snippet_syntax>
---for the specification of valid body.
---@param trigger string trigger string for snippet
---@param body string snippet text that will be expanded
---@param opts? vim.keymap.set.Opts
function M.addSnippet(trigger, body, opts)
  opts = opts or { buf = 0 }
  vim.keymap.set('ia', trigger, function()
    -- If abbrev is expanded with keys like "(", ")", "<cr>", "<space>",
    -- don't expand the snippet. Only accept "<c-]>" as trigger key.
    ---@diagnostic disable-next-line: param-type-mismatch
    local c = vim.fn.nr2char(vim.fn.getchar(0))
    if c ~= '' then
      vim.api.nvim_feedkeys(trigger .. c, 'i', true)
      return
    end
    vim.snippet.expand(body)
  end, opts)
end

-- NOTE: check https://github.com/rafamadriz/friendly-snippets/tree/main/snippets for useful snippets

return M
