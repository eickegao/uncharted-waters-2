--[[
  The game state, shared by the game loop (main/game.script) and the
  interface (main/hud.gui_script).

  Fleet ship numbers are 1-based. A mate's role is either nil (navigator),
  a ship number (captain of that ship, 1 being the commodore of the
  flagship), "firstMate", "bookKeeper" or "chiefNavigator".
]]
local constants = require "modules.constants"

local state = {}

function state.reset()
	for k in pairs(state) do
		if type(state[k]) ~= "function" then
			state[k] = nil
		end
	end

	state.port_id = "1"
	state.building_id = nil
	state.time_passed = constants.START_TIME_PASSED
	state.fleets = {
		[1] = { position = nil, ships = {} },
	}
	state.day_at_sea = 0
	state.gold = 0
	state.quests = {}
	state.used_ships_at_port = {}
	state.savings = 0
	state.debt = 0
	state.items = {}
	state.mates = {
		{ sailor_id = "1", role = nil },
	}
	state.wind = { direction = 0, speed = 0 }
	state.current = { direction = 0, speed = 0 }
	-- created by the game loop
	state.world = nil
	state.port = nil
end

state.reset()

return state
