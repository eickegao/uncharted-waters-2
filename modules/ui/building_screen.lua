-- Picks the screen for the building the player is in
local building_wrapper = require "modules.ui.building_wrapper"
local quest_step = require "modules.quest.quest_step"
local ui = require "modules.ui.ui"

local M = {}

local screens = {
	["2"] = require "modules.ui.buildings.pub",
	["3"] = require "modules.ui.buildings.shipyard",
	["4"] = require "modules.ui.buildings.harbor",
	["5"] = require "modules.ui.buildings.lodge",
	["9"] = require "modules.ui.buildings.bank",
	["10"] = require "modules.ui.buildings.item_shop",
	["11"] = require "modules.ui.buildings.church",
}

local generic = require "modules.ui.buildings.generic"

function M.create(building_id)
	local screen = screens[building_id]
	local building = screen and screen.create() or generic.create(building_id)
	local quest = quest_step.create(ui.invalidate)

	return {
		draw = function()
			building_wrapper.draw(building.view(), quest)
		end,
	}
end

return M
