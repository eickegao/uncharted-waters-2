-- Buildings whose features aren't implemented yet
local widgets = require "modules.ui.widgets"
local use_building = require "modules.ui.use_building"
local building_data = require "modules.data.building_data"
local utils = require "modules.utils"

local M = {}

function M.create(building_id)
	local b = use_building()
	local options = building_data.buildings[building_id].options

	local building = {}

	function building.view()
		return {
			building_id = building_id,
			vendor = { body = "This feature is not implemented yet. Press ESC to exit this building." },
			menu = function(x, y)
				widgets.building_menu("menu", x, y, utils.map(options, function(option)
					return { label = option, value = option, disabled = option ~= "Sail" }
				end), {
					on_select = function() end,
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
