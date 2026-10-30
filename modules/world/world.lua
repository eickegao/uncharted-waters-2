local map_module = require "modules.map"
local percent_next_move = require "modules.percent_next_move"
local world_characters = require "modules.world.world_characters"
local selectors = require "modules.state.selectors"
local actions_world = require "modules.state.actions_world"
local shared_utils = require "modules.world.shared_utils"
local constants = require "modules.constants"

local WIDTH = constants.CAMERA_WIDTH / constants.TILE_SIZE
local HEIGHT = constants.CAMERA_HEIGHT / constants.TILE_SIZE

local function create_world()
	local map = map_module.create()
	local characters = world_characters.create(map)

	local world = { map = map }

	function world.update(dt)
		percent_next_move.update(dt)

		if percent_next_move.get() ~= 0 then
			return
		end

		actions_world.world_time_tick()
		characters.update()
	end

	function world.view()
		local player = characters.player()
		local percent = percent_next_move.get()
		local camera = shared_utils.get_camera_position(player, { width = WIDTH, height = HEIGHT }, map, percent, true)

		-- player drawn last as there's no collision at sea
		local drawn = {}
		for _, npc in ipairs(characters.npcs()) do
			drawn[#drawn + 1] = npc
		end
		drawn[#drawn + 1] = player

		local sprites = {}
		for i, character in ipairs(drawn) do
			local position = character.position(percent)
			sprites[i] = {
				x = math.floor(shared_utils.get_from_to_accounting_for_wrap_around(camera.x, position.x) * constants.TILE_SIZE),
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

	function world.characters()
		return characters
	end

	return world
end

return create_world
