-- Runs main/game.script with stand-ins for the Defold APIs it uses
local state = require "modules.state.state"
local ui_bridge = require "modules.state.ui_bridge"
local actions_world = require "modules.state.actions_world"
local input_state = require "modules.input_state"

local tiles_set = 0
local max_tile = 0
local objects = {}
local playing = {}

local function vector(x, y, z, w)
	return { x = x, y = y, z = z, w = w }
end

vmath = vmath or { vector3 = vector, vector4 = vector }
msg = {
	post = function() end,
	url = function(_, id, fragment)
		return tostring(id) .. "#" .. fragment
	end,
}
tilemap = {
	set_tile = function(_, _, x, y, tile)
		assert(x >= 1 and x <= 41 and y >= 1 and y <= 26, "tile out of bounds")
		tiles_set = tiles_set + 1
		max_tile = math.max(max_tile, tile)
	end,
}
go = {
	set_position = function() end,
	delete = function(id)
		objects[id] = nil
	end,
}
local next_id = 0
factory = {
	create = function()
		next_id = next_id + 1
		objects[next_id] = true
		return next_id
	end,
}
sprite = {
	play_flipbook = function(_, animation)
		local frame = tonumber(animation:match("^f(%d+)$"))
		assert(frame and frame >= 0 and frame < 32, "no such animation " .. animation)
	end,
}
sound = {
	play = function(url)
		playing[url] = true
	end,
	stop = function(url)
		playing[url] = nil
	end,
	set_group_gain = function() end,
}

local env = setmetatable({}, { __index = _G })
local source = rawget(_G, "read_binary_file") and read_binary_file("/main/game.script")
	or assert(io.open("main/game.script")):read("*a")
local chunk = assert((loadstring or load)(source, "game.script"))
if setfenv then
	setfenv(chunk, env)
else
	chunk = assert(load(source, "game.script", "t", env))
end
chunk()

describe("game.script", function()
	test("renders the port, then the world map after setting sail", function()
		state.reset()
		ui_bridge.fade_callback = nil

		local self = {}
		env.init(self)
		for _ = 1, 20 do
			env.update(self, 0.05)
		end

		expect(tiles_set >= 41 * 26).to_equal(true)
		-- port tilesets have 240 columns and 28 rows
		expect(max_tile <= 240 * 28).to_equal(true)
		expect(playing["/music#mast_in_the_mist"]).to_equal(true)

		local people = 0
		for _ in pairs(objects) do
			people = people + 1
		end
		expect(people > 1).to_equal(true)

		-- set sail with a ship
		state.fleets[1].ships = { { id = "6", name = "Hermes II", crew = 10, cargo = {}, durability = 10 } }
		state.mates[1].role = 1
		actions_world.set_sail()
		input_state.on_key("a", true, false)
		max_tile = 0
		for _ = 1, 50 do
			env.update(self, 0.05)
		end
		input_state.on_key("a", false, true)

		expect(playing["/music#theme_of_joao"]).to_equal(true)
		expect(playing["/music#mast_in_the_mist"]).to_equal(nil)
		-- the world tileset has 128 columns and 31 rows
		expect(max_tile <= 128 * 31).to_equal(true)

		local ships = 0
		for _ in pairs(objects) do
			ships = ships + 1
		end
		expect(ships).to_equal(1)

		-- sail back and dock in Lisbon
		input_state.on_key("d", true, false)
		for _ = 1, 200 do
			env.update(self, 0.05)
			input_state.on_key("e", false, true)
			if state.port_id then
				break
			end
		end
		input_state.on_key("d", false, true)
		expect(state.port_id).to_equal("1")
	end)
end)
