-- Generated using ntangle.nvim
local M = {}
local open_dir

local max_search = 10000

local titles_pos = {}
local titles = {}

local perc_width = 0.8
local perc_height = 0.8
local win 

local mappings = {}

local mappings_lookup = {}

local max_files = 100

local valid_ext = {
  ["lua"] = true,
  ["py"] = true,
  ["cpp"] = true,
  ["c"] = true,
  ["h"] = true,
  ["hpp"] = true,
}

local exclude_dirs = {
  [".git"] = true,
  ["__pycache__"] = true,
}

function M.open()
  local files = {}
  open_dir(".", files)

  if #files > max_search then
    vim.api.nvim_echo({{("ERROR(monolithic.nvim): Too many files searched (limit at %d)! Found %d. Configure limit with max_search settings"):format(max_search, #files), "ErrorMsg"}}, true, {})
    return
  end

  files = vim.tbl_filter(function(fn) 
    local ext = fn:match("%.([^.]*)$")
    return valid_ext[ext] end, 
  files)

  if #files > max_files then
    vim.api.nvim_echo({{("ERROR(monolithic.nvim): Too many files (limit at %d)! Found %d. Configure limit with max_files settings"):format(max_files, #files), "ErrorMsg"}}, true, {})
    return
  end
  
  local buf = vim.api.nvim_create_buf(false, true)


  titles_pos = {}
  titles = {}

  for _, fn in ipairs(files) do
    local f = io.open(fn)
    local lines = {}
    if f then
      local content = f:read("*a")
      lines = vim.split(content, "\n")
    end

    local lcount = vim.api.nvim_buf_line_count(buf)
    local title = "-- " .. fn .. " ----------------"
    if lcount == 1 then
      vim.api.nvim_buf_set_lines(buf, 0, 1, true, { title })
      table.insert(titles_pos, 0)
    else
      vim.api.nvim_buf_set_lines(buf, -1, -1, true, { title })
      table.insert(titles_pos, lcount)
    end

    table.insert(titles, fn)

    vim.api.nvim_buf_set_lines(buf, -1, -1, true, lines)

  end


  local curfn = vim.fn.expand("%")
  curfn = curfn:gsub('\\', '/')
  if curfn:sub(1,1) ~= "." then
    curfn = "./" .. curfn 
  end
  local currow, _ = unpack(vim.api.nvim_win_get_cursor(0))

  local ft = vim.api.nvim_buf_get_option(0, "ft")

  local width = vim.o.columns
  local height = vim.o.lines

  local win_width = math.floor(width * perc_width)
  local win_height = math.floor(height * perc_height)

  win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = win_width,
    height = win_height,
    col = math.floor((width - win_width)/2),
    row = math.floor((height - win_height)/2),
    style = "minimal",
    border = "single",
  })

  -- vim.api.nvim_buf_set_option(0, "ft", ft)

  local ns_id = vim.api.nvim_create_namespace("")
  for _, pos in ipairs(titles_pos) do
    local line = vim.api.nvim_buf_get_lines(buf, pos, pos+1, true)[1]
    vim.api.nvim_buf_set_extmark(buf, ns_id, pos, 0, {
      end_col = string.len(line),
      hl_group = "NonText",
    })
  end

  for i = 1,#titles_pos do
    if i+1 <= #titles_pos then
      vim.api.nvim_command((titles_pos[i]+1) .. "," .. (titles_pos[i+1]) .. "fo")

    else
      local lcount = vim.api.nvim_buf_line_count(buf)
      vim.api.nvim_command((titles_pos[i]+1) .. "," .. (lcount) .. "fo")

    end
  end

  local mapping_id = 1
  for lhs, rhs in pairs(mappings) do
    vim.api.nvim_buf_set_keymap(buf, "n", lhs, [[<cmd>:lua require"monolithic".do_mapping(]] .. mapping_id .. [[)<CR>]], { noremap = true })
    mappings_lookup[mapping_id] = rhs
    mapping_id = mapping_id + 1
  end

  local has_highlighter = false
  if not has_highlighter then
    local has_ts = pcall(require, 'nvim-treesitter')
    if has_ts then
      local ts_highlight = require'nvim-treesitter.highlight'
      local ts_parsers = require'nvim-treesitter.parsers'
      
      local lang = ts_parsers.ft_to_lang(ft)
      if vim.treesitter.get_parser(buf, lang) then
        ts_highlight.attach(buf, lang)
        has_highlighter = true
      end
    end

  end

  if not has_highlighter then
    vim.api.nvim_buf_set_option(buf, "syntax", ft)

  end

  vim.api.nvim_command("autocmd WinLeave * ++once lua vim.api.nvim_win_close(" .. win .. ", false)")

  local cur
  for i=1,#titles do
    if titles[i] == curfn then
      cur = i
      break
    end
  end

  if cur then
    local lnum = titles_pos[cur] + currow + 1
    vim.api.nvim_win_set_cursor(0, { lnum, 0 })
    vim.api.nvim_command("normal zo")
  end

end

function open_dir(path, files)
  if #files > max_search then
    return
  end

  local dir = vim.loop.fs_opendir(path, nil, 50)
  if dir then
    while true do
      local entries = dir:readdir()
      if not entries then
        break
      end

      if #files > max_search then
        return
      end


      for _, entry in ipairs(entries) do
        if entry["type"] == "directory" then
          local dir_name = entry["name"]
          if not exclude_dirs[dir_name] then
            open_dir(path .. "/" .. dir_name, files)
          end
        else
          table.insert(files, path .. "/" .. entry["name"])
        end
      end
    end
    dir:closedir()
  end
end

function M.do_mapping(id)
  local f = mappings_lookup[id]
  f()
end

function M.navigate()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))

  vim.api.nvim_win_close(win, false)


  local selected
  for i=1,#titles_pos do
    if i+1 > #titles_pos then
      selected = i
      break
    end

    if titles_pos[i+1]+1 > row then
      selected = i
      break
    end
  end

  local fn = titles[selected]
  if vim.api.nvim_buf_get_name(0) ~= vim.fn.fnamemodify(fn, ":p") then
    vim.api.nvim_command("e " .. fn)
  end

  local lnum = row - titles_pos[selected]
  vim.api.nvim_win_set_cursor(0, {lnum - 1, 0})

end

function M.setup(opts)
  opts = opts or {}
  -- @deprecation_warnings
  vim.validate {
    ["opts.mappings"] = { opts.mappings, 't', true },
  }

  vim.validate {
    ["opts.perc_width"] = { opts.perc_width, 'n', true },
    ["opts.perc_height"] = { opts.perc_height, 'n', true },
  }

  vim.validate {
    ["opts.valid_ext"] = { opts.valid_ext, 't', true },
  }

  vim.validate {
    ["opts.exclude_dirs"] = { opts.exclude_dirs, 't', true },
  }

  if opts.max_search then
    max_search = opts.max_search
  end

  if opts.max_files then
    max_files = opts.max_files
  end

  if opts.mappings then
    mappings = opts.mappings
  end

  if opts.perc_width then
    perc_width = opts.perc_width
  end

  if opts.perc_height then
    perc_height = opts.perc_height
  end

  if opts.valid_ext then
    valid_ext = {}
    for _, v in ipairs(opts.valid_ext) do
      valid_ext[v] = true
    end
  end

  if opts.exclude_dirs then
    exclude_dirs = {}
    for _, v in ipairs(opts.exclude_dirs) do
      exclude_dirs[v] = true
    end
  end
end

mappings["<leader>s"] = M.navigate

return M
