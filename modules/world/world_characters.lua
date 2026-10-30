local input_state = require "modules.input_state"
local state = require "modules.state.state"
local selectors = require "modules.state.selectors"
local actions_world = require "modules.state.actions_world"
local create_world_player = require "modules.world.world_player"
local create_world_npc = require "modules.world.world_npc"
local world_utils = require "modules.world.world_utils"

local FRAMES_PER_SHIP = 8
local SHIP_VARIANTS = 2

local M = {}

function M.get_start_frame(flagship, is_player)
	local start_frame = world_utils.has_oars(flagship.id) and 0 or FRAMES_PER_SHIP
	if is_player then
		return start_frame
	end
	return start_frame + FRAMES_PER_SHIP * SHIP_VARIANTS
end

function M.create(map)
	local player_fleet = state.fleets[1]

	if not player_fleet.position then
		error("Player fleet has no position")
	end

	local player = create_world_player(
		player_fleet.position,
		M.get_start_frame(player_fleet.ships[1], true),
		"n",
		selectors.get_captain
	)

	local npcs = {}

	for id = 2, #state.fleets do
		local fleet = state.fleets[id]
		if not fleet.position then
			error("NPC fleet has no position")
		end
		npcs[#npcs + 1] = create_world_npc(fleet.position, M.get_start_frame(fleet.ships[1]), "n", true)
	end

	local function collision(position)
		return map.collision_at(position)
	end

	local characters = {}

	function characters.update()
		player.update()

		-- keeps wind and current in sync with the sea area the fleet is in
		player_fleet.position = player.position()

		if input_state.get_pressed_e() and actions_world.dock(player.position()) then
			player.set_heading("")
			return
		end

		local direction = input_state.get_direction(true)

		-- this check allows the player to keep their heading even after releasing input
		if direction ~= "" then
			player.set_heading(direction)
		end

		player.update_speed()

		local heading = player.heading()
		if heading ~= "" then
			player.move(heading, collision)
		end

		for _, npc in ipairs(npcs) do
			npc.update()
			if npc.should_move() then
				npc.move()
			end
		end
	end

	function characters.player()
		return player
	end

	function characters.npcs()
		return npcs
	end

	return characters
end

return M
