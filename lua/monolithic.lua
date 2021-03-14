local view = require "monolithic.view"
local ft = require "monolithic.filetype"
local explore = require "monolithic.explore"
local action = require "monolithic.action"
local history = require "monolithic.history"
local writer = require "monolithic.writer"
local validate = vim.validate
local api = vim.api

local M = {}

-- file extenstion to language name
-- 
-- language name:
-- 		vim syntax: $VIMRUNTIME/syntax/{language name}.vim
-- 		treesitter: vim.treesitter.get_parser(buf, "language name")
--
-- is there a better way to do this?
-- PR so that your language is included
M._ext_map = { 
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
  ["scm"] = "scheme",
  -- ["txt"] = "",
  -- ["md"] = "markdown",
}

ft.set_lookup(M._ext_map)

M._view_opts = {}
M._views = {}

local hide_line_numbering = true

function M.setup(opts)
  validate {
    opts = { opts, 't' };
  }

  validate {
    ext_map = { opts.ext_map, 't', true },
    header_hl_group = { opts.header_hl_group, 's', true },
    header_pre = { opts.header_pre, 's', true },
    header_post = { opts.header_post, 's', true },
    hide_line_numbering = { opts.hide_line_numbering, 'b', true },
    history_save_file = { opts.history_save_file, 's', true },
  }

  if opts.ext_map then
    for ext, filetype in pairs(opts.ext_map) do
      validate {
        ext = { ext, 's' },
        filetype = { filetype, 's' },
      }

      M._ext_map[ext] = val
    end

    ft.set_lookup(M._ext_map)
  end

  if opts.hide_line_numbering ~= nil then
    hide_line_numbering = opts.hide_line_numbering
  end

  if opts.history_save_file ~= nil then
    history._save_file = opts.history_save_file
  end
  M.setup_view(opts)
end

function M.setup_view(opts) 
  M._view_opts.header_hl_group = opts.header_hl_group
  M._view_opts.header_pre = opts.header_pre
  M._view_opts.header_post = opts.header_post
end

-- Open monolithic buffer in current window
function M.open()
  local v = view.new(M._view_opts, explore.get_name())
  local files = explore.cwd(M._ext_map)

  v:add_files(files)
  v:set_as_current_buf()
  v:set_extmarks()
  v:enable_syntax_highlighting()
  v:create_folds()
  if hide_line_numbering then
    v:disable_line_numbering()
  end
  v:attach_actions()

  M._views[v._buffer] = v

  history.add(vim.fn.getcwd())
  v:setup_writer()
end

function M._get_view(bufnr)
  return M._views[bufnr]
end

function M.jump_edit()
  local v = M._get_view(vim.api.nvim_get_current_buf())
  action.jump_to_file(v)
end

function M.save_all(buf)
  local v = M._views[buf]
  local lines = api.nvim_buf_get_lines(buf, 0, -1, true)
  local modified = {}
  if v then
    for i=1,#v._filenames do
      local filename = v._filenames[i]
      local startext, endext = unpack(v._extmarks[i])

      local startlnum, _ = unpack(api.nvim_buf_get_extmark_by_id(buf, v._ns_id, startext, {}))
      local endlnum, _ = unpack(api.nvim_buf_get_extmark_by_id(buf, v._ns_id, endext, {}))

      if writer.has_changed(filename, lines, startlnum, endlnum) then
        local count = writer.write(filename, lines, startlnum, endlnum)
        table.insert(modified, {
          filename = vim.fn.fnamemodify(filename, ":."),
          lines = endlnum - startlnum,
          character = count,
        })
      end
    end
  end
  vim.bo.modified = false
  for _, m in ipairs(modified) do
    print("\"" .. m.filename .. "\" " .. m.lines .. "L, " .. m.character .. "C written")
  end
end

return M
