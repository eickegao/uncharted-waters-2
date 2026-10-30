--[[
  Draws a building screen: the vendor with their message box, up to two
  character message boxes, the menus and anything else the building shows.

  view:
    building_id: decides the vendor image
    vendor: { body, acknowledge, confirm } or nil
    character: { body, character_id, acknowledge, confirm } or nil
    menu, menu2: functions drawing a menu at the given position
    children: function drawing anything else
    dark: only show the character message box, on a black background

  If a quest is in progress, its messages replace the vendor and character
  messages, and the menus are hidden.
]]
local ui = require "modules.ui.ui"
local widgets = require "modules.ui.widgets"
local colors = require "modules.ui.colors"
local constants = require "modules.constants"
local character_data = require "modules.data.character_data"
local sailor_data = require "modules.data.sailor_data"

local M = {}

local CX = constants.CAMERA_X

local function message_text(x, y, w, box)
	local node = ui.text(x, y, box.body, { w = w, wrap = true })
	if box.acknowledge then
		local height = box.body ~= "" and ui.text_height(node) or 0
		widgets.caret(x, y + height + 32, w)
	end
end

local function vendor_message_box(building_id, box)
	ui.image(CX + 16, 16, 272, 224, "building_" .. building_id)

	if not box then
		return
	end

	local x, y = widgets.message_box(CX + 288, 0, 448 + 32, 224 + 32)
	message_text(x + 16, y + 8, 448 - 32, box)
end

local CHARACTER_POSITIONS = {
	[1] = { x = 304, y = 16 },
	[2] = { x = 416, y = 320 },
}

local function character_message_box(box, position)
	if not box then
		return
	end

	local p = CHARACTER_POSITIONS[position]
	local x, y = widgets.message_box(CX + p.x, p.y, 592 + 32, 256 + 32)
	x, y = x + 16, y + 16

	local character = character_data[box.character_id]
	local name, color
	if character then
		name, color = character.name, colors[character.color]
	else
		name, color = sailor_data.get_sailor(box.character_id).name, colors.black
	end

	ui.image(x, y, 128, 160, "character_" .. box.character_id)
	ui.text(x + 144, y, name, { font = "r16", color = color })
	message_text(x + 144, y + 32, 592 - 32 - 128 - 16, box)
end

function M.draw(view, quest)
	local boxes
	local menu, menu2 = view.menu, view.menu2

	local quest_boxes = quest and quest.message_boxes()
	if quest_boxes then
		boxes = {
			quest_boxes[1] or nil,
			quest_boxes[2] or nil,
			quest_boxes[3] or nil,
		}
		menu, menu2 = nil, nil
	else
		boxes = { view.vendor, nil, view.character }
	end

	local acknowledge, confirm
	for i = 1, 3 do
		local box = boxes[i]
		if box then
			acknowledge = acknowledge or box.acknowledge
			confirm = confirm or box.confirm
		end
	end

	if not view.dark then
		ui.image(CX, 0, 1280, 896, "building_background")
		vendor_message_box(view.building_id, boxes[1])
		character_message_box(boxes[2], 1)
		character_message_box(boxes[3], 2)

		if menu then
			menu(CX + 768, 190)
		end
		if menu2 then
			menu2(CX + 696, 190)
		end
	else
		ui.box(CX, 0, constants.CAMERA_WIDTH, constants.CAMERA_HEIGHT, colors.black)
		character_message_box(boxes[3], 2)
	end

	if view.children then
		view.children()
	end

	if confirm then
		-- keyed by the question so that a new question gets a fresh dialog
		local body = (boxes[1] and boxes[1].confirm and boxes[1].body)
			or (boxes[2] and boxes[2].confirm and boxes[2].body)
			or (boxes[3] and boxes[3].body)
			or ""
		widgets.confirm("confirm:" .. body, confirm.yes, confirm.no, { x = 760, y = 290 })
	end

	if acknowledge then
		widgets.acknowledge(acknowledge)
	end
end

return M
