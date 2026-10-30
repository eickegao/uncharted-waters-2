-- Reusable pieces of the interface. Positions are screen coordinates from the top-left.
local ui = require "modules.ui.ui"
local colors = require "modules.ui.colors"
local constants = require "modules.constants"
local item_data_module = require "modules.data.item_data"
local ship_data = require "modules.data.ship_data".ship_data

local M = {}

M.PADDING = 16

local BORDERS = {
	{ 2, colors.border_red },
	{ 4, colors.border_orange },
	{ 6, colors.border_red },
	{ 10, colors.border_green },
	{ 12, colors.border_red },
	{ 14, colors.message_box },
}

-- the framed beige box used for all dialogs; w and h include the 16px frame
function M.message_box(x, y, w, h)
	ui.box(x, y, w, h, colors.black)
	for _, border in ipairs(BORDERS) do
		local inset, color = border[1], border[2]
		ui.box(x + inset, y + inset, w - inset * 2, h - inset * 2, color)
	end

	ui.image(x, y, 16, 16, "dialog_corner")
	ui.image(x + w - 16, y, 16, 16, "dialog_corner", { rotation = 90 })
	ui.image(x + w - 16, y + h - 16, 16, 16, "dialog_corner", { rotation = 180 })
	ui.image(x, y + h - 16, 16, 16, "dialog_corner", { rotation = 270 })

	-- clicking a dialog shouldn't fall through to whatever is below
	ui.region(x, y, w, h)

	return x + M.PADDING, y + M.PADDING
end

local MENU_ITEM_HEIGHT = 40
local MENU_ITEM_MARGIN = 8

function M.menu_height(count)
	return count * MENU_ITEM_HEIGHT + (count + 1) * MENU_ITEM_MARGIN
end

--[[
  A list of options navigated with W/S (or arrow keys) and selected with
  E/Enter or by clicking.

  options: list of { label, value, disabled }
  opts: on_select(value), on_cancel(), hidden, center
  Returns the index of the highlighted option.
]]
function M.menu(key, x, y, w, options, opts)
	local widget = ui.widget(key, function()
		return { active = 1 }
	end)

	if widget.active > #options then
		widget.active = math.max(1, #options)
	end

	if opts.hidden then
		return widget.active
	end

	for i, option in ipairs(options) do
		local item_y = y + MENU_ITEM_MARGIN + (i - 1) * (MENU_ITEM_HEIGHT + MENU_ITEM_MARGIN)
		local text_color = colors.black

		if widget.active == i then
			ui.box(x, item_y, w, MENU_ITEM_HEIGHT, colors.black)
			text_color = option.disabled and colors.gray_400 or colors.white
		elseif option.disabled then
			text_color = colors.gray_400
		end

		if opts.center then
			ui.text(x, item_y + 4, option.label, { w = w, align = "center", color = text_color })
		else
			ui.text(x + 16, item_y + 4, option.label, { color = text_color })
		end

		ui.region(x, item_y, w, MENU_ITEM_HEIGHT, {
			click = function()
				widget.active = i
				if not option.disabled and opts.on_select then
					opts.on_select(option.value)
				end
			end,
		})
	end

	ui.on_key(function(k)
		if ui.CANCEL[k] then
			if opts.on_cancel then
				opts.on_cancel()
				return true
			end
			return false
		end

		if #options == 0 then
			return false
		end

		if ui.CONFIRM[k] then
			local option = options[widget.active]
			if not option.disabled and opts.on_select then
				opts.on_select(option.value)
			end
			return true
		end

		if k == "s" or k == "down" then
			widget.active = widget.active % #options + 1
			return true
		end

		if k == "w" or k == "up" then
			widget.active = (widget.active - 2) % #options + 1
			return true
		end

		return false
	end)

	return widget.active
end

-- a menu inside a message box, as shown in buildings
function M.building_menu(key, x, y, options, opts)
	local w = opts.level2 and 280 or 208
	local title_height = (opts.title and opts.title ~= "") and 64 or 0
	local h = title_height + M.menu_height(#options)

	-- keep the highlighted option even while the menu is hidden
	if opts.hidden then
		M.menu(key, 0, 0, w, options, opts)
		return
	end

	local cx, cy = M.message_box(x, y, w + M.PADDING * 2, h + M.PADDING * 2)

	if title_height > 0 then
		ui.box(cx, cy, w, 48, colors.orange_200)
		ui.text(cx, cy + 8, opts.title, { w = w, align = "center" })
	end

	M.menu(key, cx, cy + title_height, w, options, {
		on_select = opts.on_select,
		on_cancel = opts.on_cancel,
		center = not opts.level2,
	})
end

-- the red/blue bar used for load percentages and sailor stats
function M.progress_bar(x, y, w, percent)
	percent = math.max(0, math.min(100, percent))

	local inner_x = x + 8
	local inner_w = w - 18

	ui.box(x, y, 8, 12, colors.progress_light_blue)
	ui.box(inner_x, y, 2, 12, colors.black)
	ui.box(inner_x + 2, y, inner_w - 4, 2, colors.black)
	ui.box(inner_x + 2, y + 2, inner_w - 4, 8, colors.progress_blue)
	if percent > 0 then
		ui.box(inner_x + 2, y + 2, (inner_w - 4) * percent / 100, 8, colors.border_red)
	end
	ui.box(x + w - 10, y, 8, 12, colors.blue_400)
	ui.box(x + w - 2, y, 2, 12, colors.black)
	ui.box(x, y + 12, w, 2, colors.black)
end

-- the blinking arrow shown when a message is waiting to be acknowledged
function M.caret(x, y, w)
	ui.image(x + w / 2 - 16, y, 32, 32, "dialog_caret_down", { blink = true })
end

-- click anywhere on the camera, or press E/Enter/Escape to continue
function M.acknowledge(on_acknowledge)
	local function acknowledge()
		on_acknowledge()
	end

	ui.region(constants.CAMERA_X, 0, constants.CAMERA_WIDTH, constants.CAMERA_HEIGHT, {
		click = acknowledge,
		right = acknowledge,
	})

	ui.on_key(function(k)
		if ui.CONFIRM[k] or ui.CANCEL[k] then
			acknowledge()
			return true
		end
		return false
	end)
end

local SUBMIT_DELAY_IF_NOT_HIGHLIGHTED = 0.05
local CONFIRM_WIDTH = 288
local CONFIRM_HEIGHT = 112

--[[
  The Yes/No dialog. It can be dragged around by its top edge, as in the
  original game. A click on the option that isn't highlighted first
  highlights it, then submits shortly after.
]]
function M.confirm(key, on_yes, on_no, initial_position)
	local widget = ui.widget(key, function()
		return {
			yes = true,
			x = initial_position.x,
			y = initial_position.y,
			last_mouse = nil,
		}
	end)

	local function submit(yes)
		if yes then
			on_yes()
		else
			on_no()
		end
	end

	local function choose(yes)
		if widget.yes == yes then
			submit(yes)
		else
			widget.yes = yes
			ui.after(SUBMIT_DELAY_IF_NOT_HIGHLIGHTED, function()
				submit(yes)
			end)
		end
	end

	local x = constants.CAMERA_X + widget.x
	local y = widget.y

	ui.image(x, y, CONFIRM_WIDTH, CONFIRM_HEIGHT, widget.yes and "dialog_yes" or "dialog_no")
	ui.region(x, y, CONFIRM_WIDTH, CONFIRM_HEIGHT)
	ui.region(x, y, CONFIRM_WIDTH, 28, {
		down = function(mx, my)
			widget.last_mouse = { x = mx, y = my }
		end,
	})
	ui.region(x + 20, y + 32, 120, 64, {
		click = function()
			choose(true)
		end,
	})
	ui.region(x + 148, y + 32, 120, 64, {
		click = function()
			choose(false)
		end,
	})

	ui.on_mouse(function(event, mx, my)
		if not widget.last_mouse then
			return false
		end

		if event == "release" then
			widget.last_mouse = nil
			return false
		end

		local new_x = widget.x + mx - widget.last_mouse.x
		local new_y = widget.y + my - widget.last_mouse.y
		widget.last_mouse = { x = mx, y = my }

		local max_x = constants.CAMERA_WIDTH - CONFIRM_WIDTH
		local max_y = constants.CAMERA_HEIGHT - CONFIRM_HEIGHT

		if new_x < 0 or new_y < 0 or new_x > max_x or new_y > max_y then
			widget.last_mouse = nil
		end

		widget.x = math.max(0, math.min(max_x, new_x))
		widget.y = math.max(0, math.min(max_y, new_y))
		return true
	end)

	ui.on_key(function(k)
		if k == "a" or k == "d" or k == "left" or k == "right" then
			widget.yes = not widget.yes
			return true
		end
		if ui.CONFIRM[k] then
			submit(widget.yes)
			return true
		end
		if ui.CANCEL[k] then
			on_no()
			return true
		end
		return false
	end)
end

local INPUT_HEIGHT = 52

-- the text field and submit button shared by number and name inputs
local function input_field(x, y, w, value, on_submit, on_click_input)
	local input_w = w - 92 - 16

	ui.box(x, y, input_w, INPUT_HEIGHT, colors.border_red)
	ui.box(x + 2, y + 2, input_w - 4, INPUT_HEIGHT - 4, colors.white)
	ui.text(x + 18, y + 10, value .. "|")
	ui.region(x, y, input_w, INPUT_HEIGHT, { click = on_click_input })

	ui.image(x + input_w + 16, y + INPUT_HEIGHT - 44, 92, 44, "dialog_submit")
	ui.region(x + input_w + 16, y + INPUT_HEIGHT - 44, 92, 44, { click = on_submit })
end

M.INPUT_HEIGHT = INPUT_HEIGHT

--[[
  Asks for an amount between 0 and limit. Without opts.position, it's shown
  in its own message box; otherwise it's drawn inline at that position with
  width opts.w.
]]
function M.input_number(key, limit, on_complete, on_cancel, opts)
	opts = opts or {}

	local widget = ui.widget(key, function()
		return { value = 0 }
	end)

	local function submit()
		on_complete(widget.value)
	end

	local x, y, w
	if opts.position then
		x, y, w = opts.position.x, opts.position.y, opts.w
	else
		local box_x, box_y = constants.CAMERA_X + 96, 500
		x, y = M.message_box(box_x, box_y, 450 + 32, INPUT_HEIGHT + 32 + 32)
		x, y, w = x + 16, y + 16, 450 - 32
	end

	input_field(x, y, w, widget.value > 0 and tostring(widget.value) or "", submit, function()
		widget.value = 0
	end)

	ui.on_text(function(text)
		if text:match("^%d+$") then
			local value = tonumber(tostring(widget.value) .. text)
			widget.value = math.max(0, math.min(limit, value))
		end
	end)

	ui.on_key(function(k)
		if k == "enter" then
			submit()
		elseif k == "escape" then
			on_cancel()
		elseif k == "backspace" then
			widget.value = math.floor(widget.value / 10)
		end
		-- the field has focus: nothing else should react to the keyboard
		return true
	end)
end

local MAX_NAME_LENGTH = 20

local function utf8_remove_last(text)
	local length = #text
	while length > 0 do
		local byte = text:byte(length)
		length = length - 1
		-- stop at the first byte of a UTF-8 sequence
		if byte < 0x80 or byte >= 0xC0 then
			break
		end
	end
	return text:sub(1, length)
end

function M.input_name(key, on_submit, on_cancel)
	local widget = ui.widget(key, function()
		return { value = "" }
	end)

	local function submit()
		-- the name is required
		if widget.value:match("%S") then
			on_submit(widget.value)
		end
	end

	local x, y = M.message_box(constants.CAMERA_X + 96, 500, 450 + 32, 32 + 32 + 16 + INPUT_HEIGHT + 32)
	ui.text(x + 16, y + 16, "Ship name?")
	input_field(x + 16, y + 64, 450 - 32, widget.value, submit)

	ui.on_text(function(text)
		if #widget.value + #text <= MAX_NAME_LENGTH then
			widget.value = widget.value .. text
		end
	end)

	ui.on_key(function(k)
		if k == "enter" then
			submit()
		elseif k == "escape" then
			on_cancel()
		elseif k == "backspace" then
			widget.value = utf8_remove_last(widget.value)
		end
		return true
	end)
end

-- name, category, rating and description of an item within a 736x304 area
function M.item_info(x, y, item)
	local name_node = ui.text(x + 64, y + 32, item.name, { color = colors.blue_600 })
	ui.text(x + 64 + ui.text_width(name_node) + 16, y + 32, "(" .. item_data_module.item_categories[item.categoryId] .. ")")

	local display = item_data_module.get_attack_or_defense_display(item.rating, item.categoryId)
	if display then
		local label = ui.text(x + 64, y + 64, display.label, { font = "r16" })
		ui.text(x + 64 + ui.text_width(label) + 8, y + 64, display.letter, { font = "r16", color = colors.red_600 })
	end

	ui.image(x + 64, y + 152 - 48, 96, 96, "item_" .. item.imageSlice)
	local description = ui.text(x + 64 + 96 + 64, y, item.description, { w = 736 - 128 - 96 - 64, wrap = true })
	gui.set_position(description, vmath.vector3(x + 224, constants.SCREEN_HEIGHT - (y + 144 - ui.text_height(description) / 2), 0))
end

-- the scroll-like box showing an item, positioned within the camera
function M.item_box(item)
	local x, y = constants.CAMERA_X, 256
	ui.image(x, y, 736, 304, "dialog_ship")
	M.item_info(x, y, item)
end

-- the scroll-like box showing a ship model's stats, positioned within the camera
function M.ship_box(ship_id, custom_name)
	local data = ship_data[ship_id]
	local x, y = constants.CAMERA_X, 256

	ui.image(x, y, 736, 304, "dialog_ship")
	ui.image(x + 32, y + 56, 256, 192, "ship_" .. ship_id)

	local px = x + 32 + 256 + 32
	local pw = 736 - 64 - 256 - 32
	local col_w = (pw - 32) / 2

	ui.text(px, y + 24, custom_name or data.name, { w = pw, align = "center", color = colors.blue_600 })

	local cargo = data.capacity - data.usedGuns - data.usedCrew
	local rows = {
		{ 1, 1, "Durability", data.durability },
		{ 2, 1, "Tacking", data.tacking },
		{ 2, 2, "Power", data.power },
		{ 3, 1, "Capacity", data.capacity },
		{ 3, 2, "Cargo", cargo },
		{ 4, 0, "Guns (Max/Remodel)", data.usedGuns .. "/" .. data.maximumGuns },
		{ 5, 0, "Crew (Min/Max)", data.minimumCrew .. "/" .. data.usedCrew },
		{ 6, 0, "Max Crew (Remodel)", data.maximumCrew },
	}

	for _, row in ipairs(rows) do
		local row_y = y + 72 + (row[1] - 1) * 36
		local cell_x = row[2] == 2 and px + col_w + 32 or px
		local cell_w = row[2] == 0 and pw or col_w
		ui.text(cell_x, row_y + 10, row[3], { font = "r16" })
		ui.text(cell_x, row_y, row[4], { w = cell_w, align = "right" })
	end
end

return M
