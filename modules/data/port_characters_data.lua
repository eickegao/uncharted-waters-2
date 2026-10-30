local M = {}

local port_character_types = {
	"PLAYER",
	"WOMAN",
	"MAN",
	"MERCHANT",
	"DOG",
	"GUARD",
	"BEGGAR",
}

M.port_player_data = {
	type = "PLAYER",
	spawn = { building_id = "4", offset = { x = 0, y = 1 } },
}

M.port_npc_data = {
	{ type = "WOMAN", spawn = { building_id = "1", offset = { x = -2, y = 1 } } },
	{ type = "WOMAN", spawn = { building_id = "3", offset = { x = 0, y = 0 } } },
	{ type = "MAN", spawn = { building_id = "2", offset = { x = -2, y = 1 } } },
	{ type = "MAN", spawn = { building_id = "5", offset = { x = -2, y = 1 } } },
	{ type = "MERCHANT", spawn = { building_id = "1", offset = { x = 2, y = 1 } }, is_stationary = true },
	{ type = "DOG", spawn = { building_id = "2", offset = { x = 2, y = 1 } }, is_stationary = true },
	{ type = "GUARD", spawn = { building_id = "4", offset = { x = -2, y = 2 } }, is_stationary = true },
	{ type = "GUARD", spawn = { building_id = "4", offset = { x = 0, y = 3 } }, is_stationary = true },
	{ type = "GUARD", spawn = { building_id = "4", offset = { x = 2, y = 2 } }, is_stationary = true },
	{ type = "BEGGAR", spawn = { building_id = "5", offset = { x = 2, y = 1 } }, is_stationary = true },
}

local FRAMES_PER_CHARACTER = 8
local FRAMES_PER_STATIONARY_CHARACTER = 2
local STATIONARY_FROM_I = 3

function M.get_start_frame(character_type)
	local i
	for index, t in ipairs(port_character_types) do
		if t == character_type then
			i = index - 1
		end
	end

	if not i then
		error("port character type not found")
	end

	if i <= STATIONARY_FROM_I then
		return i * FRAMES_PER_CHARACTER
	end

	return STATIONARY_FROM_I * FRAMES_PER_CHARACTER + (i - STATIONARY_FROM_I) * FRAMES_PER_STATIONARY_CHARACTER
end

return M
