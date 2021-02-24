local api = vim.api
local action = {}

function action.jump_to_file(view)
  local row, col = unpack(api.nvim_win_get_cursor(0))
  local filename, filerow = view:get_location_at(row)
  assert(filename, "No file region found under cursor")

  -- not sure if it's the best way to open a file but it works
  api.nvim_command("edit " .. filename)
  api.nvim_win_set_cursor(0, {filerow, col})
end

return action
