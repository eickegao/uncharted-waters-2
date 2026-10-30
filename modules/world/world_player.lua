local types = require "modules.types"
local get_ship_speed = require "modules.world.ship_speed"
local world_utils = require "modules.world.world_utils"
local shared_utils = require "modules.world.shared_utils"
local state = require "modules.state.state"
local ui_bridge = require "modules.state.ui_bridge"

local direction_to_changes = types.direction_to_changes
local direction_map = types.direction_map

-- get_captain is passed in so that tests can provide their own
local function create_world_player(start_position, start_frame, start_direction, get_captain)
	local position = start_position
	local destination = nil
	local frame_offset = direction_to_changes[start_direction].frame_offset
	local frame_alternate = 0
	local heading = ""
	local speed = 0
	local last_heading = ""
	local last_wind = { direction = 0, speed = 0 }

	ui_bridge.set_player_fleet_direction(direction_map[heading])

	local function wind_unchanged(wind)
		return wind.direction == last_wind.direction and wind.speed == last_wind.speed
	end

	local function animate()
		frame_alternate = frame_alternate == 0 and 1 or 0
	end

	local player = { width = 2, height = 2 }

	function player.move(direction, collision_at)
		animate()

		local changes = direction_to_changes[direction]
		frame_offset = changes.frame_offset

		local is_diagonal = changes.x_delta ~= 0 and changes.y_delta ~= 0
		local multiplier = speed / 40 / (is_diagonal and math.sqrt(2) or 1)

		if not is_diagonal then
			destination = world_utils.calculate_destination(position, changes.x_delta, changes.y_delta, multiplier, collision_at)
			return
		end

		local first_destination = world_utils.calculate_destination(position, changes.x_delta, 0, multiplier, collision_at)
		destination = world_utils.calculate_destination(first_destination, 0, changes.y_delta, multiplier, collision_at)
	end

	function player.update()
		if destination then
			position = {
				x = shared_utils.get_x_wrap_around(destination.x),
				y = destination.y,
			}
		end
	end

	function player.position(percent_next_move)
		percent_next_move = percent_next_move or 0
		if not destination then
			return position
		end
		return {
			x = shared_utils.get_x_wrap_around(position.x + (destination.x - position.x) * percent_next_move),
			y = position.y + (destination.y - position.y) * percent_next_move,
		}
	end

	function player.destination()
		return destination
	end

	function player.set_heading(new_heading)
		if new_heading == heading then
			return
		end
		heading = new_heading
		ui_bridge.set_player_fleet_direction(direction_map[heading])
	end

	function player.heading()
		return heading
	end

	function player.update_speed()
		if heading == last_heading and wind_unchanged(state.wind) then
			return
		end

		local ship = state.fleets[1].ships[1]
		if heading ~= "" then
			speed = get_ship_speed(ship, get_captain(1), direction_map[heading], state.wind)
		else
			speed = 0
		end

		last_heading = heading
		last_wind = state.wind
		ui_bridge.set_player_fleet_speed(speed)
	end

	function player.frame()
		return start_frame + frame_offset + frame_alternate
	end

	return player
end

return create_world_player
