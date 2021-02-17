local api = vim.api
local ft = require "monolithic.filetype"
local hl = require "monolithic.highlight"
local view = {}

-- create an empty view with its buffer
function view.new(opts)
	local new_view = {
		_buffer = api.nvim_create_buf(false, true),
		_header_pre = opts.header_pre or "-- ",
		_header_post = opts.header_pre or " -------------------------------------------",
		_header_hl_group = opts.header_hl_group or "Title",
		_filenames = {},
		_regions = {},
		_langs = {},
		_langs_set = {},
		_lnum = 0,
		_header_lnums = {},
		_hide_line_numbering = opts.hide_line_numbering
	}

	return setmetatable(new_view, {
		__index = view
	})
end

-- add file contents to the buffer
function view:add_files(filenames)
	for _, filename in ipairs(filenames) do
		self:add_file_header(filename)
		self:add_file_content(filename)
	end
end

-- add file header at the top
function view:add_file_header(filename)
	local title = self._header_pre .. filename .. self._header_post
	if self._lnum == 0 then
		api.nvim_buf_set_lines(self._buffer, 0, 1, true, { title })
	else
		api.nvim_buf_set_lines(self._buffer, -1, -1, true, { title })
	end

	table.insert(self._header_lnums, self._lnum)

	self._lnum = self._lnum + 1
end

-- add file content and save its region in buffer
function view:add_file_content(filename)
	local content = {}
	for line in io.lines(filename) do
		table.insert(content, line)
	end

	api.nvim_buf_set_lines(self._buffer, -1, -1, true, content)

	table.insert(self._filenames, filename)
	table.insert(self._langs, ft.get_lang(filename))
	table.insert(self._regions, { self._lnum, self._lnum + #content })
	self._lnum = self._lnum + #content
end

-- mark the correct regions with syntax
-- highlighter and enable it
--
-- use treesitter if available
function view:enable_syntax_highlighting()
	hl.highlight_headers(self._buffer, self._header_lnums, self._header_hl_group)

	if hl.is_treesitter_supported(self._buffer, self._langs) then
		hl.highlight_with_treesitter(self._buffer, self._langs, self._regions)
	else
		hl.highlight_with_vim(self._buffer, self._langs, self._regions)
	end
end

-- clear the buffer content and associated metadata
function view:clear()
	self._filenames = {}
	self._regions = {}
	self._langs = {}
	self._lnum = 0
	self._header_lnums = {}

	api.nvim_buf_set_lines(self._buffer, 0, -1, true, {})
end

-- display view in current window
function view:set_as_current_buf()
	api.nvim_set_current_buf(self._buffer)
end

function view:show_in_vsplit()
	api.nvim_command("vsplit")
	self.set_as_current_buf()
end

function view:show_in_split()
	api.nvim_command("split")
	self.set_as_current_buf()
end

-- create folds based on regions
function view:create_folds()
	assert(api.nvim_get_current_buf() == self._buffer)

	for i=1,#self._regions do
		local top, bot = unpack(self._regions[i])
		api.nvim_command(top .. "," .. bot .. "fold")
	end
end

-- create folds based on regions
function view:disable_line_numbering()
	if self._hide_line_numbering == nil or self._hide_line_numbering then
		assert(api.nvim_get_current_buf() == self._buffer)

		api.nvim_command("setlocal nonumber")
		api.nvim_command("setlocal norelativenumber")
	end
end

return view
