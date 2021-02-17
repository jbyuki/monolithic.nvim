##monolithic
@../lua/monolithic.lua=
local M = {}

@configuration_variables
@script_variables
@functions

return M

@functions+=
function M.open()
	@glob_all_files_in_cwd
	@filter_out_files_with_wrong_extension_and_directories
	
	@create_scratch_buffer
	@set_buffer_as_current
	@include_syntax_highlight_for_languages
	@add_files_to_buffer_one_by_one
	@setup_treesitter_syntax_highlighting
	@setup_syn_sync
end

@configuration_variables+=
M.ext = { 
	["cpp"] = "cpp",
	["c"] = "c", 
	["hpp"] = "cpp", 
	["h"] = "c",
	["rs"] = "rust", 
	["go"] = "go",
	["lua"] = "lua", 
	["py"] = "python", 
	["js"] = "javascript", 
	["ts"] = "typescript",
	["vim"] = "vim",
	["hs"] = "haskell",
	["css"] = "css",
	["html"] = "html", 
	["htm"] = "html",
	["sh"] = "sh",
	["scm"] = "scheme",
	-- ["txt"] = "",
	-- ["md"] = "markdown",
}

@glob_all_files_in_cwd+=
local all_files = vim.fn.glob("**/*")

@filter_out_files_with_wrong_extension_and_directories+=
local valid_files = {}
for file in vim.gsplit(all_files, "\n") do
	local ext = vim.fn.fnamemodify(file, ":e")
	if vim.fn.isdirectory(file) == 0 and M.ext[ext] then
		table.insert(valid_files, file)
	end
end

@create_scratch_buffer+=
local buf = vim.api.nvim_create_buf(false, true)

@set_buffer_as_current+=
vim.api.nvim_set_current_buf(buf)

@add_files_to_buffer_one_by_one+=
local lnum = 0
for _, file in ipairs(valid_files) do
	@add_filename_in_buffer
	@read_filecontent
	@add_filecontent_in_buffer

	@compute_region_to_highlight
	@create_treesitter_parser
	if not parser and (M.ext[ext]  and M.ext[ext] ~= "") then
		@syntax_highlight_filecontent_with_proper_highlighting
		@set_using_standard_syntax_highlighting
	end
	@close_fold_around_file
end

@add_filename_in_buffer+=
local title = (M.header_pre or "-- ") .. file .. (M.header_post or " ---------------------------------------------------")
if lnum == 0 then
	vim.api.nvim_buf_set_lines(0, 0, 1, true, { title })
else
	vim.api.nvim_buf_set_lines(0, -1, -1, true, { title })
end
lnum = lnum + 1
vim.api.nvim_buf_add_highlight(0, 0, M.hl_filename or "Title", lnum-1, 0, -1)

@read_filecontent+=
local lines = {}
for line in io.lines(file) do
	table.insert(lines, line)
end

@add_filecontent_in_buffer+=
vim.api.nvim_buf_set_lines(0, -1, -1, true, lines)
lnum = lnum + #lines

@include_syntax_highlight_for_languages+=
local languages = {}
for _, file in ipairs(valid_files) do
	local ext = vim.fn.fnamemodify(file, ":e")
	languages[ext] = true
end

for lang,_ in pairs(languages) do
	if M.ext[lang] and M.ext[lang] ~= "" then
		vim.api.nvim_command("syn include @" .. M.ext[lang] .. " syntax/" .. M.ext[lang] .. ".vim")
	end
end

@add_files_to_buffer_one_by_one-=
local block_num = 1

@syntax_highlight_filecontent_with_proper_highlighting+=
vim.api.nvim_command("syn region block" .. block_num .. " start=\"\\%" .. startlnum .. "l\" end=\"\\%" .. endlnum .. "l\" contains=@" .. M.ext[ext])

@close_fold_around_file+=
vim.api.nvim_command((startlnum-1) .. "," .. (endlnum-1) .. "fold")

@compute_region_to_highlight+=
local startlnum = lnum - #lines + 1
local endlnum = lnum + 1

local ext = vim.fn.fnamemodify(file, ":e")

@add_files_to_buffer_one_by_one-=
local standard_syntax = false

@set_using_standard_syntax_highlighting+=
standard_syntax = true

@setup_syn_sync+=
if standard_syntax then
	vim.api.nvim_command("syn sync fromstart")
end

@add_files_to_buffer_one_by_one-=
local all_regions = {}

@create_treesitter_parser+=
local parser
if M.ext[ext] and M.ext[ext] ~= "" then
	parser = vim.treesitter.get_parser(buf, M.ext[ext])
end
if parser then
	local lang = M.ext[ext]
	all_regions[lang] = all_regions[lang] or {}
	table.insert(all_regions[lang], { {
		startlnum-1, 0, endlnum-1, 0
	} })
end

@setup_treesitter_syntax_highlighting+=
for lang, regions in pairs(all_regions) do
	local parser = vim.treesitter.get_parser(buf, lang)
	parser:set_included_regions(regions)
	vim.treesitter.highlighter.new(parser, {})
end
