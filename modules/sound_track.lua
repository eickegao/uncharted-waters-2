-- Which music track plays where. Track names are sound components in main/music.go
local port_utils = require "modules.port.port_utils"
local utils = require "modules.utils"

local M = {}

function M.get_track(port_id, building_id)
	if port_id == nil then
		return "theme_of_joao"
	end

	if building_id == "2" then
		return "fiddlers_green"
	end

	if building_id == "6" then
		return "royal_palace"
	end

	local region = port_utils.get_region_or_if_supply_port(port_id)

	if region == "Supply port" then
		return "supply_port"
	end

	if utils.includes({ "Ottoman Empire", "Middle East" }, region) then
		return "moslem_dance"
	end

	if utils.includes({ "North Africa", "East Africa", "West Africa", "Central America", "South America" }, region) then
		return "empty_eyes"
	end

	if region == "India" then
		return "the_mahout"
	end

	if utils.includes({ "Southeast Asia", "Far East" }, region) then
		return "land_of_luxury"
	end

	return "mast_in_the_mist"
end

return M
