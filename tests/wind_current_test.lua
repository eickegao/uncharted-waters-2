local wind_current = require "modules.world.wind_current"
local assets = require "modules.assets"
local utils = require "modules.utils"
local constants = require "modules.constants"

describe("get_sea_area", function()
	test("uses zero-based numbering", function()
		expect(wind_current.get_sea_area({ x = 0, y = 0 })).to_equal(0)
	end)
	test("second column, second row, outside Lisbon", function()
		expect(wind_current.get_sea_area({ x = 72, y = 0 })).to_equal(1)
		expect(wind_current.get_sea_area({ x = 0, y = 72 })).to_equal(30)
		expect(wind_current.get_sea_area({ x = 838, y = 358 })).to_equal(131)
	end)
	test("a total of 450 areas exist", function()
		expect(wind_current.get_sea_area({ x = 2159, y = 1079 })).to_equal(449)
	end)
end)

describe("get_is_summer", function()
	test("game starts in the summer", function()
		expect(wind_current.get_is_summer(constants.START_DATE, 0)).to_equal(true)
	end)
	test("winter starts in October", function()
		local start = { year = 1523, month = 9, day = 30 }
		expect(wind_current.get_is_summer(start, 0)).to_equal(true)
		expect(wind_current.get_is_summer(start, 1440)).to_equal(false)
	end)
	test("summer starts in April", function()
		local start = { year = 1524, month = 3, day = 31 }
		expect(wind_current.get_is_summer(start, 0)).to_equal(false)
		expect(wind_current.get_is_summer(start, 1440)).to_equal(true)
	end)
end)

describe("get_wind", function()
	local original_data = assets.data("winds_current")
	local original_random = utils.random

	local function with_data(rolls, fn)
		local bytes = {}
		for i = 1, 2700 do
			bytes[i] = 0
		end
		bytes[0 + 1] = 0
		bytes[450 + 1] = 1
		bytes[900 + 1] = 7
		bytes[1350 + 1] = 7
		bytes[2249 + 1] = 4
		bytes[2699 + 1] = 6
		local chars = {}
		for i, b in ipairs(bytes) do
			chars[i] = string.char(b)
		end
		assets.set("winds_current", table.concat(chars))

		local i = 0
		utils.random = function()
			i = i + 1
			return rolls[i] or rolls[#rolls]
		end

		local ok, err = pcall(fn)
		assets.set("winds_current", original_data)
		utils.random = original_random
		if not ok then
			error(err, 0)
		end
	end

	test("direction and speed depends on summer or winter", function()
		with_data({ 0 }, function()
			expect(wind_current.get_wind(0, true)).to_equal({ direction = 0, speed = 1 })
			expect(wind_current.get_wind(0, false)).to_equal({ direction = 7, speed = 7 })
		end)
	end)

	test("base speed has a 0.5 chance to be incremented by 1", function()
		with_data({ 0, 1 }, function()
			expect(wind_current.get_wind(0, true)).to_equal({ direction = 0, speed = 2 })
		end)
	end)

	test("direction can alternate between 3, with the middle direction having a 0.8 chance", function()
		with_data({ 80, 0 }, function()
			expect(wind_current.get_wind(0, true)).to_equal({ direction = 0, speed = 1 })
		end)
		with_data({ 81, 0 }, function()
			expect(wind_current.get_wind(0, true)).to_equal({ direction = 1, speed = 1 })
		end)
		with_data({ 91, 0 }, function()
			expect(wind_current.get_wind(0, true)).to_equal({ direction = 7, speed = 1 })
		end)
		with_data({ 90, 0 }, function()
			expect(wind_current.get_wind(0, false)).to_equal({ direction = 0, speed = 7 })
		end)
	end)

	test("current", function()
		with_data({ 0 }, function()
			expect(wind_current.get_current(449)).to_equal({ direction = 4, speed = 6 })
		end)
	end)
end)
