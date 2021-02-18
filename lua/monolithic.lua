local view = require "monolithic.view"
local ft = require "monolithic.filetype"
local explore = require "monolithic.explore"
local validate = vim.validate

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

  M.setup_view(opts)
end

function M.setup_view(opts) 
  M._view_opts.header_hl_group = opts.header_hl_group
  M._view_opts.header_pre = opts.header_pre
  M._view_opts.header_post = opts.header_post
  M._view_opts.hide_line_numbering = opts.hide_line_numbering
end

-- Open monolithic buffer in current window
function M.open()

  local v = view.new(M._view_opts)
  local files = explore.cwd(M._ext_map)

  v:add_files(files)
  v:set_as_current_buf()
  v:enable_syntax_highlighting()
  v:create_folds()
  v:disable_line_numbering()
end


return M
