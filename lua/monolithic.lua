-- Generated from core.lua.tl using ntangle.nvim
local M = {}

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
	["htm"] = "htm",
	["sh"] = "sh",
	["txt"] = "",
	["md"] = "md",
}

function M.open()
	local all_files = vim.fn.glob("**/*")
	
	local valid_files = {}
	for file in vim.gsplit(all_files, "\n") do
		local ext = vim.fn.fnamemodify(file, ":e")
		if vim.fn.isdirectory(file) == 0 and M.ext[ext] then
			table.insert(valid_files, file)
		end
	end
	
	
	local buf = vim.api.nvim_create_buf(false, true)
	
	vim.api.nvim_set_current_buf(buf)
	
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
	
	local block_num = 1
	
	local lnum = 0
	for _, file in ipairs(valid_files) do
		local title = (M.header_pre or "-- ") .. file .. (M.header_post or " ---------------------------------------------------")
		if lnum == 0 then
			vim.api.nvim_buf_set_lines(0, 0, 1, true, { title })
		else
			vim.api.nvim_buf_set_lines(0, -1, -1, true, { title })
		end
		lnum = lnum + 1
		vim.api.nvim_buf_add_highlight(0, 0, M.hl_filename or "Title", lnum-1, 0, -1)
		
		local lines = {}
		for line in io.lines(file) do
			table.insert(lines, line)
		end
		
		vim.api.nvim_buf_set_lines(0, -1, -1, true, lines)
		lnum = lnum + #lines
		
		local startlnum = lnum - #lines + 1
		local endlnum = lnum + 1
		
		local ext = vim.fn.fnamemodify(file, ":e")
		
		if M.ext[ext]  and M.ext[ext] ~= "" then
			vim.api.nvim_command("syn region block" .. block_num .. " start=\"\\%" .. startlnum .. "l\" end=\"\\%" .. endlnum .. "l\" contains=@" .. M.ext[ext])
		end
		
		vim.api.nvim_command((startlnum-1) .. "," .. (endlnum-1) .. "fold")
	end
	
	vim.api.nvim_command("syn sync fromstart")
	
end


return M

