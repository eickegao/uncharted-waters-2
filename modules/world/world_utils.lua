local M = {}

function M.get_heading_wind_delta(d1, d2)
	local delta = math.abs(d1 - d2)

	if delta > 4 then
		return 8 - delta
	end

	return delta
end

function M.has_oars(ship_id)
	return tonumber(ship_id) >= 19
end

local function is_whole(n)
	return n % 1 == 0
end

--[[
  Moves the fleet along one axis. When the fleet is blocked, it slides around
  the obstacle if there's an opening above/below (or to the left/right).
]]
function M.calculate_destination(position, x_delta, y_delta, multiplier, collision_at)
	local destination = {
		x = position.x + x_delta * multiplier,
		y = position.y + y_delta * multiplier,
	}

	if x_delta == 1 then
		local x_next = math.ceil(destination.x)
		local y = math.floor(position.y)

		local upper_or_middle_collision = collision_at({ x = x_next, y = y })
		local lower_collision = not is_whole(position.y) and collision_at({ x = x_next, y = y + 1 })

		if not (upper_or_middle_collision or lower_collision) then
			return destination
		end

		local y_next_upper = math.ceil(position.y) - 1
		local y_next_lower = math.floor(position.y) + 1

		local upper_alternative = not collision_at({ x = x_next, y = y_next_upper })
		local lower_alternative = not collision_at({ x = x_next, y = y_next_lower })

		if upper_alternative then
			local x_next_excess = destination.x - (x_next - 1)
			local y_next_need = position.y - y_next_upper
			local remaining = x_next_excess - y_next_need

			if remaining >= 0 then
				destination.y = y_next_upper
				destination.x = x_next - 1 + remaining
			else
				destination.y = destination.y - x_next_excess
				destination.x = destination.x - x_next_excess
			end
		elseif lower_alternative then
			local x_next_excess = destination.x - (x_next - 1)
			local y_next_need = y_next_lower - position.y
			local remaining = x_next_excess - y_next_need

			if remaining >= 0 then
				destination.y = y_next_lower
				destination.x = x_next - 1 + remaining
			else
				destination.y = destination.y + x_next_excess
				destination.x = destination.x - x_next_excess
			end
		else
			destination.x = math.min(destination.x, x_next - 1)
		end
	elseif x_delta == -1 then
		local x_next = math.floor(destination.x)
		local y = math.floor(position.y)

		local upper_or_middle_collision = collision_at({ x = x_next, y = y })
		local lower_collision = not is_whole(position.y) and collision_at({ x = x_next, y = y + 1 })

		if not (upper_or_middle_collision or lower_collision) then
			return destination
		end

		local y_next_upper = math.ceil(position.y) - 1
		local y_next_lower = math.floor(position.y) + 1

		local upper_alternative = not collision_at({ x = x_next, y = y_next_upper })
		local lower_alternative = not collision_at({ x = x_next, y = y_next_lower })

		if upper_alternative then
			local x_next_excess = x_next + 1 - destination.x
			local y_next_need = position.y - y_next_upper
			local remaining = x_next_excess - y_next_need

			if remaining >= 0 then
				destination.y = y_next_upper
				destination.x = x_next + 1 - remaining
			else
				destination.y = destination.y - x_next_excess
				destination.x = destination.x + x_next_excess
			end
		elseif lower_alternative then
			local x_next_excess = x_next + 1 - destination.x
			local y_next_need = y_next_lower - position.y
			local remaining = x_next_excess - y_next_need

			if remaining >= 0 then
				destination.y = y_next_lower
				destination.x = x_next + 1 - remaining
			else
				destination.y = destination.y + x_next_excess
				destination.x = destination.x + x_next_excess
			end
		else
			destination.x = math.max(destination.x, x_next + 1)
		end
	elseif y_delta == -1 then
		local y_next = math.floor(destination.y)
		local x = math.floor(position.x)

		local left_or_middle_collision = collision_at({ x = x, y = y_next })
		local right_collision = not is_whole(position.x) and collision_at({ x = x + 1, y = y_next })

		if not (left_or_middle_collision or right_collision) then
			return destination
		end

		local x_next_left = math.ceil(position.x) - 1
		local x_next_right = math.floor(position.x) + 1

		local left_alternative = not collision_at({ x = x_next_left, y = y_next })
		local right_alternative = not collision_at({ x = x_next_right, y = y_next })

		if left_alternative then
			local y_next_excess = y_next + 1 - destination.y
			local x_next_need = position.x - x_next_left
			local remaining = y_next_excess - x_next_need

			if remaining >= 0 then
				destination.x = x_next_left
				destination.y = y_next + 1 - remaining
			else
				destination.x = destination.x - y_next_excess
				destination.y = destination.y + y_next_excess
			end
		elseif right_alternative then
			local y_next_excess = y_next + 1 - destination.y
			local x_next_need = x_next_right - position.x
			local remaining = y_next_excess - x_next_need

			if remaining >= 0 then
				destination.x = x_next_right
				destination.y = y_next + 1 - remaining
			else
				destination.x = destination.x + y_next_excess
				destination.y = destination.y + y_next_excess
			end
		else
			destination.y = math.max(destination.y, y_next + 1)
		end
	elseif y_delta == 1 then
		local y_next = math.ceil(destination.y)
		local x = math.floor(position.x)

		local left_or_middle_collision = collision_at({ x = x, y = y_next })
		local right_collision = not is_whole(position.x) and collision_at({ x = x + 1, y = y_next })

		if not (left_or_middle_collision or right_collision) then
			return destination
		end

		local x_next_left = math.ceil(position.x) - 1
		local x_next_right = math.floor(position.x) + 1

		local left_alternative = not collision_at({ x = x_next_left, y = y_next })
		local right_alternative = not collision_at({ x = x_next_right, y = y_next })

		if left_alternative then
			local y_next_excess = destination.y - (y_next - 1)
			local x_next_need = position.x - x_next_left
			local remaining = y_next_excess - x_next_need

			if remaining >= 0 then
				destination.x = x_next_left
				destination.y = y_next - 1 + remaining
			else
				destination.x = destination.x - y_next_excess
				destination.y = destination.y - y_next_excess
			end
		elseif right_alternative then
			local y_next_excess = destination.y - (y_next - 1)
			local x_next_need = x_next_right - position.x
			local remaining = y_next_excess - x_next_need

			if remaining >= 0 then
				destination.x = x_next_right
				destination.y = y_next - 1 + remaining
			else
				destination.x = destination.x + y_next_excess
				destination.y = destination.y - y_next_excess
			end
		else
			destination.y = math.min(destination.y, y_next - 1)
		end
	end

	return destination
end

return M
