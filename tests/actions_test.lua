local state = require "modules.state.state"
local actions_port = require "modules.state.actions_port"
local selectors = require "modules.state.selectors"
local selectors_fleet = require "modules.state.selectors_fleet"

describe("actions_port", function()
	test("the first ship is captained by the player", function()
		state.reset()
		actions_port.receive_first_ship()
		expect(#selectors_fleet.get_player_fleet()).to_equal(1)
		expect(state.mates[1].role).to_equal(1)
		expect(selectors.get_role_display(1)).to_equal("Commodore of Hermes II")
		expect(selectors.get_captain(1).name).to_equal("João Franco")
	end)

	test("buying a used ship requires a sailor and gold", function()
		state.reset()
		state.port_id = "1"
		actions_port.receive_first_ship()
		actions_port.recruit_rocco()
		state.gold = 100000

		local used_ships = selectors.get_used_ships()
		local count = #used_ships
		expect(count >= 2).to_equal(true)

		actions_port.buy_used_ship(used_ships[1].id, "Second")
		expect(#selectors.get_used_ships()).to_equal(count - 1)
		expect(#selectors_fleet.get_player_fleet()).to_equal(2)
		expect(state.mates[2].role).to_equal(2)
		expect(actions_port.get_available_sailor_id()).to_equal(nil)
	end)

	test("selling the flagship hands the next ship to the player", function()
		state.reset()
		actions_port.receive_first_ship()
		actions_port.recruit_rocco()
		actions_port.add_ship({ id = "1", name = "Second", crew = 0, cargo = {}, durability = 10 })

		actions_port.sell_ship_number(1)
		expect(#selectors_fleet.get_player_fleet()).to_equal(1)
		expect(selectors_fleet.get_player_fleet()[1].name).to_equal("Second")
		expect(state.mates[1].role).to_equal(1)
		expect(state.mates[2].role).to_equal(nil)
	end)

	test("supplying and crewing ships", function()
		state.reset()
		state.gold = 10000
		actions_port.receive_first_ship()
		expect(selectors_fleet.has_crew_assigned()).to_equal(false)

		local needed = selectors_fleet.get_crew_needed()
		actions_port.recruit_crew(needed)
		expect(selectors_fleet.has_crew_assigned()).to_equal(true)
		expect(state.gold).to_equal(10000 - needed * actions_port.CREW_COST)

		actions_port.supply_ship(1, "water", 20)
		actions_port.supply_ship(1, "food", 10)
		actions_port.supply_ship(1, "food", 10)
		expect(selectors_fleet.get_cargo_quantity(selectors_fleet.get_player_fleet_ship(1), "food")).to_equal(20)
		expect(selectors_fleet.get_days_provisions_will_last()).to_equal(math.floor(20 / needed * 10))
	end)

	test("bank", function()
		state.reset()
		state.gold = 500
		actions_port.deposit(200)
		expect(state.gold).to_equal(300)
		expect(selectors.get_savings()).to_equal(200)
		actions_port.borrow(1000)
		expect(selectors.get_credit_line()).to_equal(0)
		expect(selectors.get_repay_amount()).to_equal(1000)
	end)

	test("item shop", function()
		state.reset()
		state.gold = 100
		expect(actions_port.buy_item("1")).to_equal(false)
		expect(actions_port.buy_item("1", true)).to_equal(true)
		expect(selectors.get_player_items()[1].name).to_equal("Dagger")
		actions_port.sell_item(1)
		expect(#state.items).to_equal(0)
		expect(state.gold).to_equal(350)
	end)
end)
