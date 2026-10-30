local state = require "modules.state.state"
local port_utils = require "modules.port.port_utils"
local generate_used_ships = require "modules.port.generate_used_ships"
local item_data = require "modules.data.item_data".item_data
local sailor_data = require "modules.data.sailor_data"
local selectors_fleet = require "modules.state.selectors_fleet"
local map_module = require "modules.map"
local utils = require "modules.utils"

local M = {}

function M.get_time_of_day()
	return state.time_passed % 1440
end

function M.is_day()
	local time_of_day = M.get_time_of_day()
	return time_of_day >= 240 and time_of_day < 1200
end

function M.should_update_world_status()
	return state.time_passed % 240 == 0
end

function M.position_adjacent_to_port(port_id)
	local position = port_utils.get_port_data(port_id).position
	local map = map_module.create()

	local offsets_to_check = {
		{ x = 0, y = -2 },
		{ x = 2, y = 0 },
		{ x = 0, y = 2 },
		{ x = -2, y = 0 },
	}

	for _, offset in ipairs(offsets_to_check) do
		local p = utils.apply_position_delta(position, offset)
		if not map.collision_at(p) then
			return p
		end
	end

	error("No available tile was found adjacent to port")
end

function M.finished_quest(id)
	return utils.includes(state.quests, id)
end

function M.can_afford(cost)
	return state.gold > cost
end

-- TODO reset used ships for a given port after some time has passed
function M.get_used_ships()
	local existing = state.used_ships_at_port[state.port_id]
	if existing then
		return existing
	end

	local used_ships = generate_used_ships(state.port_id)
	state.used_ships_at_port[state.port_id] = used_ships
	return used_ships
end

function M.get_gold()
	return state.gold
end

function M.get_savings()
	return state.savings
end

local CREDIT_LINE = 1000

function M.get_credit_line()
	return math.max(0, CREDIT_LINE - state.debt)
end

function M.get_debt()
	return state.debt
end

function M.get_repay_amount()
	return math.min(state.debt, state.gold)
end

function M.get_at_mosque()
	return state.port_id ~= nil and port_utils.get_port_data(state.port_id).tileset == 2
end

local function secret_item_shop_open()
	local time_of_day = M.get_time_of_day()
	return time_of_day >= 120 and time_of_day < 180
end

function M.get_item_shop_stock()
	if not state.port_id then
		return {}
	end

	local port = port_utils.get_port_data(state.port_id)

	if port.is_supply_port or not port.itemShop then
		return {}
	end

	local items = {}
	for _, id in ipairs(port.itemShop.regular) do
		items[#items + 1] = id
	end

	if port.itemShop.secret and secret_item_shop_open() then
		items[#items + 1] = port.itemShop.secret
	end

	return utils.map(items, function(id)
		return { id = id, name = item_data[id].name }
	end)
end

function M.get_player_items()
	return utils.map(state.items, function(id)
		return { id = id, name = item_data[id].name }
	end)
end

function M.get_player_item(i)
	return item_data[state.items[i]]
end

function M.get_mates()
	return utils.map(state.mates, function(mate)
		local sailor = sailor_data.get_sailor(mate.sailor_id)
		local result = { sailor_id = mate.sailor_id, role = mate.role }
		for k, v in pairs(sailor) do
			result[k] = v
		end
		return result
	end)
end

function M.get_captain(ship_number)
	for _, mate in ipairs(state.mates) do
		if mate.role == ship_number then
			return sailor_data.get_sailor(mate.sailor_id)
		end
	end
	error("No captain was found for the provided ship")
end

function M.get_role_display(role)
	local fleet = selectors_fleet.get_player_fleet()

	if #fleet == 0 then
		return ""
	end

	local flagship_name = fleet[1].name

	if role == nil then
		return "Navigator of " .. flagship_name
	elseif role == "firstMate" then
		return "First Mate of " .. flagship_name
	elseif role == "bookKeeper" then
		return "Bookkeeper of " .. flagship_name
	elseif role == "chiefNavigator" then
		return "Chief Navigator of " .. flagship_name
	elseif role == 1 then
		return "Commodore of " .. flagship_name
	end

	return "Captain of " .. fleet[role].name
end

-- TODO needs to be implemented
function M.get_first_mate_id()
	return "32"
end

function M.is_lisbon()
	return state.port_id == "1"
end

return M
