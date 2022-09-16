##monolithic
@implement+=
function M.open()
  @glob_all_files_in_cwd
  @check_max_files_limit
  
  @create_scratch_buffer

  @append_all_files_to_buffer
  @stop_timer_2

  @get_filename_and_line_of_current
  @get_file_filetype
  @create_float_window
  @set_window_filetype
  @set_highlights_titles
  @setup_folds
  @setup_mappings
  @setup_highlighter
  @close_float_on_leave
  @goto_filename_and_line_of_current
end

@script_variables+=
local open_dir

@implement+=
function open_dir(path, files)
  @check_that_files_is_below_maximum
  local dir = vim.loop.fs_opendir(path, nil, 50)
  if dir then
    while true do
      local entries = dir:readdir()
      if not entries then
        break
      end

      @check_that_files_is_below_maximum

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

@script_variables+=
local max_search = 10000

@set_options+=
if opts.max_search then
  max_search = opts.max_search
end

@check_that_files_is_below_maximum+=
if #files > max_search then
  return
end

@glob_all_files_in_cwd+=
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

@create_scratch_buffer+=
local buf = vim.api.nvim_create_buf(false, true)

@append_all_files_to_buffer+=
for _, fn in ipairs(files) do
  @load_file_content
  @append_file_header
  @append_file_content_to_buf
end

@load_file_content+=
local f = io.open(fn)
local lines = {}
if f then
  local content = f:read("*a")
  lines = vim.split(content, "\n")
end

@script_variables+=
local titles_pos = {}
local titles = {}

@append_all_files_to_buffer-=
titles_pos = {}
titles = {}

@append_file_header+=
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

@append_file_content_to_buf+=
vim.api.nvim_buf_set_lines(buf, -1, -1, true, lines)

@script_variables+=
local perc_width = 0.8
local perc_height = 0.8
local win 

@create_float_window+=
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

@set_highlights_titles+=
local ns_id = vim.api.nvim_create_namespace("")
for _, pos in ipairs(titles_pos) do
  local line = vim.api.nvim_buf_get_lines(buf, pos, pos+1, true)[1]
  vim.api.nvim_buf_set_extmark(buf, ns_id, pos, 0, {
    end_col = string.len(line),
    hl_group = "NonText",
  })
end

@get_file_filetype+=
local ft = vim.api.nvim_buf_get_option(0, "ft")

@set_window_filetype+=
-- vim.api.nvim_buf_set_option(0, "ft", ft)

@setup_folds+=
for i = 1,#titles_pos do
  if i+1 <= #titles_pos then
    @create_fold_until_next
  else
    @create_fold_until_eof
  end
end

@create_fold_until_next+=
vim.api.nvim_command((titles_pos[i]+1) .. "," .. (titles_pos[i+1]) .. "fo")

@create_fold_until_eof+=
local lcount = vim.api.nvim_buf_line_count(buf)
vim.api.nvim_command((titles_pos[i]+1) .. "," .. (lcount) .. "fo")

@close_float_on_leave+=
vim.api.nvim_command("autocmd WinLeave * ++once lua vim.api.nvim_win_close(" .. win .. ", false)")

@script_variables+=
local mappings = {}

@set_default_mappings+=
mappings["<leader>s"] = M.navigate

@implement+=
function M.do_mapping(id)
  local f = mappings_lookup[id]
  f()
end

@script_variables+=
local mappings_lookup = {}

@setup_mappings+=
local mapping_id = 1
for lhs, rhs in pairs(mappings) do
  vim.api.nvim_buf_set_keymap(buf, "n", lhs, [[<cmd>:lua require"monolithic".do_mapping(]] .. mapping_id .. [[)<CR>]], { noremap = true })
  mappings_lookup[mapping_id] = rhs
  mapping_id = mapping_id + 1
end

@implement+=
function M.navigate()
  @get_cursor_pos
  @close_float_window

  @see_in_which_file_to_jump
  @open_jump_file
  @goto_line_in_jump_file
end

@get_cursor_pos+=
local row, col = unpack(vim.api.nvim_win_get_cursor(0))

@close_float_window+=
vim.api.nvim_win_close(win, false)

@see_in_which_file_to_jump+=
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

@open_jump_file+=
local fn = titles[selected]
if vim.api.nvim_buf_get_name(0) ~= vim.fn.fnamemodify(fn, ":p") then
  vim.api.nvim_command("e " .. fn)
end

@goto_line_in_jump_file+=
local lnum = row - titles_pos[selected]
vim.api.nvim_win_set_cursor(0, {lnum - 1, 0})

@get_filename_and_line_of_current+=
local curfn = vim.fn.expand("%")
if curfn:sub(1,1) ~= "." then
  curfn = "./" .. curfn 
end
local currow, _ = unpack(vim.api.nvim_win_get_cursor(0))

@goto_filename_and_line_of_current+=
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

@setup_highlighter+=
local has_highlighter = false
if not has_highlighter then
  @setup_treesitter_highlighter
end

if not has_highlighter then
  @setup_regex_highlighter
end

@setup_treesitter_highlighter+=
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

@setup_regex_highlighter+=
vim.api.nvim_buf_set_option(buf, "syntax", ft)

@script_variables+=
local max_files = 100

@set_options+=
if opts.max_files then
  max_files = opts.max_files
end

@check_max_files_limit+=
if #files > max_files then
  vim.api.nvim_echo({{("ERROR(monolithic.nvim): Too many files (limit at %d)! Found %d. Configure limit with max_files settings"):format(max_files, #files), "ErrorMsg"}}, true, {})
  return
end
