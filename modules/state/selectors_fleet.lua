local state = require "modules.state.state"
local ship_data = require "modules.data.ship_data".ship_data

local M = {}

function M.get_player_fleet()
	return state.fleets[1].ships
end

function M.get_player_fleet_ship(ship_number)
	return state.fleets[1].ships[ship_number]
end

local function cargo_total(ship)
	local total = 0
	for _, cargo in ipairs(ship.cargo) do
		total = total + cargo.quantity
	end
	return total
end

function M.get_available_space(ship_number)
	local ship = state.fleets[1].ships[ship_number]
	local data = ship_data[ship.id]
	return data.capacity - data.minimumCrew - cargo_total(ship)
end

function M.get_load_percent(ship_number)
	local ship = state.fleets[1].ships[ship_number]
	local data = ship_data[ship.id]
	return ((cargo_total(ship) + data.minimumCrew) / data.capacity) * 100
end

function M.has_crew_assigned()
	for _, ship in ipairs(state.fleets[1].ships) do
		if ship.crew <= 0 then
			return false
		end
	end
	return true
end

function M.get_cargo_quantity(ship, cargo_type)
	for _, cargo in ipairs(ship.cargo) do
		if cargo.type == cargo_type then
			return cargo.quantity
		end
	end
	return 0
end

function M.get_days_provisions_will_last()
	local total_crew = 0
	local total_water = 0
	local total_food = 0

	for _, ship in ipairs(M.get_player_fleet()) do
		total_crew = total_crew + ship.crew
		total_water = total_water + M.get_cargo_quantity(ship, "water")
		total_food = total_food + M.get_cargo_quantity(ship, "food")
	end

	if total_crew == 0 then
		return 0
	end

	return math.floor(math.min(total_water / total_crew, total_food / total_crew) * 10)
end

function M.get_crew_needed()
	local count = 0
	for _, ship in ipairs(M.get_player_fleet()) do
		count = count + ship_data[ship.id].minimumCrew - ship.crew
	end
	return count
end

return M
