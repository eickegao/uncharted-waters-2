local M = {}

M.direction_to_changes = {
	n = { x_delta = 0, y_delta = -1, frame_offset = 0 },
	e = { x_delta = 1, y_delta = 0, frame_offset = 2 },
	s = { x_delta = 0, y_delta = 1, frame_offset = 4 },
	w = { x_delta = -1, y_delta = 0, frame_offset = 6 },
	ne = { x_delta = 1, y_delta = -1, frame_offset = 2 },
	se = { x_delta = 1, y_delta = 1, frame_offset = 2 },
	sw = { x_delta = -1, y_delta = 1, frame_offset = 6 },
	nw = { x_delta = -1, y_delta = -1, frame_offset = 6 },
}

-- "" means no direction
M.direction_map = {
	n = 0,
	ne = 1,
	e = 2,
	se = 3,
	s = 4,
	sw = 5,
	w = 6,
	nw = 7,
	[""] = 8,
}

return M
