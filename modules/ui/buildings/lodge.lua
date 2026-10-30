local widgets = require "modules.ui.widgets"
local use_building = require "modules.ui.use_building"
local actions_port = require "modules.state.actions_port"

local M = {}

local OPTIONS = {
	{ label = "Check In", value = "Check In" },
	{ label = "Gossip", value = "Gossip", disabled = true },
	{ label = "Port Info", value = "Port Info", disabled = true },
}

function M.create()
	local b = use_building()

	local building = {}

	function building.view()
		return {
			building_id = "5",
			vendor = { body = "Welcome. You must be tired. Please make yourself at home." },
			menu = function(x, y)
				widgets.building_menu("menu", x, y, OPTIONS, {
					hidden = b.option ~= nil,
					on_select = function(option)
						b.select_option(option)
						if option == "Check In" then
							actions_port.check_in()
						end
					end,
					on_cancel = function()
						b.back()
					end,
				})
			end,
		}
	end

	return building
end

return M
