--[[
  A small immediate-mode layer on top of Defold's GUI API, standing in for
  React in the browser version.

  Every time something changes, the whole interface is rebuilt: all nodes are
  deleted and the render functions in modules/ui/ run again. While rendering,
  widgets register click regions and key handlers. Input is dispatched to the
  most recently registered (topmost) handler first.

  Coordinates are given from the top-left corner of the screen, like CSS.
  Widget state that needs to survive rebuilds (the highlighted menu option,
  a number being typed, ...) is kept with M.widget(key, init). State that
  isn't requested during a rebuild is discarded, much like an unmounted
  React component.

  Only main/hud.gui_script may call M.begin/M.finish, as they create nodes.
]]
local constants = require "modules.constants"

local M = {}

local HEIGHT = constants.SCREEN_HEIGHT

local nodes = {}
local regions = {}
local key_handlers = {}
local text_handler = nil
local mouse_handlers = {}
local widgets = {}
local used_widgets = {}
local timers = {}

M.dirty = true

function M.invalidate()
	M.dirty = true
end

function M.begin()
	for _, node in ipairs(nodes) do
		gui.delete_node(node)
	end
	nodes = {}
	regions = {}
	key_handlers = {}
	text_handler = nil
	mouse_handlers = {}
	used_widgets = {}
	M.dirty = false
end

function M.finish()
	for key in pairs(widgets) do
		if not used_widgets[key] then
			widgets[key] = nil
		end
	end
end

function M.widget(key, init)
	used_widgets[key] = true
	if widgets[key] == nil then
		widgets[key] = init()
	end
	return widgets[key]
end

-- runs fn after delay seconds
function M.after(delay, fn)
	timers[#timers + 1] = { remaining = delay, fn = fn }
end

function M.update(dt)
	for i = #timers, 1, -1 do
		local timer = timers[i]
		timer.remaining = timer.remaining - dt
		if timer.remaining <= 0 then
			table.remove(timers, i)
			timer.fn()
			M.dirty = true
		end
	end
end

local function add(node)
	nodes[#nodes + 1] = node
	return node
end

function M.box(x, y, w, h, color)
	local node = gui.new_box_node(vmath.vector3(x, HEIGHT - y, 0), vmath.vector3(w, h, 0))
	gui.set_pivot(node, gui.PIVOT_NW)
	gui.set_color(node, color)
	return add(node)
end

-- an image from assets/ui/ui.atlas
function M.image(x, y, w, h, animation, options)
	options = options or {}
	local node = gui.new_box_node(vmath.vector3(x, HEIGHT - y, 0), vmath.vector3(w, h, 0))
	gui.set_pivot(node, gui.PIVOT_NW)
	gui.set_texture(node, "ui")
	gui.play_flipbook(node, animation)
	if options.color then
		gui.set_color(node, options.color)
	end
	if options.rotation then
		-- rotate around the center: CSS rotations are clockwise
		gui.set_pivot(node, gui.PIVOT_CENTER)
		gui.set_position(node, vmath.vector3(x + w / 2, HEIGHT - y - h / 2, 0))
		gui.set_euler(node, vmath.vector3(0, 0, -options.rotation))
	end
	if options.blink then
		gui.animate(node, "color.w", 0.25, gui.EASING_INOUTSINE, 0.6, 0, nil, gui.PLAYBACK_LOOP_PINGPONG)
	end
	return add(node)
end

--[[
  options:
    font: one of the fonts in main/hud.gui (default "r24")
    color: vector4 (default black)
    w, h: size of the text area, needed for align and wrap
    align: "left" (default), "center" or "right"
    wrap: break lines to fit within w
]]
function M.text(x, y, text, options)
	options = options or {}
	local w = options.w or 1
	local align = options.align or "left"

	local pivot = gui.PIVOT_NW
	local px = x
	if align == "center" then
		pivot = gui.PIVOT_N
		px = x + w / 2
	elseif align == "right" then
		pivot = gui.PIVOT_NE
		px = x + w
	end

	local node = gui.new_text_node(vmath.vector3(px, HEIGHT - y, 0), tostring(text))
	gui.set_font(node, options.font or "r24")
	gui.set_pivot(node, pivot)
	gui.set_size(node, vmath.vector3(w, options.h or 1, 0))
	gui.set_color(node, options.color or vmath.vector4(0, 0, 0, 1))
	gui.set_outline(node, vmath.vector4(0, 0, 0, 0))
	gui.set_shadow(node, vmath.vector4(0, 0, 0, 0))
	if options.wrap then
		gui.set_line_break(node, true)
		gui.set_leading(node, options.leading or 1.1)
	end
	return add(node)
end

function M.text_height(node)
	return gui.get_text_metrics_from_node(node).height
end

function M.text_width(node)
	return gui.get_text_metrics_from_node(node).width
end

--[[
  handlers:
    click(x, y): left mouse button pressed inside the region
    right(): right mouse button pressed inside the region
    down(x, y): left mouse button pressed, called before click
  A region without handlers still blocks regions below it.
]]
function M.region(x, y, w, h, handlers)
	regions[#regions + 1] = { x = x, y = y, w = w, h = h, handlers = handlers or {} }
end

-- fn(key) returns true if it handled the key. Keys are named after the
-- bindings in input/game.input_binding: "w", "a", "s", "d", "e", "enter",
-- "escape", "up", "down", "left", "right", "backspace"
function M.on_key(fn)
	key_handlers[#key_handlers + 1] = fn
end

-- receives typed characters; only one text input can be active
function M.on_text(fn)
	text_handler = fn
end

-- fn(event, x, y) with event "move" or "release"
function M.on_mouse(fn)
	mouse_handlers[#mouse_handlers + 1] = fn
end

M.CONFIRM = { e = true, enter = true }
M.CANCEL = { escape = true }

local function region_at(x, y)
	for i = #regions, 1, -1 do
		local r = regions[i]
		if x >= r.x and x < r.x + r.w and y >= r.y and y < r.y + r.h then
			return r
		end
	end
	return nil
end

function M.key_pressed(key)
	for i = #key_handlers, 1, -1 do
		if key_handlers[i](key) then
			M.dirty = true
			return true
		end
	end
	return false
end

-- returns true if the click landed on the interface
function M.click(x, y)
	local region = region_at(x, y)
	if not region then
		return false
	end
	if region.handlers.down then
		region.handlers.down(x, y)
	end
	if region.handlers.click then
		region.handlers.click(x, y)
	end
	M.dirty = true
	return true
end

-- right-click works as cancel, unless the region under the cursor handles it
function M.right_click(x, y)
	local region = region_at(x, y)
	if region and region.handlers.right then
		region.handlers.right()
		M.dirty = true
		return true
	end
	return M.key_pressed("escape")
end

function M.text_input(text)
	if text_handler then
		text_handler(text)
		M.dirty = true
		return true
	end
	return false
end

function M.mouse(event, x, y)
	for _, fn in ipairs(mouse_handlers) do
		if fn(event, x, y) then
			M.dirty = true
		end
	end
end

return M
