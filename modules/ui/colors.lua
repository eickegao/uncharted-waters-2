-- Tailwind colors used by the browser version
local M = {}

local function hex(value, alpha)
	local r = tonumber(value:sub(2, 3), 16) / 255
	local g = tonumber(value:sub(4, 5), 16) / 255
	local b = tonumber(value:sub(6, 7), 16) / 255
	return vmath.vector4(r, g, b, alpha or 1)
end

M.hex = hex

M.white = hex("#ffffff")
M.black = hex("#000000")
M.hud = hex("#aaaaaa")
M.overlay = hex("#000000", 0.75)
M.message_box = hex("#f3e3d3")
M.border_red = hex("#d34100")
M.border_orange = hex("#f3a261")
M.border_green = hex("#00a261")
M.progress_light_blue = hex("#00a2f3")
M.progress_blue = hex("#0041d3")

M.blue_400 = hex("#60a5fa")
M.blue_600 = hex("#2563eb")
M.blue_900 = hex("#1e3a8a")
M.red_600 = hex("#dc2626")
M.yellow_600 = hex("#ca8a04")
M.amber_600 = hex("#d97706")
M.amber_800 = hex("#92400e")
M.purple_600 = hex("#9333ea")
M.purple_800 = hex("#6b21a8")
M.pink_600 = hex("#db2777")
M.green_600 = hex("#16a34a")
M.lime_400 = hex("#a3e635")
M.gray_400 = hex("#9ca3af")
M.gray_500 = hex("#6b7280")
M.gray_800 = hex("#1f2937")
M.orange_200 = hex("#fed7aa")
M.orange_700 = hex("#c2410c")

return M
