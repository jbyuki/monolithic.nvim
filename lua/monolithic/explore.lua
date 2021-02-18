local ft = require "monolithic.filetype"
local explorer = {}
local fn = vim.fn

function explorer.glob_cwd()
  local path_str = fn.glob("**/*")
  local paths = vim.split(path_str, "\n")

  -- if the string is empty, { "" } is returned
  -- returned by split
  if #paths == 1 and paths[1] == "" then
    return {}
  end
  return paths
end

function explorer.filter(paths, ext_map)
  local files = {}
  for _, path in ipairs(paths) do
    local ext = ft.extract_extension(path)
    if vim.fn.isdirectory(path) == 0 and ext_map[ext] then
      table.insert(files, path)
    end
  end
  return files
end

function explorer.cwd(ext_map)
  local paths = explorer.glob_cwd()
  local valid_files = explorer.filter(paths, ext_map)
  return valid_files
end

return explorer
