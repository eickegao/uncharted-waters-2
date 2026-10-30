local state = require "modules.state.state"
local ui_bridge = require "modules.state.ui_bridge"
local selectors = require "modules.state.selectors"
local selectors_fleet = require "modules.state.selectors_fleet"
local ship_data = require "modules.data.ship_data".ship_data
local item_data = require "modules.data.item_data".item_data
local interface_utils = require "modules.interface_utils"
local utils = require "modules.utils"

local M = {}

function M.update_general()
	ui_bridge.set_general({
		port_id = state.port_id,
		building_id = state.building_id,
		time_passed = state.time_passed,
		gold = state.gold,
	})
end

function M.enter_building(building_id)
	state.building_id = building_id
	M.update_general()
end

function M.exit_building(sleep)
	if not sleep then
		state.time_passed = state.time_passed + utils.sample({ 40, 60, 80 })
	else
		state.time_passed = state.time_passed + interface_utils.minutes_until_next_morning(state.time_passed)
	end

	state.building_id = nil

	if state.port then
		if selectors.is_day() then
			state.port.characters().spawn_npcs()
		else
			state.port.characters().despawn_npcs()
		end
	end

	M.update_general()
end

function M.get_available_sailor_id()
	for _, mate in ipairs(state.mates) do
		if mate.role == nil then
			return mate.sailor_id
		end
	end
	return nil
end

function M.add_ship(ship)
	local sailor_id = M.get_available_sailor_id()
	local fleet = selectors_fleet.get_player_fleet()

	if not sailor_id then
		error("Tried to add a ship to fleet despite no available sailors")
	end

	fleet[#fleet + 1] = ship

	for _, mate in ipairs(state.mates) do
		if mate.sailor_id == sailor_id then
			mate.role = #fleet
			break
		end
	end
end

local USED_SHIP_DURABILITY = 0.85

function M.buy_used_ship(used_ship_id, ship_name)
	local used_ships = selectors.get_used_ships()

	for i, used_ship in ipairs(used_ships) do
		if used_ship.id == used_ship_id then
			local data = ship_data[used_ship.ship_id]
			state.gold = state.gold - data.basePrice
			M.add_ship({
				id = used_ship.ship_id,
				name = ship_name,
				crew = 0,
				cargo = {},
				durability = math.floor(data.durability * USED_SHIP_DURABILITY),
			})
			table.remove(used_ships, i)
			break
		end
	end

	M.update_general()
end

M.SELL_SHIP_MODIFIER = 0.5

function M.sell_ship_number(ship_number)
	local fleet = selectors_fleet.get_player_fleet()
	local id = fleet[ship_number].id

	table.remove(fleet, ship_number)

	state.gold = state.gold + ship_data[id].basePrice * M.SELL_SHIP_MODIFIER

	for _, mate in ipairs(state.mates) do
		if mate.role == ship_number then
			mate.role = nil
		elseif type(mate.role) == "number" and mate.role > ship_number then
			-- ships after the one sold move up one step
			mate.role = mate.role - 1
		end
	end

	-- the flagship was sold: the player takes over the next ship
	if #fleet > 0 and ship_number == 1 then
		for _, mate in ipairs(state.mates) do
			if mate.role == 1 then
				mate.role = nil
			end
		end
		state.mates[1].role = 1
	end

	M.update_general()
end

M.provision_cost = {
	water = 0,
	food = 20,
	lumber = 90,
	shot = 120,
}

function M.supply_ship(ship_number, provision, quantity)
	local cargo = state.fleets[1].ships[ship_number].cargo
	local found = false

	for _, item in ipairs(cargo) do
		if item.type == provision then
			item.quantity = item.quantity + quantity
			found = true
			break
		end
	end

	if not found then
		cargo[#cargo + 1] = { type = provision, quantity = quantity }
	end

	state.gold = state.gold - M.provision_cost[provision] * quantity
	M.update_general()
end

function M.complete_quest(id)
	state.quests[#state.quests + 1] = id
end

function M.receive_gold(amount)
	state.gold = state.gold + amount
	M.update_general()
end

function M.check_in()
	ui_bridge.fade(function()
		M.exit_building(true)
	end)
end

function M.exit_building_if_not_lodge()
	if state.building_id ~= "5" then
		M.exit_building()
	end
end

function M.receive_first_ship()
	local id = "6"
	M.add_ship({
		id = id,
		name = "Hermes II",
		crew = 0,
		cargo = {},
		durability = math.floor(ship_data[id].durability * USED_SHIP_DURABILITY),
	})
	M.update_general()
end

function M.recruit_rocco()
	state.mates[#state.mates + 1] = { sailor_id = "32", role = nil }
end

function M.recruit_enrico()
	state.mates[#state.mates + 1] = { sailor_id = "33", role = nil }
end

--[[
  In the original game, no check is done before assigning Rocco and Enrico
  their roles. If you hand them ships, they'll be assigned First Mate and
  Bookkeeper while still remaining as captains (allowing them to captain 2
  ships each). Here, captains keep their ship.
]]
function M.assign_first_roles()
	if state.mates[2] and type(state.mates[2].role) ~= "number" then
		state.mates[2].role = "firstMate"
	end
	if state.mates[3] and type(state.mates[3].role) ~= "number" then
		state.mates[3].role = "bookKeeper"
	end
end

function M.deposit(amount)
	state.savings = state.savings + amount
	state.gold = state.gold - amount
	M.update_general()
end

function M.withdraw(amount)
	state.savings = state.savings - amount
	state.gold = state.gold + amount
	M.update_general()
end

function M.borrow(amount)
	state.debt = state.debt + amount
	state.gold = state.gold + amount
	M.update_general()
end

function M.repay(amount)
	state.debt = state.debt - amount
	state.gold = state.gold - amount
	M.update_general()
end

-- TODO implement luck
function M.pray() end

-- returns how large the donation was, in percent of the player's gold
function M.donate(amount)
	local percent = (amount / state.gold) * 100
	state.gold = state.gold - amount
	M.update_general()
	return percent
end

function M.buy_item(id, gift)
	if not gift then
		local price = item_data[id].price
		if price > state.gold then
			return false
		end
		state.gold = state.gold - price
	end

	state.items[#state.items + 1] = id
	M.update_general()
	return true
end

M.ITEM_SHOP_SELL_MULTIPLIER = 0.5

function M.sell_item(i)
	local id = state.items[i]
	state.gold = state.gold + item_data[id].price * M.ITEM_SHOP_SELL_MULTIPLIER
	table.remove(state.items, i)
	M.update_general()
	return true
end

-- cost in the original game is economy / 20 + 5
M.CREW_COST = 40

function M.recruit_crew(amount)
	local remaining = amount
	local ships = selectors_fleet.get_player_fleet()

	for _, ship in ipairs(ships) do
		if remaining == 0 then
			break
		end

		local assign = math.min(ship_data[ship.id].minimumCrew - ship.crew, remaining)
		ship.crew = ship.crew + assign
		remaining = remaining - assign
	end

	state.gold = state.gold - amount * M.CREW_COST
	M.update_general()
end

return M
