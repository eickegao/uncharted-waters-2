local ship_data_module = require "modules.data.ship_data"
local get_ship_speed = require "modules.world.ship_speed"

local sailor = { navigationLevel = 1, stats = { seamanship = 80 } }

local function with_mocked_ships(fn)
	local original_ships = ship_data_module.ship_data
	local original_factors = ship_data_module.ship_wind_factor_map

	ship_data_module.ship_data = {
		["1"] = { name = "Slow ship to prevent hitting the speed cap", tacking = 100, power = 20, minimumCrew = 5, capacity = 100, sailType = 1 },
		["2"] = { name = "Ship affected by tacking in headwind", tacking = 90, power = 20, minimumCrew = 5, capacity = 100, sailType = 2 },
		["19"] = { name = "Ship with oars", tacking = 100, power = 20, minimumCrew = 5, capacity = 100, sailType = 1 },
	}
	ship_data_module.ship_wind_factor_map = {
		[1] = { 10, 8, 6, 4, 2 },
		-- for the tacking test, ensuring that the wind factor won't be a factor
		[2] = { 10, 10, 10, 10, 10 },
	}

	local ok, err = pcall(fn)
	ship_data_module.ship_data = original_ships
	ship_data_module.ship_wind_factor_map = original_factors
	if not ok then
		error(err, 0)
	end
end

local function ship(id, crew, cargo)
	return { id = id, crew = crew or 5, cargo = cargo or {} }
end

describe("get_ship_speed", function()
	test("higher the faster the wind speed", function()
		with_mocked_ships(function()
			local function by(speed)
				return get_ship_speed(ship("1"), sailor, 0, { direction = 0, speed = speed })
			end
			expect(by(0)).to_equal(0)
			expect(by(2)).to_be_greater_than(by(1))
			expect(by(7)).to_be_greater_than(by(4))
		end)
	end)

	test("ships with oars have a minimum wind speed of 3", function()
		with_mocked_ships(function()
			local function by(speed)
				return get_ship_speed(ship("19"), sailor, 0, { direction = 0, speed = speed })
			end
			expect(by(0)).to_equal(by(1))
			expect(by(1)).to_equal(by(3))
			expect(by(4)).to_be_greater_than(by(3))
		end)
	end)

	test("depends on wind direction relative to heading", function()
		with_mocked_ships(function()
			local function by(direction)
				return get_ship_speed(ship("1"), sailor, 3, { direction = direction, speed = 3 })
			end
			expect(by(3)).to_be_greater_than(by(4))
			expect(by(4)).to_be_greater_than(by(5))
			expect(by(5)).to_be_greater_than(by(6))
			expect(by(6)).to_be_greater_than(by(7))
		end)
	end)

	test("depends on having enough navigation crew, with no boost above the minimum", function()
		with_mocked_ships(function()
			local function by(crew)
				return get_ship_speed(ship("1", crew), sailor, 0, { direction = 0, speed = 3 })
			end
			expect(by(0)).to_equal(0)
			expect(by(2)).to_be_greater_than(by(1))
			expect(by(10)).to_equal(by(5))
		end)
	end)

	test("load starts affecting speed when above 30%", function()
		with_mocked_ships(function()
			local function by(total)
				return get_ship_speed(ship("1", 5, { { type = "water", quantity = total } }), sailor, 0, { direction = 0, speed = 3 })
			end
			expect(by(0)).to_equal(by(25))
			expect(by(26)).to_be_less_than(by(25))
			expect(by(95)).to_be_less_than(by(80))
		end)
	end)

	test("is increased by Navigation Level and affected by Seamanship", function()
		with_mocked_ships(function()
			local function by(level, seamanship)
				return get_ship_speed(ship("1"), { navigationLevel = level, stats = { seamanship = seamanship } }, 0, { direction = 0, speed = 3 })
			end
			expect(by(2, 80)).to_be_greater_than(by(1, 80))
			expect(by(20, 80)).to_be_greater_than(by(5, 80))
			expect(by(1, 100)).to_be_greater_than(by(1, 80))
		end)
	end)

	test("tacking rating is used with a side headwind or headwind", function()
		with_mocked_ships(function()
			local function by(direction)
				return get_ship_speed(ship("2"), sailor, 0, { direction = direction, speed = 3 })
			end
			expect(by(2)).to_equal(by(0))
			expect(by(1)).to_be_greater_than(by(3))
			expect(by(0)).to_be_greater_than(by(4))
		end)
	end)

	test("is capped at 40", function()
		with_mocked_ships(function()
			local fast = get_ship_speed(ship("1"), { navigationLevel = 90, stats = { seamanship = 100 } }, 0, { direction = 0, speed = 7 })
			expect(fast).to_equal(40)
		end)
	end)

	test("known values", function()
		with_mocked_ships(function()
			expect(string.format("%.2f", get_ship_speed(ship("1"), sailor, 0, { direction = 0, speed = 7 }))).to_equal("16.43")
			expect(string.format("%.2f", get_ship_speed(ship("2"), sailor, 0, { direction = 4, speed = 7 }))).to_equal("14.78")
		end)
	end)
end)
