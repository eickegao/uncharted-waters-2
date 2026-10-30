local input_state = require "modules.input_state"
local ui_bridge = require "modules.state.ui_bridge"
local create_port_player = require "modules.port.port_player"
local create_port_npc = require "modules.port.port_npc"
local port_characters_data = require "modules.data.port_characters_data"
local utils = require "modules.utils"

local function create_port_characters(map, building, is_supply_port, enter_building)
	local player_data = port_characters_data.port_player_data
	local player = create_port_player(
		utils.apply_position_delta(building.get(player_data.spawn.building_id), player_data.spawn.offset),
		port_characters_data.get_start_frame(player_data.type),
		"s",
		enter_building
	)

	local npcs = {}

	local function collision_others_at(position, self)
		local function check(character)
			if character == self then
				return false
			end
			local other = character.destination() or character.position()
			return math.abs(position.x - other.x) < 2 and math.abs(position.y - other.y) < 2
		end

		if check(player) then
			return true
		end
		for _, npc in ipairs(npcs) do
			if check(npc) then
				return true
			end
		end
		return false
	end

	local function collision_at(position, self)
		return map.collision_at(position) or collision_others_at(position, self)
	end

	local characters = {}

	function characters.update()
		player.update()
		for _, npc in ipairs(npcs) do
			npc.update()
		end

		--[[
		  When entering a building, we want the movement towards the door to
		  be rendered.
		  At the same time, we want to prevent the rare case where an NPC could
		  be blocking when we exit. To accomplish this, NPC movement is skipped
		  both when entering and exiting.
		]]
		if player.entered_building() then
			return
		end

		local direction = ui_bridge.popover_open and "" or input_state.get_direction(false)

		if direction ~= "" then
			player.move(direction, function(position)
				return collision_at(position, player)
			end)
		end

		if player.will_enter_building(building.at) then
			return
		end

		for _, npc in ipairs(npcs) do
			if npc.should_move() then
				npc.move(function(position)
					return collision_at(position, npc)
				end)
			end
		end
	end

	function characters.spawn_npcs()
		if #npcs > 0 or is_supply_port then
			return
		end

		for _, npc in ipairs(port_characters_data.port_npc_data) do
			-- TODO implement blockade
			if npc.type ~= "GUARD" then
				npcs[#npcs + 1] = create_port_npc(
					utils.apply_position_delta(building.get(npc.spawn.building_id), npc.spawn.offset),
					port_characters_data.get_start_frame(npc.type),
					"s",
					npc.is_stationary or false
				)
			end
		end
	end

	function characters.despawn_npcs()
		npcs = {}
	end

	function characters.player()
		return player
	end

	function characters.npcs()
		return npcs
	end

	return characters
end

return create_port_characters
