local port_utils = require "modules.port.port_utils"

local function create_building(port_id)
	local building = {}

	function building.get(id)
		return port_utils.get_port_data(port_id).buildings[id]
	end

	function building.at(position)
		for id, location in pairs(port_utils.get_port_data(port_id).buildings) do
			if location.x == position.x and location.y == position.y then
				return tostring(id)
			end
		end
		return nil
	end

	return building
end

return create_building
