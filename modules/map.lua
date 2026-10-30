--[[
  Tile data and collision for both the world map and port maps. Rendering is
  done by main/game.script, which copies the visible part of the map into a
  Defold tilemap.
]]
local assets = require "modules.assets"
local constants = require "modules.constants"
local shared_utils = require "modules.world.shared_utils"
local port_extra_data = require "modules.data.port_extra_data"

local M = {}

local PORT_TILEMAP_SIZE = 96

-- number of columns in the tileset images (tiles are 16px in the images)
M.WORLD_TILESET_COLUMNS = 128
M.PORT_TILESET_COLUMNS = 240

local function world_tileset_offset(time)
	local time_offset

	if time >= 480 and time < 960 then
		-- 08 to 16
		time_offset = 0
		if time >= 840 then
			time_offset = time_offset + (time - 840) / (120 / 6)
		end
	elseif time >= 960 and time < 1200 then
		-- 16 to 20
		time_offset = 6
		if time >= 1080 then
			time_offset = time_offset + (time - 1080) / (120 / 10)
		end
	elseif time >= 1200 or time < 240 then
		-- 20 to 04
		time_offset = 16
		if time >= 120 and time < 240 then
			time_offset = time_offset + (time - 120) / (120 / 6)
		end
	else
		-- 04 to 08
		time_offset = 22
		if time >= 360 then
			time_offset = time_offset + (time - 360) / (120 / 9)
		end
	end

	return math.floor(time_offset)
end

function M.create(port_data)
	local map = {}

	local data_id
	local base
	local columns
	local rows
	local collision_indices

	if port_data then
		data_id = "port_tilemaps"
		columns = PORT_TILEMAP_SIZE
		rows = PORT_TILEMAP_SIZE
		base = port_data.tilemap * columns * rows
		collision_indices = port_extra_data.tilesets[port_data.tileset].collisionIndices
		map.tileset_columns = M.PORT_TILESET_COLUMNS
	else
		data_id = "world_tilemap"
		columns = constants.WORLD_MAP_COLUMNS
		rows = 1080
		base = 0
		map.tileset_columns = M.WORLD_TILESET_COLUMNS
	end

	local size = columns * rows

	map.is_port = port_data ~= nil
	map.tilemap_columns = columns
	map.tilemap_rows = rows

	function map.tiles(x, y)
		local index = y * columns + shared_utils.get_x_wrap_around(x)
		if index < 0 or index >= size then
			return 0
		end
		return assets.byte(data_id, base + index) or 0
	end

	-- the tilesets have one row of tiles per time of day
	function map.get_tileset_offset(time)
		if not port_data then
			return world_tileset_offset(time)
		end

		local time_offset
		if time >= 240 and time < 480 then
			time_offset = 0
		elseif time >= 480 and time < 960 then
			time_offset = 1
		elseif time >= 960 and time < 1200 then
			time_offset = 2
		else
			time_offset = 3
		end

		return time_offset + port_data.tileset * 4
	end

	local function out_of_bounds_at(position)
		local x, y = position.x, position.y

		if y < 0 or y + 1 >= rows then
			return true
		end

		if not port_data then
			return false
		end

		return x < 0 or x + 1 >= columns
	end

	-- characters are 2x2 tiles; ports only check the lower half
	function map.collision_at(position)
		if out_of_bounds_at(position) then
			return true
		end

		local x, y = position.x, position.y

		if port_data then
			local left = map.tiles(x, y + 1)
			local right = map.tiles(x + 1, y + 1)

			if left >= collision_indices.either or left >= collision_indices.left then
				return true
			end

			return right >= collision_indices.either
				or (right >= collision_indices.right and right < collision_indices.left)
		end

		return map.tiles(x, y + 1) >= 50
			or map.tiles(x + 1, y + 1) >= 50
			or map.tiles(x, y) >= 50
			or map.tiles(x + 1, y) >= 50
	end

	return map
end

return M
