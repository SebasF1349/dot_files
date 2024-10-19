return {
  dir = '~/dot_files/nvim/lua/uim',
  lazy = false,
  config = function()
    local uim = require('uim')
    uim.setup({
      kind = {
        codeaction = {
          keys_method = 'intelligent',
          -- stylua: ignore
          possible_chars = { 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
                            'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z' },
        },
      },
    })

    vim.ui.select = uim.select()
    vim.ui.input = uim.input()

    vim.ui.open = (function(overridden)
      return function(path, opt)
        vim.validate({
          path = { path, 'string' },
        })
        local is_uri = path:match('%w+:')
        local is_half_url = path:match('%.com$') or path:match('%.com%.')
        local is_repo = vim.bo.filetype == 'lua' and path:match('%w/%w') and vim.fn.count(path, '/') == 1
        local is_dir = path:match('/%w')
        if not is_uri then
          if is_half_url then
            path = ('https://%s'):format(path)
          elseif is_repo then
            path = ('https://github.com/%s'):format(path)
          elseif not is_dir then
            path = ('https://google.com/search?q=%s'):format(path)
          end
        end
        overridden(path, opt)
      end
    end)(vim.ui.open)
  end,
}
