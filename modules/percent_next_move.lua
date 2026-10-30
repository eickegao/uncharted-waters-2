-- Characters move in steps every 67ms; in between, their positions are
-- interpolated using this percentage.
local STEP = 0.067

local M = {}

local elapsed = 0
local percent = 0

function M.update(dt)
	elapsed = elapsed + dt
	if elapsed < STEP then
		percent = elapsed / STEP
	else
		elapsed = 0
		percent = 0
	end
end

function M.get()
	return percent
end

return M
