local port_data = require "modules.data.port_data"
local port_extra_data = require "modules.data.port_extra_data"

local M = {}

local regular_ports = port_data.regular_ports
local supply_ports = port_data.supply_ports

local cache = {}

--[[
  Returns the port with the given id ("1" is Lisbon). Supply ports come after
  the regular ports and share a single tilemap and building layout.
]]
function M.get_port_data(id)
	if cache[id] then
		return cache[id]
	end

	local number = tonumber(id) - 1

	if number < 0 or number >= #regular_ports + #supply_ports then
		error("Port does not exist!")
	end

	local is_supply_port = number >= #regular_ports
	local result = {}

	if not is_supply_port then
		for k, v in pairs(regular_ports[number + 1]) do
			result[k] = v
		end
		result.tilemap = number
	else
		for k, v in pairs(supply_ports[number - #regular_ports + 1]) do
			result[k] = v
		end
		result.buildings = port_data.SUPPLY_PORT_BUILDINGS
		result.tileset = port_data.SUPPLY_PORT_TILESET
		result.tilemap = #regular_ports
	end

	result.id = id
	result.is_supply_port = is_supply_port
	cache[id] = result

	return result
end

local port_coordinates

function M.port_adjacent_at(position)
	if not port_coordinates then
		port_coordinates = {}
		for _, port in ipairs(regular_ports) do
			port_coordinates[#port_coordinates + 1] = port.position
		end
		for _, port in ipairs(supply_ports) do
			port_coordinates[#port_coordinates + 1] = port.position
		end
	end

	for i, coordinate in ipairs(port_coordinates) do
		local delta_x = math.abs(coordinate.x - position.x)
		local delta_y = math.abs(coordinate.y - position.y)

		if delta_x <= 2 and delta_y <= 2 and delta_x + delta_y <= 3 then
			return tostring(i)
		end
	end

	return nil
end

function M.get_region_or_if_supply_port(port_id)
	local port = M.get_port_data(port_id)

	if not port.is_supply_port then
		return port_extra_data.markets[port.marketId]
	end

	return "Supply port"
end

return M
