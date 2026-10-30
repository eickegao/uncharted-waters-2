local ui = require "modules.ui.ui"
local widgets = require "modules.ui.widgets"
local colors = require "modules.ui.colors"
local use_building = require "modules.ui.use_building"
local actions_port = require "modules.state.actions_port"
local actions_world = require "modules.state.actions_world"
local selectors_fleet = require "modules.state.selectors_fleet"
local constants = require "modules.constants"

local M = {}

local OPTION_NAMES = { "Sail", "Supply", "Moor" }
local PROVISIONS = { "water", "food", "lumber", "shot" }
local PROVISION_LABELS = { water = "Water", food = "Food", lumber = "Lumber", shot = "Shot" }

local CX = constants.CAMERA_X

local function ship_rows(x, y, columns, on_click_provision)
	for i, ship in ipairs(selectors_fleet.get_player_fleet()) do
		local row_y = y + 32 + (i - 1) * 40
		local load_percent = selectors_fleet.get_load_percent(i)
		local column_x = x + 256

		ui.text(x, row_y, ship.name)

		if columns.crew then
			ui.text(column_x, row_y, ship.crew, { w = 96, align = "right" })
			column_x = column_x + 144
		end

		widgets.progress_bar(column_x, row_y + 9, 96, load_percent)
		column_x = column_x + 96

		for _, provision in ipairs(columns.provisions) do
			ui.text(column_x, row_y, selectors_fleet.get_cargo_quantity(ship, provision), { w = 96, align = "right" })
			if on_click_provision and load_percent < 100 then
				ui.region(column_x, row_y, 96, 32, {
					click = function()
						on_click_provision(i, provision)
					end,
				})
			end
			column_x = column_x + 96
		end
	end
end

local function header(x, y, columns)
	local column_x = x + 256
	ui.text(x, y, "Ship", { font = "r16", color = colors.green_600 })
	if columns.crew then
		ui.text(column_x, y, "Crew", { font = "r16", w = 96, align = "right", color = colors.purple_600 })
		column_x = column_x + 144
	end
	ui.text(column_x, y, "Load", { font = "r16", color = colors.border_red })
	column_x = column_x + 96
	for _, provision in ipairs(columns.provisions) do
		ui.text(column_x, y, PROVISION_LABELS[provision], { font = "r16", w = 96, align = "right", color = colors.blue_600 })
		column_x = column_x + 96
	end
end

local function fleet_table(columns, on_click_provision)
	local count = #selectors_fleet.get_player_fleet()
	local w = 256 + (columns.crew and 144 or 0) + 96 + #columns.provisions * 96
	local x, y = widgets.message_box(CX + 16, 48, w + 32 + 32, 32 + count * 40 + 16 + 32)
	header(x + 16, y + 8, columns)
	ship_rows(x + 16, y + 8, columns, on_click_provision)
end

local function supply_input(ship_number, provision, on_done)
	local cost = actions_port.provision_cost[provision]
	local messages = {
		water = "Water is free. How many barrels should we load?",
		food = "Food will cost us " .. cost .. " gold pieces per barrel. How many barrels will we buy?",
		lumber = "Lumber will cost us " .. cost .. " gold pieces per plank. How many planks will we buy?",
		shot = "Cannonballs will cost us " .. cost .. " gold pieces per barrel. How many barrels will we buy?",
	}

	local box_w, box_h = 400 + 32, 260
	local x, y = widgets.message_box(CX + 80, constants.CAMERA_HEIGHT - 80 - box_h, box_w, box_h)
	local text = ui.text(x + 16, y + 8, messages[provision], { w = 400 - 32, wrap = true })

	widgets.input_number("supply", selectors_fleet.get_available_space(ship_number), function(quantity)
		actions_port.supply_ship(ship_number, provision, quantity)
		on_done()
	end, on_done, {
		position = { x = x + 16, y = y + 8 + ui.text_height(text) + 16 },
		w = 400 - 32,
	})
end

function M.create()
	local b = use_building()
	-- { ship_number, provision } while choosing an amount
	local ship_provision = nil

	local building = {}

	function building.view()
		local option = b.option
		local vendor = { body = "Ahoy there, matey, will ye be shoving off?" }
		local character
		local children
		local dark = false

		local has_fleet = #selectors_fleet.get_player_fleet() > 0
		local options = {}
		for i, name in ipairs(OPTION_NAMES) do
			options[i] = { label = name, value = name, disabled = name == "Moor" or not has_fleet }
		end

		local back = function()
			b.back()
		end

		local menu = function(x, y)
			widgets.building_menu("menu", x, y, options, {
				hidden = option ~= nil,
				on_select = b.select_option,
				on_cancel = back,
			})
		end

		if option == "Sail" then
			if selectors_fleet.has_crew_assigned() then
				local days = selectors_fleet.get_days_provisions_will_last()
				if days > 0 then
					character = {
						body = days >= 10 and ("We can sail for " .. days .. " days. Shall we cast off?")
							or "We won’t be able to sail for long. Shall we cast off anyway?",
						character_id = "32",
						confirm = { yes = actions_world.set_sail, no = back },
					}
				else
					character = {
						body = "We’ll starve if we leave with no provisions!",
						character_id = "32",
						acknowledge = back,
					}
				end
			else
				character = {
					body = "Some ships have no crew assigned. We won’t get anywhere.",
					character_id = "32",
					acknowledge = back,
				}
			end

			children = function()
				fleet_table({ crew = true, provisions = { "water", "food" } })
			end
			dark = true
		end

		if option == "Supply" then
			vendor = nil
			children = function()
				fleet_table({ provisions = PROVISIONS }, function(ship_number, provision)
					ship_provision = { ship_number = ship_number, provision = provision }
				end)

				if ship_provision then
					supply_input(ship_provision.ship_number, ship_provision.provision, function()
						ship_provision = nil
						ui.invalidate()
					end)
				else
					ui.on_key(function(k)
						if ui.CANCEL[k] then
							b.back()
							return true
						end
						return false
					end)
				end
			end
		end

		return {
			building_id = "4",
			vendor = vendor,
			character = character,
			menu = menu,
			children = children,
			dark = dark,
		}
	end

	return building
end

return M
