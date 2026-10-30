--[[
  Returns the three message boxes shown in a building for the given step of a
  conversation: the vendor (1) and the two character boxes (2 and 3).
  Characters who spoke earlier remain visible with an empty message box.
]]
local POSITIONS = { 0, 1, 2 }

local function replace_names(body)
	return (body:gsub("%$firstName", "João"):gsub("%$lastName", "Franco"))
end

local function get_message_boxes(messages, step)
	local message = messages[step]
	local body = replace_names(message.body)
	local boxes = {}

	for i, position in ipairs(POSITIONS) do
		local box = false

		if message.position == position then
			if position == 0 then
				box = { body = body }
			else
				box = { body = body, character_id = message.characterId }
			end
		else
			for j = step - 1, 1, -1 do
				local earlier = messages[j]
				if earlier.position == position then
					if position == 0 then
						box = { body = "" }
					else
						box = { body = "", character_id = earlier.characterId }
					end
					break
				end
			end
		end

		-- false rather than nil so that the table keeps all three entries
		boxes[i] = box
	end

	return boxes
end

return get_message_boxes
