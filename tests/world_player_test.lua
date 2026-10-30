local create_world_player = require "modules.world.world_player"
local ship_data_module = require "modules.data.ship_data"
local state = require "modules.state.state"

local function collision_at(tiles)
	return function(position)
		for _, t in ipairs(tiles) do
			if (position.x == t.x or position.x + 1 == t.x) and (position.y == t.y or position.y + 1 == t.y) then
				return true
			end
		end
		return false
	end
end

-- a ship and captain that together sail at exactly 40, one tile per move
local function by_position(position)
	state.reset()
	state.fleets[1].ships = { { id = "90", crew = 5, cargo = {} } }
	state.wind = { direction = 0, speed = 7 }
	ship_data_module.ship_data["90"] = { tacking = 100, power = 100, minimumCrew = 5, capacity = 100, sailType = 1 }

	local player = create_world_player(position, 0, "n", function()
		return { navigationLevel = 90, stats = { seamanship = 100 } }
	end)
	player.set_heading("n")
	player.update_speed()
	return player
end

local function step(player, direction, tiles)
	player.move(direction, collision_at(tiles))
	player.update()
	return player.position()
end

local function close_to(p1, p2)
	expect(p1.x).to_be_close_to(p2.x)
	expect(p1.y).to_be_close_to(p2.y)
end

describe("world_player", function()
	test("right movement, with no alternative destination", function()
		local tiles = { { x = 4, y = 0 }, { x = 4, y = 1 }, { x = 4, y = 2 }, { x = 4, y = 3 } }
		local player = by_position({ x = 1, y = 1 })
		expect(step(player, "e", tiles)).to_equal({ x = 2, y = 1 })
		expect(step(player, "e", tiles)).to_equal({ x = 2, y = 1 })

		player = by_position({ x = 0.9, y = 1 })
		close_to(step(player, "e", tiles), { x = 1.9, y = 1 })
		expect(step(player, "e", tiles)).to_equal({ x = 2, y = 1 })
	end)

	test("right movement, with upper alternative destination", function()
		local tiles = { { x = 4, y = 2 }, { x = 4, y = 3 } }
		local player = by_position({ x = 1, y = 1 })
		expect(step(player, "e", tiles)).to_equal({ x = 2, y = 1 })
		expect(step(player, "e", tiles)).to_equal({ x = 2, y = 0 })

		close_to(step(by_position({ x = 2, y = 0.9 }), "e", tiles), { x = 2.1, y = 0 })
		close_to(step(by_position({ x = 1.9, y = 1 }), "e", tiles), { x = 2, y = 0.1 })
		close_to(step(by_position({ x = 2, y = 1.1 }), "e", tiles), { x = 2, y = 1.1 })
	end)

	test("right movement, with lower alternative destination", function()
		local tiles = { { x = 4, y = 2 }, { x = 4, y = 3 } }
		local player = by_position({ x = 1, y = 3 })
		expect(step(player, "e", tiles)).to_equal({ x = 2, y = 3 })
		expect(step(player, "e", tiles)).to_equal({ x = 2, y = 4 })

		close_to(step(by_position({ x = 2, y = 2.9 }), "e", tiles), { x = 2, y = 2.9 })
		close_to(step(by_position({ x = 1.9, y = 3.1 }), "e", tiles), { x = 2, y = 4 })
	end)

	test("left movement, with no alternative destination", function()
		local tiles = { { x = 0, y = 0 }, { x = 0, y = 1 }, { x = 0, y = 2 }, { x = 0, y = 3 } }
		local player = by_position({ x = 2, y = 1 })
		expect(step(player, "w", tiles)).to_equal({ x = 1, y = 1 })
		expect(step(player, "w", tiles)).to_equal({ x = 1, y = 1 })

		player = by_position({ x = 2.9, y = 1 })
		close_to(step(player, "w", tiles), { x = 1.9, y = 1 })
		expect(step(player, "w", tiles)).to_equal({ x = 1, y = 1 })
	end)

	test("up movement, with right alternative destination", function()
		local tiles = { { x = 1, y = 0 }, { x = 2, y = 0 } }
		local player = by_position({ x = 2, y = 2 })
		expect(step(player, "n", tiles)).to_equal({ x = 2, y = 1 })
		expect(step(player, "n", tiles)).to_equal({ x = 3, y = 1 })

		close_to(step(by_position({ x = 1.9, y = 1 }), "n", tiles), { x = 1.9, y = 1 })
		close_to(step(by_position({ x = 2.1, y = 1 }), "n", tiles), { x = 3, y = 0.9 })
	end)

	test("up movement, with no alternative destination", function()
		local tiles = { { x = 0, y = 0 }, { x = 1, y = 0 }, { x = 2, y = 0 }, { x = 3, y = 0 } }
		local player = by_position({ x = 1, y = 2 })
		expect(step(player, "n", tiles)).to_equal({ x = 1, y = 1 })
		expect(step(player, "n", tiles)).to_equal({ x = 1, y = 1 })
		close_to(step(by_position({ x = 1, y = 1.9 }), "n", tiles), { x = 1, y = 1 })
	end)

	test("up movement, with left alternative destination", function()
		local tiles = { { x = 2, y = 0 }, { x = 3, y = 0 } }
		local player = by_position({ x = 1, y = 2 })
		expect(step(player, "n", tiles)).to_equal({ x = 1, y = 1 })
		expect(step(player, "n", tiles)).to_equal({ x = 0, y = 1 })

		close_to(step(by_position({ x = 0.9, y = 1 }), "n", tiles), { x = 0, y = 0.9 })
		close_to(step(by_position({ x = 1.1, y = 1 }), "n", tiles), { x = 1.1, y = 1 })
	end)
end)
