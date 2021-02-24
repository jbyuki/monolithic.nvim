local history = {}

history._limit = 50

history.add = function(path)
  if not history._save_file then return end
  local save_file = vim.fn.expand(history._save_file, ":p")

  -- if file non existent create empty file
  if vim.fn.filereadable(save_file) == 0 then
    local f = io.open(save_file, "w")
    f:write("\n")
    f:close()
  end

  -- read lines
  local dirs = {}
  for line in io.lines(save_file) do
    table.insert(dirs, line)
  end

  -- append new entry
  table.insert(dirs, path)

  while #dirs > history._limit do
    table.remove(dirs)
  end

  -- write lines
  local f = io.open(save_file, "w")
  for _, line in ipairs(dirs) do
    f:write(line .. "\n")
  end
  f:close()
end

history.get = function()
  if not history._save_file then return {} end
  local save_file = vim.fn.expand(history._save_file, ":p")

  -- if file non existent create empty file
  if vim.fn.filereadable(save_file) == 0 then
    local f = io.open(save_file, "w")
    f:close()
  end

  local dirs = {}
  for line in io.lines(save_file) do
    table.insert(dirs, line)
  end
  return dirs
end

return history
