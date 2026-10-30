local port_utils = require "modules.port.port_utils"
local shipyards_to_ships = require "modules.data.port_shipyard_data".shipyards_to_ships
local utils = require "modules.utils"

-- returns a list of { id = unique id, ship_id = ship model }
local function generate_used_ships(port_id)
	local port = port_utils.get_port_data(port_id)

	if port.is_supply_port then
		error("Supply port was provided")
	end

	local industry = port.industry
	local pool = {}

	for _, entry in ipairs(shipyards_to_ships[port.industryId]) do
		if industry >= entry.industryRequirement then
			pool[#pool + 1] = entry.shipId
		end
	end

	local amount = 2
	if industry > 800 then
		amount = utils.random(2, 8)
	elseif industry > 600 then
		amount = utils.random(2, 6)
	elseif industry > 400 then
		amount = utils.random(2, 4)
	end

	local used_ships = {}
	for _ = 1, amount do
		used_ships[#used_ships + 1] = { id = utils.generate_id(), ship_id = utils.sample(pool) }
	end

	return used_ships
end

return generate_used_ships
