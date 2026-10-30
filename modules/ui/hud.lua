--[[
  Everything drawn around and on top of the camera: the side panels, the
  building screens, the Mates/Fleet/Items windows and the fade effect.
]]
local ui = require "modules.ui.ui"
local colors = require "modules.ui.colors"
local popovers = require "modules.ui.popovers"
local building_screen = require "modules.ui.building_screen"
local ui_bridge = require "modules.state.ui_bridge"
local interface_utils = require "modules.interface_utils"
local port_utils = require "modules.port.port_utils"
local constants = require "modules.constants"

local M = {}

local PANEL_WIDTH = constants.CAMERA_X
local RIGHT_X = constants.CAMERA_X + constants.CAMERA_WIDTH
local HEIGHT = constants.SCREEN_HEIGHT
local FADE_DURATION = 0.2

local current_building_id = nil
local building = nil
local open_popover = nil
local fade_progress = 0

local function label(x, y, text)
	ui.text(x, y, text, { font = "r14", color = colors.hud })
end

local function value(x, y, text, w)
	ui.text(x, y, text, { font = "r20", color = colors.hud, w = w or (PANEL_WIDTH - 40), align = "right" })
end

local function draw_provisions(y)
	local provisions = ui_bridge.provisions
	label(20, y, "Provisions")
	y = y + 36
	for _, provision in ipairs({ "water", "food", "lumber", "shot" }) do
		ui.image(20, y + 8, 32, 64, "world_" .. provision)
		value(20, y + 26, provisions[provision])
		y = y + 80
	end
end

local function draw_left(general)
	local in_port = general.port_id ~= nil

	ui.box(0, 0, PANEL_WIDTH, HEIGHT, colors.black)

	ui.text(20, 20, interface_utils.get_date(general.time_passed), { font = "b24", color = colors.hud })
	ui.text(20, 52, in_port and interface_utils.get_hours_minutes(general.time_passed) or ("Day " .. ui_bridge.day_at_sea), {
		font = "r18",
		color = colors.hud,
	})

	label(20, 160, "Ingots")
	value(20, 180, interface_utils.get_ingots(general.gold))
	label(20, 224, "Coins")
	value(20, 244, interface_utils.get_coins(general.gold))

	if not in_port then
		draw_provisions(368)
	else
		for i, popover in ipairs(popovers.list) do
			local y = 408 + (i - 1) * 68
			if open_popover == i then
				ui.box(0, y, PANEL_WIDTH, 68, colors.gray_800)
			end
			ui.text(20, y + 20, popover.label, { font = "r18", color = colors.hud, w = PANEL_WIDTH - 40, align = "right" })
			ui.region(0, y, PANEL_WIDTH, 68, {
				click = function()
					open_popover = i
				end,
			})
		end
	end

	local sound_on = ui_bridge.sound_on
	ui.text(20, 742, sound_on and "Sound on" or "Sound off", {
		font = "r18",
		color = sound_on and colors.lime_400 or colors.red_600,
		w = PANEL_WIDTH - 40,
		align = "right",
	})
	ui.region(0, 730, PANEL_WIDTH, 50, {
		click = function()
			ui_bridge.sound_on = not ui_bridge.sound_on
		end,
	})
end

local function draw_port_info(port_id)
	local port = port_utils.get_port_data(port_id)
	local economy, industry = 0, 0
	if not port.is_supply_port then
		economy, industry = port.economy, port.industry
	end

	local x = RIGHT_X + 20
	ui.text(x, 20, port.name, { font = "b24", color = colors.hud })
	ui.text(x, 52, port_utils.get_region_or_if_supply_port(port_id), { font = "r18", color = colors.hud })

	-- TODO Investments
	local rows = {
		{ "Economy", economy },
		{ "Investment", economy },
		{ "Industry", industry },
		{ "Investment", industry },
		{ "Price Index", "100%" },
	}
	local y = 160
	for _, row in ipairs(rows) do
		label(x, y, row[1])
		value(x, y + 20, row[2])
		y = y + 64
	end
end

local function draw_indicator(y, title, direction, speed, unit)
	local x = RIGHT_X + 20
	label(x, y, title)
	ui.image(x, y + 36, 80, 80, "indicator_" .. direction)
	ui.text(x, y + 52, speed, { font = "r36", color = colors.hud, w = PANEL_WIDTH - 40, align = "right" })
	if unit then
		ui.text(x, y + 96, unit, { font = "r14", color = colors.hud, w = PANEL_WIDTH - 40, align = "right" })
	end
end

local function draw_indicators()
	local indicators = ui_bridge.indicators
	local y = 170

	if indicators then
		draw_indicator(y, "Wind", indicators.wind.direction, indicators.wind.speed)
		draw_indicator(y + 148, "Current", indicators.current.direction, indicators.current.speed)
	end

	draw_indicator(y + 344, "Your fleet", ui_bridge.player_fleet_direction, math.floor(ui_bridge.player_fleet_speed / 2), "knots")
end

local function draw_right(general)
	ui.box(RIGHT_X, 0, PANEL_WIDTH, HEIGHT, colors.black)

	if general.port_id ~= nil then
		draw_port_info(general.port_id)
	else
		draw_indicators()
	end
end

local function draw_popover()
	local popover = popovers.list[open_popover]
	local function close()
		open_popover = nil
	end

	-- anything below the window shouldn't react while it's open
	ui.on_key(function(k)
		if ui.CANCEL[k] then
			close()
		end
		return true
	end)

	ui.box(0, 0, constants.SCREEN_WIDTH, HEIGHT, colors.overlay)
	ui.region(0, 0, constants.SCREEN_WIDTH, HEIGHT, { click = close, right = close })

	local label_center = 408 + (open_popover - 1) * 68 + 34
	local y = math.max(0, math.min(HEIGHT - popover.height, label_center - popover.height / 2))
	popover.draw(PANEL_WIDTH, y)
end

function M.update(dt)
	local general = ui_bridge.general

	if general.building_id ~= current_building_id then
		current_building_id = general.building_id
		building = current_building_id and building_screen.create(current_building_id) or nil
		ui.invalidate()
	end

	if general.port_id == nil then
		open_popover = nil
	end
	ui_bridge.popover_open = open_popover ~= nil

	if ui_bridge.fade_callback then
		fade_progress = fade_progress + dt / FADE_DURATION
		if fade_progress >= 1 then
			local callback = ui_bridge.fade_callback
			ui_bridge.fade_callback = nil
			fade_progress = 0
			callback()
		end
		ui.invalidate()
	end
end

function M.draw()
	local general = ui_bridge.general

	if building then
		building.draw()
	end

	if fade_progress > 0 then
		ui.box(constants.CAMERA_X, 0, constants.CAMERA_WIDTH, constants.CAMERA_HEIGHT, colors.hex("#000000", fade_progress))
	end

	draw_left(general)
	draw_right(general)

	if open_popover then
		draw_popover()
	end
end

return M
