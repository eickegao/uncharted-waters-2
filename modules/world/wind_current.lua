local assets = require "modules.assets"
local utils = require "modules.utils"
local date_utils = require "modules.date_utils"

local M = {}

-- The world map is 2160x1080, divided into 30x15 areas of 72x72 tiles
function M.get_sea_area(position)
	local area_column = math.floor(position.x / 72)
	local area_row = math.floor(position.y / 72)
	return area_column + area_row * 30
end

--[[
  Guesswork through observing the game.
  The original direction seems to rarely change between updates.
]]
local function random_direction(direction)
	local roll = utils.random(1, 100)

	if roll <= 80 then
		return direction
	end

	if roll <= 90 then
		return direction == 7 and 0 or direction + 1
	end

	return direction == 0 and 7 or direction - 1
end

local function data(index)
	return assets.byte("winds_current", index)
end

function M.get_wind(sea_area, is_summer)
	local base_direction = data(is_summer and sea_area or sea_area + 900)
	local base_speed = data(is_summer and sea_area + 450 or sea_area + 1350)

	return {
		direction = random_direction(base_direction),
		speed = base_speed == 7 and base_speed or base_speed + utils.random(0, 1),
	}
end

function M.get_is_summer(start_date, time_passed)
	local date = date_utils.add_minutes(start_date, time_passed)
	-- April to September
	return date.month >= 4 and date.month < 10
end

function M.get_current(sea_area)
	return {
		direction = data(sea_area + 1800),
		speed = data(sea_area + 2250),
	}
end

return M
