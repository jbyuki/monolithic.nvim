local api = vim.api
local ft = require "monolithic.filetype"
local hl = require "monolithic.highlight"
local writer = require "monolithic.writer"
local view = {}

-- create an empty view with its buffer
function view.new(opts, name)
  local new_view = {
    _header_pre = opts.header_pre or "-- ",
    _header_post = opts.header_pre or " -------------------------------------------",
    _header_hl_group = opts.header_hl_group or "Title",
    _filenames = {},
    _regions = {},
    _langs = {},
    _langs_set = {},
    _lnum = 0,
    _name = name,
    _header_lnums = {},
    _keymap_edit = opts.keymap_edit or "<tab>",
    _ns_id = api.nvim_create_namespace(""),
    _extmarks = {},
  }

  local buf = vim.fn.bufnr(name)
  if buf ~= -1 then
    api.nvim_command("bw " .. buf)
  end

  new_view._buffer = api.nvim_create_buf(false, true)
  api.nvim_buf_set_name(new_view._buffer, name)

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
    hl.highlight_with_treesitter(self._buffer, self._langs, self._regions,self._ns_id, self._extmarks)
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
  if self._rename then
    api.nvim_command("file " .. self._name)
    self._rename = true
  end
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
  assert(api.nvim_get_current_buf() == self._buffer)

  api.nvim_command("setlocal nonumber")
  api.nvim_command("setlocal norelativenumber")
end

-- get filename and line number at lnum
function view:get_location_at(lnum)
  lnum = lnum - 1
  assert(lnum >= 0 and lnum < self._lnum)

  for i, region in ipairs(self._regions) do
    if lnum >= region[1] and lnum < region[2] then
      return self._filenames[i], (lnum-region[1])+1
    end
  end
end

function view:attach_actions()
  if self._keymap_edit then
    api.nvim_buf_set_keymap(self._buffer, 'n', self._keymap_edit, [[<cmd>lua require"monolithic".jump_edit()<CR>]], { noremap = true })
  end
end

function view:setup_writer()
  writer.set_buftype(self._buffer)
  writer.set_bufwritecmds(self._buffer)
  vim.bo.modified = false
end

function view:set_extmarks()
  for _, region in ipairs(self._regions) do
    local startnum, endnum = unpack(region)
    table.insert(self._extmarks, {
      api.nvim_buf_set_extmark(
        self._buffer, self._ns_id, startnum, 0, {}),
      api.nvim_buf_set_extmark(
        self._buffer, self._ns_id, endnum, 0, {})
    })
  end
end

return view
