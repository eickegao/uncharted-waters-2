local ship_data_module = require "modules.data.ship_data"
local world_utils = require "modules.world.world_utils"

--[[
  In contrast to the original game, we do not round down during each step of
  the calculation.

  An oversight in the game is that your ship will continue moving faster as
  the headwind gets stronger. Also, if wind speed is 0, wind direction still
  matters when calculating the speed of a ship with oars.

  Consider imposing a heavier penalty sailing into the wind, if the gameplay
  doesn't get tedious.

  It's also worth looking into requiring higher sailor stats to handle
  end-game ships so mid-tier ships have their uses outside exploration.
]]
local function get_ship_speed(ship, sailor, heading, wind)
	local data = ship_data_module.ship_data[ship.id]
	local direction_delta = world_utils.get_heading_wind_delta(heading, wind.direction)
	local ship_wind_factor = ship_data_module.ship_wind_factor_map[data.sailType][direction_delta + 1]

	-- TODO if wind speed = 0 as a mechanic is introduced, ships with oars should count as having 2 wind speed
	local wind_speed = world_utils.has_oars(ship.id) and math.max(3, wind.speed) or wind.speed

	local propulsion_factor = (data.power * ship_wind_factor * wind_speed) / 150

	-- in the absence of game features, we'll assume the entire crew is assigned to navigation
	local nav_crew = ship.crew
	local navigation_crew_factor = math.min(1, nav_crew / data.minimumCrew)

	local capacity_used = ship.crew
	for _, cargo in ipairs(ship.cargo) do
		capacity_used = capacity_used + cargo.quantity
	end
	local cargo_factor = math.min(1.5, 1.8 - capacity_used / data.capacity)

	local navigation_level_factor = (10 + sailor.navigationLevel) / 10

	local is_headwind_or_side_headwind = direction_delta >= 3
	local tacking_factor = is_headwind_or_side_headwind and data.tacking / 100 or 1

	local base_speed = math.min(
		30,
		propulsion_factor * navigation_crew_factor * cargo_factor * navigation_level_factor
	)

	return (base_speed * tacking_factor * sailor.stats.seamanship) / 75
end

return get_ship_speed
