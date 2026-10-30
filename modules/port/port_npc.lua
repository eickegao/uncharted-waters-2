local types = require "modules.types"
local utils = require "modules.utils"

local direction_to_changes = types.direction_to_changes

local function create_port_npc(start_position, start_frame, start_direction, is_stationary)
	local position = start_position
	local destination = nil
	local frame_offset = is_stationary and 0 or direction_to_changes[start_direction].frame_offset
	local frame_alternate = 0

	local function get_moves_to_skip()
		return utils.random(2, 6)
	end

	local moves_to_skip = get_moves_to_skip()
	local moves_skipped = 0
	local current_direction = "s"
	local direction_was_collision = false

	local function random_direction()
		if not direction_was_collision and math.random() < 0.75 then
			return current_direction
		end
		return utils.sample(utils.directions)
	end

	local function animate()
		frame_alternate = frame_alternate == 0 and 1 or 0
	end

	local npc = { width = 2, height = 2, is_stationary = is_stationary }

	function npc.should_move()
		if moves_skipped == moves_to_skip then
			moves_to_skip = get_moves_to_skip()
			moves_skipped = 0
			return true
		end
		moves_skipped = moves_skipped + 1
		return false
	end

	function npc.move(collision_at)
		animate()

		if is_stationary then
			return
		end

		local direction = random_direction()
		local changes = direction_to_changes[direction]
		frame_offset = changes.frame_offset
		destination = { x = position.x + changes.x_delta, y = position.y + changes.y_delta }

		if not collision_at(destination) then
			current_direction = direction
			direction_was_collision = false
		else
			destination = nil
			direction_was_collision = true
		end
	end

	function npc.update()
		if destination then
			position = destination
		end
	end

	function npc.position(percent_next_move)
		percent_next_move = percent_next_move or 0
		if not destination then
			return position
		end
		return {
			x = position.x + (destination.x - position.x) * percent_next_move,
			y = position.y + (destination.y - position.y) * percent_next_move,
		}
	end

	function npc.destination()
		return destination
	end

	function npc.frame()
		return start_frame + frame_offset + frame_alternate
	end

	return npc
end

return create_port_npc
