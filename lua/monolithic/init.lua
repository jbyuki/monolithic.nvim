-- Generated using ntangle.nvim
local M = {}
local search_patterns = { "**/*" }

local excluded_patterns = {}

local titles_pos = {}
local titles = {}

local perc_width = 0.8
local perc_height = 0.8
local win 

local mappings = {}

local mappings_lookup = {}

local max_files = 20

function M.open()
  local files_dict = {}
  for _, pat in ipairs(search_patterns) do
    local ex = vim.split(vim.fn.glob(pat), "\n")
    for _, f in ipairs(ex) do
      files_dict[f] = true
    end

  end

  local files = {}
  for file, _ in pairs(files_dict) do
    table.insert(files, file)
  end

  local excluded = {}
  for _, pat in ipairs(excluded_patterns) do
    local ex = vim.split(vim.fn.glob(pat), "\n")
    for _, f in ipairs(ex) do
      excluded[f] = true
    end

  end

  files = vim.tbl_filter(function(x) return not excluded[x] end, files)

  files = vim.tbl_filter(function(x) return vim.fn.isdirectory(x) == 0 end, files)

  if max_files ~= -1 then
    if max_files > #files then
      vim.api.nvim_echo({{("ERROR(monolithic.nvim): Too many files! Found %d. Configure limit with max_files settings"):format(#files), "ErrorMsg"}}, true, {})
      return
    end
  end

  
  local buf = vim.api.nvim_create_buf(false, true)

  titles_pos = {}
  titles = {}

  for _, fn in ipairs(files) do
    local lines = {}
    for line in io.lines(fn) do
      table.insert(lines, line)
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
      if ts_parsers.has_parser(lang) then
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
  vim.validate {
    ["opts.excluded_pat"] = { opts.excluded_pat, 't', true },
    ["opts.mappings"] = { opts.mappings, 't', true },
  }

  vim.validate {
    ["opts.perc_width"] = { opts.perc_width, 'n', true },
    ["opts.perc_height"] = { opts.perc_height, 'n', true },
  }

  if opts.search_pat then
    search_patterns = opts.search_pat
  end

  if opts.max_files then
    max_files = opts.max_files
  end

  if opts.mappings then
    mappings = opts.mappings
  end

  if opts.excluded_pat then
    excluded_patterns = opts.excluded_pat
  end

  if opts.perc_width then
    perc_width = opts.perc_width
  end

  if opts.perc_height then
    perc_height = opts.perc_height
  end
end

mappings["<leader>s"] = M.navigate

return M
