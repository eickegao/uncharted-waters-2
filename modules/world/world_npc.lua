local types = require "modules.types"
local utils = require "modules.utils"

local direction_to_changes = types.direction_to_changes

local function create_world_npc(position, start_frame, start_direction, is_stationary)
	local x, y = position.x, position.y
	local x_to, y_to = x, y
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

	function npc.move()
		if not is_stationary then
			local direction = random_direction()
			local changes = direction_to_changes[direction]
			frame_offset = changes.frame_offset
			x_to = x + changes.x_delta
			y_to = y + changes.y_delta
			current_direction = direction
			direction_was_collision = false
		end
		animate()
	end

	function npc.undo_move()
		x_to = x
		y_to = y
		direction_was_collision = true
	end

	function npc.update()
		x = x_to
		y = y_to
	end

	function npc.position(percent_next_move)
		percent_next_move = percent_next_move or 0
		return {
			x = x + (x_to - x) * percent_next_move,
			y = y + (y_to - y) * percent_next_move,
		}
	end

	function npc.destination()
		return { x = x_to, y = y_to }
	end

	function npc.frame()
		return start_frame + frame_offset + frame_alternate
	end

	return npc
end

return create_world_npc
