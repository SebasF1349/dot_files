local M = {}

---@param path string
M.read = function(path)
  local fd = vim.uv.fs_open(path, 'r', 438)
  if not fd then
    return
  end

  local stat = assert(vim.uv.fs_fstat(fd))
  local data = assert(vim.uv.fs_read(fd, stat.size, 0))
  assert(vim.uv.fs_close(fd))
  return data
end

---@param path string
---@param data string
M.write = function(path, data)
  local fd = assert(vim.uv.fs_open(path, 'w', 438))
  assert(vim.uv.fs_write(fd, data, 0))
  assert(vim.uv.fs_close(fd))
end

---@param path string
---@return table | nil
M.read_json = function(path)
  local data = M.read(path)
  if not data then
    return
  end
  return vim.json.decode(data)
end

---@param path string
---@param data table
M.write_json = function(path, data)
  local data_json = vim.json.encode(data)
  M.write(path, data_json)
end

return M
