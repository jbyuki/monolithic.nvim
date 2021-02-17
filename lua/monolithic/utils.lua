local utils = {}

function utils.make_set_from_keys(list)
	local set = {}
	for _,k in ipairs(list) do
		set[k] = true
	end
	return set
end

function utils.group_by_key(keys, values)
	assert(#keys == #values)
	local grouped = {}
	for i=1,#keys do
		local key = keys[i]
		local val = values[i]

		grouped[key] = grouped[key] or {}
		table.insert(grouped[key], val)
	end
	return grouped
end

return utils
