-- Generated using ntangle.nvim
local info = debug.getinfo(1, "S")
local path
if info and info.source:sub(1, 1) == "@" then
  path = vim.fn.fnamemodify(info.source:sub(2), ":p")
end
path = vim.fn.fnamemodify(path, ":h:h")
local monolithic_path = path


vim.api.nvim_command ([[cd ]] .. monolithic_path)

require"monolithic".open()

