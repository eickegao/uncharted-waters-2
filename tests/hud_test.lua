--[[
  Drives the interface and the game loop with stand-ins for Defold's gui and
  vmath modules, to catch runtime errors in code that otherwise only runs
  inside the engine.
]]
local live_nodes = 0
local created_nodes = 0

local function vector(x, y, z, w)
	return { x = x, y = y, z = z, w = w }
end

vmath = { vector3 = vector, vector4 = vector }

local function node_function()
	return function() end
end

gui = setmetatable({
	PIVOT_NW = "nw",
	PIVOT_N = "n",
	PIVOT_NE = "ne",
	PIVOT_CENTER = "center",
	EASING_INOUTSINE = "easing",
	PLAYBACK_LOOP_PINGPONG = "pingpong",
	new_box_node = function(position, size)
		live_nodes = live_nodes + 1
		created_nodes = created_nodes + 1
		return { position = position, size = size }
	end,
	new_text_node = function(position, text)
		assert(type(text) == "string")
		live_nodes = live_nodes + 1
		created_nodes = created_nodes + 1
		return { position = position, text = text }
	end,
	delete_node = function()
		live_nodes = live_nodes - 1
	end,
	get_text_metrics_from_node = function(node)
		return { width = #node.text * 10, height = 30 }
	end,
}, {
	__index = function()
		return node_function()
	end,
})

local ui = require "modules.ui.ui"
local hud = require "modules.ui.hud"
local state = require "modules.state.state"
local ui_bridge = require "modules.state.ui_bridge"
local actions_port = require "modules.state.actions_port"
local actions_world = require "modules.state.actions_world"
local input_state = require "modules.input_state"
local create_port = require "modules.port.port"
local create_world = require "modules.world.world"
local building_data = require "modules.data.building_data"

local version = nil

local function frame(dt)
	ui.update(dt or 0.016)
	hud.update(dt or 0.016)
	if ui.dirty or version ~= ui_bridge.version then
		version = ui_bridge.version
		ui.begin()
		hud.draw()
		ui.finish()
	end
end

-- finishes fades and the delayed Yes/No submit
local function settle()
	for _ = 1, 30 do
		frame(0.02)
	end
end

local function press(key)
	ui.key_pressed(key)
	settle()
end

local function start_game()
	state.reset()
	ui_bridge.fade_callback = nil
	actions_port.update_general()
	actions_world.set_docked_fleet_positions()
	state.port = create_port(state.port_id)
	settle()
end

local KEYS = { "w", "a", "s", "d", "e", "enter", "escape", "up", "down", "left", "right", "backspace" }

local function fuzz(steps)
	for _ = 1, steps do
		local roll = math.random(1, 10)
		if roll <= 6 then
			ui.key_pressed(KEYS[math.random(1, #KEYS)])
		elseif roll <= 8 then
			ui.click(math.random(0, 1639), math.random(0, 799))
		elseif roll == 9 then
			ui.right_click(math.random(0, 1639), math.random(0, 799))
		else
			ui.text_input(tostring(math.random(0, 9)))
		end
		frame(0.03)
	end
end

describe("interface", function()
	test("draws the port, and enters and leaves every building", function()
		start_game()
		expect(live_nodes > 0).to_equal(true)

		for id in pairs(building_data.buildings) do
			actions_port.enter_building(id)
			settle()
			for _ = 1, 100 do
				if not state.building_id then
					break
				end
				press("escape")
			end
			expect(state.building_id).to_equal(nil)
		end
	end)

	test("plays through the opening of the story", function()
		start_game()
		state.gold = 0

		local function visit(building_id)
			actions_port.enter_building(building_id)
			settle()
			for _ = 1, 200 do
				if not state.building_id then
					return
				end
				press("e")
			end
			-- some buildings have a menu after the conversation
			for _ = 1, 20 do
				if not state.building_id then
					return
				end
				press("escape")
			end
		end

		visit("8")
		visit("3")
		expect(#state.fleets[1].ships).to_equal(1)
		visit("11")
		expect(#state.mates).to_equal(3)
		visit("2")
		expect(state.gold > 0).to_equal(true)
	end)

	test("recruits crew, supplies and sets sail", function()
		start_game()
		state.quests = {
			"houseBeforeQuest",
			"shipyardAfterQuest",
			"churchAfterQuest",
			"pubAfterQuest",
			"houseAfterQuestAndPub",
			"harborFinal",
			"itemShopAfterQuest",
		}
		state.gold = 5000
		actions_port.receive_first_ship()
		actions_port.recruit_rocco()

		-- Pub: Carlotta's greeting, Recruit Crew, Yes, then the two acknowledgements
		actions_port.enter_building("2")
		settle()
		press("e")
		press("e")
		press("e")
		press("e")
		press("e")
		expect(state.fleets[1].ships[1].crew > 0).to_equal(true)
		press("escape")
		expect(state.building_id).to_equal(nil)

		-- Harbor: Supply water and food by clicking the quantities
		actions_port.enter_building("4")
		settle()
		press("s")
		press("e")
		for _, column in ipairs({ 0, 1 }) do
			-- ship row, water/food columns, see harbor.lua
			ui.click(180 + 16 + 16 + 16 + 256 + 96 + column * 96 + 10, 48 + 16 + 8 + 32 + 10)
			settle()
			ui.text_input("3")
			ui.text_input("0")
			press("enter")
		end
		local cargo = state.fleets[1].ships[1].cargo
		expect(#cargo).to_equal(2)
		press("escape")

		-- Sail
		press("w")
		press("e")
		press("e")
		expect(state.port_id).to_equal(nil)

		state.world = create_world()
		input_state.on_key("w", true, false)
		for _ = 1, 50 do
			state.world.update(0.07)
			local view = state.world.view()
			expect(#view.sprites).to_equal(1)
			frame(0.07)
		end
		input_state.on_key("w", false, true)
	end)

	test("survives random input in every building", function()
		math.randomseed(42)
		for _ = 1, 3 do
			start_game()
			state.gold = 3000
			actions_port.receive_first_ship()
			actions_port.recruit_rocco()
			state.quests = { "houseBeforeQuest", "shipyardAfterQuest", "itemShopAfterQuest" }
			for id in pairs(building_data.buildings) do
				if state.port_id == nil then
					break
				end
				actions_port.enter_building(id)
				settle()
				fuzz(300)
				if state.building_id then
					actions_port.exit_building()
					settle()
				end
			end
		end
	end)

	test("opens the Mates, Fleet and Items windows", function()
		start_game()
		actions_port.receive_first_ship()
		actions_port.buy_item("4", true)
		for i = 0, 2 do
			ui.click(100, 408 + i * 68 + 30)
			settle()
			expect(ui_bridge.popover_open).to_equal(true)
			press("s")
			press("escape")
			expect(ui_bridge.popover_open).to_equal(false)
		end
	end)

	test("the port player walks around and NPCs move", function()
		start_game()
		input_state.on_key("d", true, false)
		for _ = 1, 200 do
			state.port.update(0.07)
			state.port.view()
			if state.building_id then
				break
			end
		end
		input_state.on_key("d", false, true)
	end)
end)

test("nodes are deleted when the interface is rebuilt", function()
	ui.begin()
	ui.finish()
	expect(live_nodes).to_equal(0)
	expect(created_nodes > 0).to_equal(true)
end)
