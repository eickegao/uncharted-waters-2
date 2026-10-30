-- The Mates, Fleet and Items windows opened from the left panel while in port
local ui = require "modules.ui.ui"
local widgets = require "modules.ui.widgets"
local colors = require "modules.ui.colors"
local selectors = require "modules.state.selectors"
local selectors_fleet = require "modules.state.selectors_fleet"
local sailor_data = require "modules.data.sailor_data"
local character_data = require "modules.data.character_data"
local item_data = require "modules.data.item_data".item_data
local utils = require "modules.utils"

local M = {}

local function mates(x, y)
	local list = selectors.get_mates()
	local w, h = 280 + 640, 720
	local cx, cy = widgets.message_box(x, y, w + 32, h + 32)

	local selected = widgets.menu("mates", cx, cy, 280, utils.map(list, function(mate, i)
		return { label = mate.name, value = i }
	end), {})

	local mate = list[selected]
	local character = character_data[mate.sailor_id]
	local dx, dy = cx + 280 + 32, cy + 32

	ui.image(dx, dy, 128, 160, "character_" .. mate.sailor_id)
	ui.text(dx + 160, dy + 24, mate.name, { font = "b36", color = character and colors[character.color] or colors.black })
	ui.text(dx + 160, dy + 68, "Age " .. mate.age, { font = "r18", color = colors.gray_500 })
	ui.text(dx + 160, dy + 112, selectors.get_role_display(mate.role))
	ui.text(dx + 160, dy + 144, "Loyal to Portugal")

	local left_x, left_w = dx, 288
	local row_y = dy + 160 + 32

	local function row(label, value, font, color)
		ui.text(left_x, row_y, label, { font = font, color = color })
		ui.text(left_x, row_y, value, { font = font, color = color, w = left_w, align = "right" })
	end

	if mate.sailor_id == "1" then
		row("Rank", "None")
	else
		row("Wages", "10")
	end

	row_y = row_y + 64
	row("Navigation Level", mate.navigationLevel)
	row_y = row_y + 40
	left_x = dx + 16
	left_w = 288 - 16
	row("Experience", "0", "r18", colors.gray_500)
	left_x, left_w = dx, 288

	row_y = row_y + 44
	row("Battle Level", mate.battleLevel)
	row_y = row_y + 40
	left_x = dx + 16
	left_w = 288 - 16
	row("Experience", "0", "r18", colors.gray_500)
	left_x, left_w = dx, 288

	row_y = row_y + 60
	ui.text(dx, row_y, "Skills")
	row_y = row_y + 40
	for _, skill in ipairs(sailor_data.sailor_skills) do
		local has_skill = utils.includes(mate.skills, skill)
		ui.text(dx + 16, row_y, skill, {
			font = has_skill and "b18" or "r18",
			color = has_skill and colors.orange_700 or colors.orange_200,
		})
		row_y = row_y + 36
	end

	local stat_x = dx + 288 + 64
	local stat_y = dy + 160 + 32
	for _, stat in ipairs(sailor_data.stat_names) do
		if stat ~= "luck" then
			local value = mate.stats[stat]
			ui.text(stat_x, stat_y, stat:sub(1, 1):upper() .. stat:sub(2), { font = "r18" })
			widgets.progress_bar(stat_x, stat_y + 32, 144, value)
			ui.text(stat_x, stat_y + 8, value, { w = 224, align = "right" })
			stat_y = stat_y + 68
		end
	end
end

local FLEET_POSITIONS = {
	{ x = 512, y = 320 },
	{ x = 768, y = 128 },
	{ x = 256, y = 128 },
}

local function fleet(x, y)
	local cx, cy = widgets.message_box(x, y, 1280 + 32, 608 + 32)
	ui.image(cx, cy, 1280, 608, "fleet_background")
	for i, ship in ipairs(selectors_fleet.get_player_fleet()) do
		local position = FLEET_POSITIONS[i]
		if position then
			ui.image(cx + position.x, cy + position.y, 256, 192, "ship_" .. ship.id)
		end
	end
end

local function items(x, y)
	local list = selectors.get_player_items()

	if #list == 0 then
		local cx, cy = widgets.message_box(x, y, 256 + 32, 48 + 32)
		ui.text(cx + 16, cy + 8, "You have no items.")
		return
	end

	local cx, cy = widgets.message_box(x, y, 280 + 736 + 32, 304 + 32)
	local selected = widgets.menu("items", cx, cy, 280, utils.map(list, function(item, i)
		return { label = item.name, value = i }
	end), {})

	widgets.item_info(cx + 280, cy, item_data[list[selected].id])
end

M.list = {
	{ label = "Mates", draw = mates, height = 752 },
	{ label = "Fleet", draw = fleet, height = 640 },
	{ label = "Items", draw = items, height = 336 },
}

return M
