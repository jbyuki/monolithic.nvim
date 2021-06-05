##test
@../test/test.lua=
@get_path_of_monolithic_repo
@change_directory_to_monolithic
@glob_all_files_in_cwd

@get_path_of_monolithic_repo+=
local info = debug.getinfo(1, "S")
local path
if info and info.source:sub(1, 1) == "@" then
  path = vim.fn.fnamemodify(info.source:sub(2), ":p")
end
path = vim.fn.fnamemodify(path, ":h:h")
local monolithic_path = path


@change_directory_to_monolithic+=
vim.api.nvim_command ([[cd ]] .. monolithic_path)

@glob_all_files_in_cwd+=
require"monolithic".open()
