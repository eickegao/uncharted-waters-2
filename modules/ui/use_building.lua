--[[
  Menu state shared by all buildings: the selected option and how many steps
  into it the player is. Step -1 (with exit_message) shows a goodbye message
  before leaving.
]]
local actions_port = require "modules.state.actions_port"
local ui = require "modules.ui.ui"

local function use_building(exit_message)
	local b = { option = nil, step = 0 }

	function b.select_option(option)
		b.option = option
		b.step = 0
		ui.invalidate()
	end

	function b.reset()
		b.option = nil
		b.step = 0
		ui.invalidate()
	end

	function b.next()
		b.step = b.step + 1
		ui.invalidate()
	end

	function b.back(steps)
		local step = b.step - (steps or 1)
		ui.invalidate()

		if b.option then
			if step >= 0 then
				b.step = step
				return
			end
			b.reset()
			return
		end

		if (not exit_message and step < 0) or (exit_message and step < -1) then
			actions_port.exit_building()
			return
		end

		b.step = step
	end

	return b
end

return use_building
