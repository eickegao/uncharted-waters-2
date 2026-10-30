-- Binary data shipped as custom resources (see [project] custom_resources)
local M = {}

local paths = {
	world_tilemap = "/assets/data/world_tilemap.dat",
	port_tilemaps = "/assets/data/port_tilemaps.dat",
	winds_current = "/assets/data/winds_current.dat",
}

local loaded = {}

-- replaced in tests
M.loader = function(path)
	return sys.load_resource(path)
end

function M.data(id)
	if not loaded[id] then
		local data = M.loader(paths[id])
		if not data then
			error("Failed loading " .. paths[id])
		end
		loaded[id] = data
	end
	return loaded[id]
end

-- zero-based, returns nil when out of range
function M.byte(id, index)
	if index < 0 then
		return nil
	end
	return string.byte(M.data(id), index + 1)
end

function M.set(id, data)
	loaded[id] = data
end

return M
