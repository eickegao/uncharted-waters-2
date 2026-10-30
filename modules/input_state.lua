-- Keeps track of movement keys (WASD) and E for docking, mirroring how the
-- keyboard was read in the browser version.
local M = {}

local cardinal_key_map = {
	w = "n",
	d = "e",
	s = "s",
	a = "w",
}

local ordinal_key_map = {
	w = { d = "ne", a = "nw" },
	s = { d = "se", a = "sw" },
}

local PRESSED_E_TIME_MARGIN = 0.25

local pressed_wasd = {}
local pressed_e_timer = 0

local function remove(key)
	for i = #pressed_wasd, 1, -1 do
		if pressed_wasd[i] == key then
			table.remove(pressed_wasd, i)
		end
	end
end

-- key is one of "w", "a", "s", "d" or "e"
function M.on_key(key, pressed, released)
	if cardinal_key_map[key] then
		if pressed then
			remove(key)
			table.insert(pressed_wasd, 1, key)
		elseif released then
			remove(key)
		end
	end

	if key == "e" and released then
		pressed_e_timer = PRESSED_E_TIME_MARGIN
	end
end

function M.update(dt)
	if pressed_e_timer > 0 then
		pressed_e_timer = math.max(0, pressed_e_timer - dt)
	end
end

function M.get_direction(include_ordinal)
	if #pressed_wasd == 0 then
		return ""
	end

	if include_ordinal and #pressed_wasd > 1 then
		local first, second = pressed_wasd[1], pressed_wasd[2]
		local direction = (ordinal_key_map[first] and ordinal_key_map[first][second])
			or (ordinal_key_map[second] and ordinal_key_map[second][first])

		if direction then
			return direction
		end
	end

	return cardinal_key_map[pressed_wasd[1]]
end

function M.get_pressed_e()
	return pressed_e_timer > 0
end

function M.reset()
	pressed_wasd = {}
	pressed_e_timer = 0
end

return M
