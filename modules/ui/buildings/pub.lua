local widgets = require "modules.ui.widgets"
local use_building = require "modules.ui.use_building"
local actions_port = require "modules.state.actions_port"
local selectors = require "modules.state.selectors"
local selectors_fleet = require "modules.state.selectors_fleet"

local M = {}

local OPTION_NAMES = { "Recruit Crew", "Dismiss Crew", "Treat", "Meet", "Waitress", "Gamble" }

function M.create()
	local b = use_building()

	local building = {}

	function building.view()
		local option, step = b.option, b.step
		local vendor = { body = "Hey sailor, you’ll like our wine!" }
		local character

		-- Carlotta greets instead of the regular vendor
		if selectors.is_lisbon() then
			vendor = nil
		end

		local has_fleet = #selectors_fleet.get_player_fleet() > 0
		local options = {}
		for i, name in ipairs(OPTION_NAMES) do
			options[i] = { label = name, value = name, disabled = name ~= "Recruit Crew" or not has_fleet }
		end

		local menu = function(x, y)
			widgets.building_menu("menu", x, y, options, {
				hidden = option ~= nil or step == -1,
				on_select = b.select_option,
				on_cancel = function()
					b.back()
				end,
			})
		end

		local back = function()
			b.back()
		end

		if option == "Recruit Crew" then
			vendor = nil
			local gold = selectors.get_gold()
			local crew_needed = selectors_fleet.get_crew_needed()
			local first_mate = selectors.get_first_mate_id()

			if step == 0 then
				if crew_needed == 0 then
					character = { body = "We have enough men in our crew.", character_id = first_mate, acknowledge = back }
				elseif gold < actions_port.CREW_COST then
					character = { body = "We don’t have enough gold.", character_id = first_mate, acknowledge = back }
				else
					character = {
						body = "Shall we recruit some men for our crew?",
						character_id = first_mate,
						confirm = { yes = b.next, no = back },
					}
				end
			elseif step == 1 then
				character = {
					body = "Hey! Do any of you tough sailors want to join our crew?",
					character_id = "1",
					acknowledge = b.next,
				}
			elseif step == 2 then
				local count
				if crew_needed * actions_port.CREW_COST > gold then
					count = math.floor(gold / actions_port.CREW_COST)
				else
					count = crew_needed
				end

				character = {
					body = "We rounded up " .. count .. " men, at the cost of " .. count * actions_port.CREW_COST .. " gold pieces.",
					character_id = first_mate,
					acknowledge = function()
						actions_port.recruit_crew(count)
						b.reset()
					end,
				}
			end
		end

		return {
			building_id = "2",
			vendor = vendor,
			character = character,
			menu = menu,
		}
	end

	return building
end

return M
