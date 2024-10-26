local M = {
  ---@type uim.Opts
  opts = {},
}

---@class uim.OptsClosingKeys
---@field [1] string
---@field modes string[]

---@class uim.OptsSelect
---@field position? 'bottom' | 'right' | 'center' | 'cursor'
---@field border? 'none' | 'single' | 'double' | 'rounded' | 'solid' | 'shadow'
---@field title_pos? 'left' | 'center' | 'right'
---@field keys_method? 'list' | 'intelligent'
---@field possible_chars? string[]
---@field ignore_chars? string[]
---@field closing_keys? (string | uim.OptsClosingKeys)[] -- string maps to all modes
---@field footer_labels? boolean
---@field autoselect? boolean

---@class uim.OptsInput
---@field position? 'bottom' | 'right' | 'center' | 'cursor' | 'cmdline'
---@field border? 'none' | 'single' | 'double' | 'rounded' | 'solid' | 'shadow'
---@field title_pos? 'left' | 'center' | 'right'
---@field closing_keys? (string | uim.OptsClosingKeys)[]

---@class uim.Opts
---@field select? uim.OptsSelect
---@field input? uim.OptsInput
---@field kind? table<string, uim.OptsSelect>
M.opts = {
  select = {
    position = 'bottom',
    border = 'none',
    title_pos = 'left',
    keys_method = 'list',
    -- stylua: ignore
    possible_chars = { 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', "'",
                      'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '[' },
    ignore_chars = {},
    closing_keys = { 'q', '<C-c>', '<ESC>' },
    footer_labels = true,
    autoselect = false,
  },
  input = {
    position = 'cmdline',
    border = 'none',
    title_pos = 'left',
    closing_keys = { { 'q', modes = { 'n', 'v' } }, '<C-c>' },
  },
}

---@param config uim.Opts
function M.setup(config)
  ---@type uim.Opts
  M.opts = vim.tbl_deep_extend('force', {}, M.opts, config or {})
end

return M
