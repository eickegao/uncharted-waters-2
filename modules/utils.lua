local M = {}

M.directions = { "n", "e", "s", "w" }

function M.sample(values)
	return values[math.random(1, #values)]
end

-- inclusive on both ends
function M.random(min, max)
	return math.random(math.ceil(min), math.floor(max))
end

function M.apply_position_delta(p1, p2)
	return { x = p1.x + p2.x, y = p1.y + p2.y }
end

function M.get_position_delta(p1, p2)
	return { x = p1.x - p2.x, y = p1.y - p2.y }
end

local id_counter = 0

function M.generate_id()
	id_counter = id_counter + 1
	return string.format("%d-%d", os.time(), id_counter)
end

function M.includes(list, value)
	for _, v in ipairs(list) do
		if v == value then
			return true
		end
	end
	return false
end

function M.find_index(list, predicate)
	for i, v in ipairs(list) do
		if predicate(v, i) then
			return i
		end
	end
	return nil
end

function M.map(list, fn)
	local result = {}
	for i, v in ipairs(list) do
		result[i] = fn(v, i)
	end
	return result
end

function M.filter(list, fn)
	local result = {}
	for i, v in ipairs(list) do
		if fn(v, i) then
			result[#result + 1] = v
		end
	end
	return result
end

function M.deep_copy(value)
	if type(value) ~= "table" then
		return value
	end
	local result = {}
	for k, v in pairs(value) do
		result[k] = M.deep_copy(v)
	end
	return result
end

-- keys of tables such as { ["1"] = ..., ["12"] = ... } in numeric order
function M.sorted_keys(t)
	local keys = {}
	for k in pairs(t) do
		keys[#keys + 1] = k
	end
	table.sort(keys, function(a, b)
		local na, nb = tonumber(a), tonumber(b)
		if na and nb then
			return na < nb
		end
		return tostring(a) < tostring(b)
	end)
	return keys
end

return M
