local port_utils = require "modules.port.port_utils"
local port_data = require "modules.data.port_data"

local regular_count = #port_data.regular_ports
local first_supply_port = tostring(regular_count + 1)

describe("port_utils", function()
	test("accessing a port that doesn't exist", function()
		expect(function()
			port_utils.get_port_data("0")
		end).to_throw()
		expect(function()
			port_utils.get_port_data(tostring(regular_count + #port_data.supply_ports + 1))
		end).to_throw()
	end)

	test("regular port data", function()
		local lisbon = port_utils.get_port_data("1")
		expect(lisbon.id).to_equal("1")
		expect(lisbon.name).to_equal("Lisbon")
		expect(lisbon.is_supply_port).to_equal(false)
		expect(lisbon.tilemap).to_equal(0)

		expect(port_utils.get_port_data("2").tilemap).to_equal(1)
	end)

	test("supply port data", function()
		local hekla = port_utils.get_port_data(first_supply_port)
		expect(hekla.name).to_equal("Hekla")
		expect(hekla.is_supply_port).to_equal(true)
	end)

	test("supply ports only have the Harbor and share a tilemap", function()
		local hekla = port_utils.get_port_data(first_supply_port)
		expect(hekla.buildings).to_equal(port_data.SUPPLY_PORT_BUILDINGS)
		expect(hekla.tilemap).to_equal(regular_count)
		expect(port_utils.get_port_data(tostring(regular_count + 2)).tilemap).to_equal(regular_count)
	end)

	test("must be within [2, 1] or [1, 2] of a port to dock", function()
		-- Lisbon is at 840, 358 and Hekla at 784, 210
		expect(port_utils.port_adjacent_at({ x = 10, y = 10 })).to_equal(nil)
		expect(port_utils.port_adjacent_at({ x = 838, y = 358 })).to_equal("1")
		expect(port_utils.port_adjacent_at({ x = 838, y = 357 })).to_equal("1")
		expect(port_utils.port_adjacent_at({ x = 838, y = 356.9 })).to_equal(nil)
		expect(port_utils.port_adjacent_at({ x = 838, y = 359 })).to_equal("1")
		expect(port_utils.port_adjacent_at({ x = 838, y = 359.1 })).to_equal(nil)
		expect(port_utils.port_adjacent_at({ x = 837.9, y = 358 })).to_equal(nil)
		expect(port_utils.port_adjacent_at({ x = 784, y = 208 })).to_equal(first_supply_port)
		expect(port_utils.port_adjacent_at({ x = 785, y = 208 })).to_equal(first_supply_port)
		expect(port_utils.port_adjacent_at({ x = 785.1, y = 208 })).to_equal(nil)
		expect(port_utils.port_adjacent_at({ x = 783, y = 208 })).to_equal(first_supply_port)
		expect(port_utils.port_adjacent_at({ x = 782.9, y = 208 })).to_equal(nil)
	end)

	test("regions", function()
		expect(port_utils.get_region_or_if_supply_port("1")).to_equal("Iberia")
		expect(port_utils.get_region_or_if_supply_port(first_supply_port)).to_equal("Supply port")
	end)
end)
