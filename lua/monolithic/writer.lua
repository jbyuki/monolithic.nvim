local writer = {}
local api = vim.api

function writer.set_buftype(buf)
  api.nvim_buf_set_option(buf, "buftype", "acwrite")
end

function writer.set_bufwritecmds(buf)
  api.nvim_command("autocmd BufWriteCmd <buffer=" .. buf .. [[> lua require"monolithic".save_all(]] .. buf .. ")")
end

function writer.has_changed(filename, lines, startlnum, endlnum) 
  -- check if file exists
  local f = io.open(filename, "r")
  if not f then
    return true
  end
  f:close()

  local lnum = 0
  for line in io.lines(filename) do
    if lines[startlnum+lnum+1] ~= line then
      return true
    end
    lnum = lnum + 1
  end
  return lnum == endlnum - startlnum + 1
end

function writer.write(filename, lines, startlnum, endlnum) 
  local f = io.open(filename, "w")

  local count = 0
  for i=startlnum+1,endlnum do
    f:write(lines[i] .. "\n")
    count = count + string.len(lines[i]) + 1
  end
  f:close()
  return count
end

return writer
