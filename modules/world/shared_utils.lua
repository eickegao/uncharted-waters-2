local constants = require "modules.constants"

local M = {}

function M.get_x_wrap_around(x)
	if x < 0 then
		return x + constants.WORLD_MAP_COLUMNS
	end

	if x >= constants.WORLD_MAP_COLUMNS then
		return x - constants.WORLD_MAP_COLUMNS
	end

	return x
end

function M.get_camera_position(player, camera, map, percent_next_move, x_wrap_around)
	local position = player.position(percent_next_move)
	local camera_center_x = position.x + player.width / 2
	local camera_center_y = position.y + player.height / 2

	local position_x
	if x_wrap_around then
		position_x = M.get_x_wrap_around(camera_center_x - camera.width / 2)
	else
		position_x = math.max(camera_center_x - camera.width / 2, 0)
		position_x = math.min(position_x, map.tilemap_columns - camera.width)
	end

	local position_y = math.max(camera_center_y - camera.height / 2, 0)
	position_y = math.min(position_y, map.tilemap_rows - camera.height)

	return { x = position_x, y = position_y }
end

function M.get_from_to_accounting_for_wrap_around(x1, x2)
	local from_to = x2 - x1

	if from_to > constants.WORLD_MAP_COLUMNS / 2 then
		return from_to - constants.WORLD_MAP_COLUMNS
	end

	if -from_to > constants.WORLD_MAP_COLUMNS / 2 then
		return from_to + constants.WORLD_MAP_COLUMNS
	end

	return from_to
end

return M
