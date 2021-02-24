local history = {}

history._dirs = {}
history._limit = 50

history.add = function(path)
  table.insert(history._dirs, path)
  while #history._dirs > history._limit do
    table.remove(history._dirs)
  end
end

history.get = function()
  return history._dirs
end

return history
