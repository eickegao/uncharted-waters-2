local widgets = require "modules.ui.widgets"
local use_building = require "modules.ui.use_building"
local actions_port = require "modules.state.actions_port"
local selectors = require "modules.state.selectors"
local item_data = require "modules.data.item_data".item_data
local utils = require "modules.utils"

local M = {}

local OPTIONS = {
	{ label = "Buy", value = "Buy" },
	{ label = "Sell", value = "Sell" },
}

-- TODO haggling, items that cannot be sold, equipment limit
function M.create()
	local b = use_building()
	local has_bought = false
	local selected_item_id = nil
	local has_sold = false
	local selected_item_i = nil

	local building = {}

	function building.view()
		local option, step = b.option, b.step
		local vendor = { body = "May I help you?" }
		local menu2
		local children

		local back = function()
			b.back()
		end

		local menu = function(x, y)
			widgets.building_menu("menu", x, y, OPTIONS, {
				hidden = option ~= nil or step == -1,
				on_select = b.select_option,
				on_cancel = back,
			})
		end

		if option == "Buy" then
			if selectors.get_gold() > 0 then
				vendor = {
					body = not has_bought and "I’m sure you’ll find something you like."
						or "Are you interested in anything else?",
				}
				menu2 = function(x, y)
					widgets.building_menu("menu2", x, y, utils.map(selectors.get_item_shop_stock(), function(item)
						return { label = item.name, value = item.id }
					end), {
						title = "Item",
						level2 = true,
						hidden = step ~= 0,
						on_select = function(id)
							selected_item_id = id
							b.next()
						end,
						on_cancel = back,
					})
				end
			else
				vendor = { body = "It seems you have no gold.", acknowledge = back }
			end

			if selected_item_id then
				if step == 1 then
					local item = item_data[selected_item_id]
					vendor = {
						body = "The " .. item.name .. " will cost you " .. item.price .. " gold pieces.",
						confirm = {
							yes = function()
								if not actions_port.buy_item(selected_item_id) then
									b.next()
									return
								end
								has_bought = true
								if selectors.get_gold() > 0 then
									b.back()
								else
									b.reset()
								end
							end,
							no = function()
								selected_item_id = nil
								b.back()
							end,
						},
					}
					children = function()
						widgets.item_box(item)
					end
				elseif step == 2 then
					vendor = {
						body = "I’m afraid you don’t have enough gold.",
						acknowledge = function()
							b.back(2)
						end,
					}
				end
			end
		end

		if option == "Sell" then
			local items = selectors.get_player_items()

			if #items == 0 then
				vendor = { body = "You don’t have any items.", acknowledge = back }
			else
				vendor = { body = not has_sold and "What would you like to sell?" or "What else can you sell me?" }
				menu2 = function(x, y)
					widgets.building_menu("menu2", x, y, utils.map(items, function(item, i)
						return { label = item.name, value = i }
					end), {
						title = "Item",
						level2 = true,
						hidden = step ~= 0,
						on_select = function(i)
							selected_item_i = i
							b.next()
						end,
						on_cancel = back,
					})
				end
			end

			if selected_item_i and step == 1 then
				local item = selectors.get_player_item(selected_item_i)
				vendor = {
					body = "I’d like to take that "
						.. item.name
						.. " off your hands. I’ll take it for "
						.. item.price * actions_port.ITEM_SHOP_SELL_MULTIPLIER
						.. " gold pieces.",
					confirm = {
						yes = function()
							actions_port.sell_item(selected_item_i)
							has_sold = true
							selected_item_i = nil
							if #selectors.get_player_items() > 0 then
								b.back()
							else
								b.reset()
							end
						end,
						no = function()
							selected_item_i = nil
							b.back()
						end,
					},
				}
				children = function()
					widgets.item_box(item)
				end
			end
		end

		return {
			building_id = "10",
			vendor = vendor,
			menu = menu,
			menu2 = menu2,
			children = children,
		}
	end

	return building
end

return M
