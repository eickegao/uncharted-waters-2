local widgets = require "modules.ui.widgets"
local use_building = require "modules.ui.use_building"
local actions_port = require "modules.state.actions_port"
local selectors = require "modules.state.selectors"

local M = {}

local OPTIONS = {
	{ label = "Pray", value = "Pray" },
	{ label = "Donate", value = "Donate" },
}

function M.create()
	local b = use_building(true)
	local was_large_donation = false

	local building = {}

	function building.view()
		local option, step = b.option, b.step
		local at_mosque = selectors.get_at_mosque()

		local vendor = { body = "Welcome to our church." }
		local children

		local menu = function(x, y)
			widgets.building_menu("menu", x, y, OPTIONS, {
				hidden = option ~= nil or step == -1,
				on_select = b.select_option,
				on_cancel = function()
					b.back()
				end,
			})
		end

		if option == "Pray" then
			vendor = {
				body = "Let’s pray that God will protect you.",
				acknowledge = function()
					actions_port.pray()
					b.reset()
				end,
			}
		end

		if option == "Donate" then
			local gold = selectors.get_gold()

			if step == 0 then
				if gold == 0 then
					-- TODO this should be a character message
					vendor = { body = "You have no gold.", acknowledge = b.reset }
				else
					vendor = { body = "Your money will be used to feed the poor. How much can you give?" }
					children = function()
						widgets.input_number("donate", gold, function(amount)
							if actions_port.donate(amount) >= 10 then
								was_large_donation = true
							end
							b.next()
						end, b.reset)
					end
				end
			end

			if step == 1 then
				vendor = {
					body = was_large_donation
							and "Thank you for your generous donation. Our heavenly father will surely watch over you."
						or "Come visit us again.",
					acknowledge = b.reset,
				}
			end
		end

		if step == -1 then
			vendor = {
				body = "May God bless you in your travels!",
				acknowledge = function()
					b.back()
				end,
			}
		end

		if at_mosque then
			vendor = {
				body = "I respect your interest, but Christians are not allowed in the house of Allah.",
				acknowledge = function()
					b.back(2)
				end,
			}
			menu = nil
		end

		return {
			building_id = at_mosque and "13" or "11",
			vendor = vendor,
			menu = menu,
			children = children,
		}
	end

	return building
end

return M
