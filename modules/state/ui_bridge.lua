--[[
  The game logic pushes values to the interface through this module. The
  interface (main/hud.gui_script) reads them and redraws whenever "version"
  changes.
]]
local M = {
	version = 0,
	general = { port_id = nil, building_id = nil, time_passed = 0, gold = 0 },
	day_at_sea = 0,
	provisions = { water = 0, food = 0, lumber = 0, shot = 0 },
	indicators = nil,
	player_fleet_direction = 8,
	player_fleet_speed = 0,
	-- set while a fade-out is in progress
	fade_callback = nil,
	-- while the Mates, Fleet or Items window is open, the port player can't move
	popover_open = false,
	sound_on = true,
}

local function changed()
	M.version = M.version + 1
end

M.changed = changed

function M.set_general(general)
	M.general = general
	changed()
end

function M.set_day_at_sea(day_at_sea)
	M.day_at_sea = day_at_sea
	changed()
end

function M.set_provisions(provisions)
	M.provisions = provisions
	changed()
end

function M.set_indicators(indicators)
	M.indicators = indicators
	changed()
end

function M.set_player_fleet_direction(direction)
	M.player_fleet_direction = direction
	changed()
end

function M.set_player_fleet_speed(speed)
	M.player_fleet_speed = speed
	changed()
end

function M.fade(on_complete)
	M.fade_callback = on_complete
	changed()
end

return M
