local types = require "modules.types"

local direction_to_changes = types.direction_to_changes

local function alternative_destinations(direction, position, i)
	if direction == "n" or direction == "s" then
		local second_step_y = direction == "n" and position.y - 1 or position.y + 1
		return {
			{
				direction = "e",
				step1 = { x = position.x + i, y = position.y },
				step2 = { x = position.x + i, y = second_step_y },
			},
			{
				direction = "w",
				step1 = { x = position.x - i, y = position.y },
				step2 = { x = position.x - i, y = second_step_y },
			},
		}
	end

	local second_step_x = direction == "e" and position.x + 1 or position.x - 1
	return {
		{
			direction = "n",
			step1 = { x = position.x, y = position.y - i },
			step2 = { x = second_step_x, y = position.y - i },
		},
		{
			direction = "s",
			step1 = { x = position.x, y = position.y + i },
			step2 = { x = second_step_x, y = position.y + i },
		},
	}
end

-- when walking into a wall, look for an opening to the sides and walk towards it
local function alternative_direction(direction, position, collision_at)
	local first_possible = true
	local second_possible = true

	for i = 1, 19 do
		local destinations = alternative_destinations(direction, position, i)

		if first_possible then
			if collision_at(destinations[1].step1) then
				first_possible = false
			elseif not collision_at(destinations[1].step2) then
				return destinations[1].direction
			end
		end

		if second_possible then
			if collision_at(destinations[2].step1) then
				second_possible = false
			elseif not collision_at(destinations[2].step2) then
				return destinations[2].direction
			end
		end
	end

	return ""
end

-- enter_building is passed in to avoid a circular dependency with actions_port
local function create_port_player(start_position, start_frame, start_direction, enter_building)
	local position = start_position
	local destination = nil
	local frame_offset = direction_to_changes[start_direction].frame_offset
	local frame_alternate = 0
	local building_id = nil

	local function animate()
		frame_alternate = frame_alternate == 0 and 1 or 0
	end

	local player = { width = 2, height = 2 }

	function player.move(direction, collision_at)
		animate()

		local changes = direction_to_changes[direction]
		frame_offset = changes.frame_offset
		destination = { x = position.x + changes.x_delta, y = position.y + changes.y_delta }

		if not collision_at(destination) then
			return
		end

		local new_direction = alternative_direction(direction, position, collision_at)

		if new_direction ~= "" then
			changes = direction_to_changes[new_direction]
			frame_offset = changes.frame_offset
			destination = { x = position.x + changes.x_delta, y = position.y + changes.y_delta }
		else
			destination = nil
		end
	end

	function player.will_enter_building(building_at)
		if not destination then
			return false
		end
		building_id = building_at(destination)
		return building_id ~= nil
	end

	function player.entered_building()
		if not building_id then
			return false
		end

		enter_building(building_id)
		building_id = nil
		animate()

		-- the player steps out of the building once done
		local changes = direction_to_changes.s
		frame_offset = changes.frame_offset
		destination = { x = position.x + changes.x_delta, y = position.y + changes.y_delta }

		return true
	end

	function player.update()
		if destination then
			position = destination
		end
	end

	function player.position(percent_next_move)
		percent_next_move = percent_next_move or 0
		if not destination then
			return position
		end
		return {
			x = position.x + (destination.x - position.x) * percent_next_move,
			y = position.y + (destination.y - position.y) * percent_next_move,
		}
	end

	function player.destination()
		return destination
	end

	function player.frame()
		return start_frame + frame_offset + frame_alternate
	end

	return player
end

return create_port_player
