local widgets = require "modules.ui.widgets"
local use_building = require "modules.ui.use_building"
local actions_port = require "modules.state.actions_port"
local selectors = require "modules.state.selectors"
local selectors_fleet = require "modules.state.selectors_fleet"
local ship_data = require "modules.data.ship_data".ship_data
local utils = require "modules.utils"

local M = {}

local OPTIONS = {
	{ label = "New Ship", value = "New Ship", disabled = true },
	{ label = "Used Ship", value = "Used Ship" },
	{ label = "Repair", value = "Repair" },
	{ label = "Sell", value = "Sell" },
	{ label = "Remodel", value = "Remodel", disabled = true },
	{ label = "Invest", value = "Invest", disabled = true },
}

function M.create()
	local b = use_building()
	local used_ship_id = nil
	local selected_ship_number_to_sell = nil

	local building = {}

	function building.view()
		local option, step = b.option, b.step
		local vendor = { body = "What brings you to this shipyard?" }
		local menu2
		local children

		local back = function()
			b.back()
		end

		local menu = function(x, y)
			widgets.building_menu("menu", x, y, OPTIONS, {
				hidden = option ~= nil,
				on_select = b.select_option,
				on_cancel = back,
			})
		end

		if option == "Used Ship" then
			local used_ships = selectors.get_used_ships()

			menu2 = function(x, y)
				widgets.building_menu("menu2", x, y, utils.map(used_ships, function(used_ship)
					return { label = ship_data[used_ship.ship_id].name, value = used_ship.id }
				end), {
					title = "Ship Model",
					level2 = true,
					hidden = step ~= 0,
					on_select = function(id)
						used_ship_id = id
						b.next()
					end,
					on_cancel = back,
				})
			end

			local used_ship
			for _, s in ipairs(used_ships) do
				if s.id == used_ship_id then
					used_ship = s
				end
			end

			if used_ship then
				local data = ship_data[used_ship.ship_id]
				local function cancel_purchase()
					used_ship_id = nil
					b.back(3)
				end

				children = function()
					widgets.ship_box(used_ship.ship_id)
				end

				if step == 1 then
					vendor = { body = data.description, acknowledge = b.next }
				elseif step == 2 then
					vendor = {
						body = "I’d sell this ship for " .. data.basePrice .. " gold pieces. What do ye say?",
						confirm = {
							yes = b.next,
							no = function()
								used_ship_id = nil
								b.back(2)
							end,
						},
					}
				elseif step == 3 then
					if not selectors.can_afford(data.basePrice) then
						vendor = { body = "I’m afraid you don’t have enough gold.", acknowledge = cancel_purchase }
					elseif not actions_port.get_available_sailor_id() then
						-- the original game offers you to swap ship
						vendor = {
							body = "You don’t have a sailor available to captain this ship.",
							acknowledge = cancel_purchase,
						}
					else
						vendor = { body = "All right, it’s yers. Time to name yer ship." }
						children = function()
							widgets.ship_box(used_ship.ship_id)
							widgets.input_name("ship_name", function(name)
								actions_port.buy_used_ship(used_ship.id, name)
								cancel_purchase()
							end, cancel_purchase)
						end
					end
				end
			end
		end

		if option == "Repair" then
			vendor = { body = "Your fleet’s already in tiptop shape, matey!", acknowledge = back }
		end

		if option == "Sell" then
			local fleet = selectors_fleet.get_player_fleet()

			if #fleet <= 1 then
				if step == 0 then
					vendor = {
						body = #fleet == 1 and "We only have the flag ship." or "You don’t have any ships.",
						acknowledge = back,
					}
				end
			else
				menu2 = function(x, y)
					widgets.building_menu("menu2", x, y, utils.map(fleet, function(ship, i)
						return { label = ship.name, value = i }
					end), {
						title = "Your Ships",
						level2 = true,
						hidden = step ~= 0,
						on_select = function(i)
							selected_ship_number_to_sell = i
							b.next()
						end,
						on_cancel = back,
					})
				end

				if step == 0 then
					vendor = { body = "Which one is for sale?" }
				end

				if step == 1 and selected_ship_number_to_sell then
					--[[
					  TODO As you currently cannot modify ships and there are no hull
					  types, we can just use the defaults for the ship model in question.
					]]
					local ship = selectors_fleet.get_player_fleet_ship(selected_ship_number_to_sell)
					vendor = {
						body = "For this ship, I’ll give you "
							.. ship_data[ship.id].basePrice * actions_port.SELL_SHIP_MODIFIER
							.. " gold pieces. OK?",
						confirm = {
							yes = function()
								actions_port.sell_ship_number(selected_ship_number_to_sell)
								selected_ship_number_to_sell = nil
								b.back()
							end,
							no = function()
								selected_ship_number_to_sell = nil
								b.back()
							end,
						},
					}
					children = function()
						widgets.ship_box(ship.id, ship.name)
					end
				end
			end
		end

		return {
			building_id = "3",
			vendor = vendor,
			menu = menu,
			menu2 = menu2,
			children = children,
		}
	end

	return building
end

return M
