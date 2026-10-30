local map_module = require "modules.map"
local selectors = require "modules.state.selectors"
local port_utils = require "modules.port.port_utils"

describe("map", function()
	test("the world map is surrounded by land in the far north", function()
		local world = map_module.create()
		expect(world.collision_at({ x = 0, y = -1 })).to_equal(true)
		expect(world.collision_at({ x = 0, y = 1079 })).to_equal(true)
	end)

	test("the player leaves Lisbon onto open water", function()
		local position = selectors.position_adjacent_to_port("1")
		local world = map_module.create()
		expect(world.collision_at(position)).to_equal(false)
		expect(port_utils.port_adjacent_at(position)).to_equal("1")
	end)

	test("the player spawns outside Lisbon's harbor without colliding", function()
		local port = map_module.create(port_utils.get_port_data("1"))
		local harbor = port_utils.get_port_data("1").buildings["4"]
		expect(port.collision_at({ x = harbor.x, y = harbor.y + 1 })).to_equal(false)
		expect(port.collision_at({ x = -1, y = 0 })).to_equal(true)
	end)

	test("tileset rows change with the time of day", function()
		local port = map_module.create(port_utils.get_port_data("1"))
		local world = map_module.create()
		expect(port.get_tileset_offset(480)).to_equal(1 + port_utils.get_port_data("1").tileset * 4)
		expect(world.get_tileset_offset(480)).to_equal(0)
		expect(world.get_tileset_offset(0)).to_equal(16)
	end)
end)
