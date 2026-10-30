local map_module = require "modules.map"
local percent_next_move = require "modules.percent_next_move"
local create_building = require "modules.port.building"
local create_port_characters = require "modules.port.port_characters"
local port_utils = require "modules.port.port_utils"
local selectors = require "modules.state.selectors"
local actions_port = require "modules.state.actions_port"
local shared_utils = require "modules.world.shared_utils"
local constants = require "modules.constants"

local WIDTH = constants.CAMERA_WIDTH / constants.TILE_SIZE
local HEIGHT = constants.CAMERA_HEIGHT / constants.TILE_SIZE

local function create_port(port_id)
	local port_data = port_utils.get_port_data(port_id)
	local map = map_module.create(port_data)
	local building = create_building(port_id)
	local characters = create_port_characters(map, building, port_data.is_supply_port, actions_port.enter_building)

	if selectors.is_day() then
		characters.spawn_npcs()
	end

	local port = { map = map }

	function port.update(dt)
		percent_next_move.update(dt)

		if percent_next_move.get() ~= 0 then
			return
		end

		characters.update()
	end

	-- what main/game.script needs to render the port
	function port.view()
		local player = characters.player()
		local percent = percent_next_move.get()
		local camera = shared_utils.get_camera_position(player, { width = WIDTH, height = HEIGHT }, map, percent, false)

		local drawn = { player }
		for _, npc in ipairs(characters.npcs()) do
			drawn[#drawn + 1] = npc
		end

		local sprites = {}
		for i, character in ipairs(drawn) do
			local position = character.position(percent)
			sprites[i] = {
				x = math.floor((position.x - camera.x) * constants.TILE_SIZE),
				y = math.floor((position.y - camera.y) * constants.TILE_SIZE),
				frame = character.frame(),
			}
		end

		return {
			camera = camera,
			map = map,
			time_of_day = selectors.get_time_of_day(),
			sprites = sprites,
		}
	end

	function port.characters()
		return characters
	end

	return port
end

return create_port
