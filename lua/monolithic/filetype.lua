local filetype = {}
local fn = vim.fn

function filetype.extract_extension(filename)
	local ext = fn.fnamemodify(filename, ":e")
	return ext
end

function filetype.set_lookup(lookup)
	filetype._lookup = lookup
end

function filetype.get_lang(filename)
	local ext = filetype.extract_extension(filename)
	return filetype._lookup[ext]
end

function filetype.has_lang(filename)
	local ext = filetype.extract_extension(filename)
	return filetype._lookup[ext] ~= nil
end

return filetype
