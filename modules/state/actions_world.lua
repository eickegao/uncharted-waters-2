local state = require "modules.state.state"
local ui_bridge = require "modules.state.ui_bridge"
local selectors = require "modules.state.selectors"
local actions_port = require "modules.state.actions_port"
local port_utils = require "modules.port.port_utils"
local input_state = require "modules.input_state"
local wind_current = require "modules.world.wind_current"
local constants = require "modules.constants"

local M = {}

function M.dock(position)
	local port_id = port_utils.port_adjacent_at(position)

	if not port_id then
		return false -- TODO show message
	end

	-- TODO NPC fleet positions need to be saved as well
	local player_fleet = state.fleets[1]
	if player_fleet.position then
		player_fleet.position = position
	end

	-- required here as port.lua depends on actions_port, which this module also uses
	local create_port = require "modules.port.port"
	state.port = create_port(port_id)
	state.port_id = port_id
	input_state.reset()
	actions_port.update_general()

	state.day_at_sea = 0
	ui_bridge.set_day_at_sea(state.day_at_sea)

	return true
end

local function update_provisions()
	local provisions = { water = 0, food = 0, lumber = 0, shot = 0 }

	for _, ship in ipairs(state.fleets[1].ships) do
		for _, item in ipairs(ship.cargo) do
			if provisions[item.type] then
				provisions[item.type] = provisions[item.type] + item.quantity
			end
		end
	end

	ui_bridge.set_provisions(provisions)
end

function M.update_world_status()
	local position = state.fleets[1].position

	if not position then
		error("Player fleet position is not set")
	end

	local sea_area = wind_current.get_sea_area(position)
	local wind = wind_current.get_wind(sea_area, wind_current.get_is_summer(constants.START_DATE, state.time_passed))
	local current = wind_current.get_current(sea_area)

	state.wind = wind
	state.current = current

	ui_bridge.set_indicators({ wind = wind, current = current })
end

function M.world_time_tick()
	state.time_passed = state.time_passed + 20

	if selectors.should_update_world_status() then
		M.update_world_status()
	end

	if selectors.get_time_of_day() == 0 then
		actions_port.update_general()
		state.day_at_sea = state.day_at_sea + 1
		ui_bridge.set_day_at_sea(state.day_at_sea)
	end
end

--[[
  While fleets under normal circumstances always have a position even when
  docked, there are two exceptions:
    - The player at the start of the game
    - NPC sailors who have respawned
]]
function M.set_docked_fleet_positions()
	local player_fleet = state.fleets[1]

	if not player_fleet.position then
		if state.port_id == nil then
			error("Player fleet must start with a position if not in port")
		end
		player_fleet.position = selectors.position_adjacent_to_port(state.port_id)
	end
end

function M.set_sail()
	state.port_id = nil
	state.building_id = nil
	M.update_world_status()
	input_state.reset()
	actions_port.update_general()
	update_provisions()
end

return M
