local date_utils = require "modules.date_utils"

local M = {}

function M.get_date(time_passed)
	local date = date_utils.current_date(time_passed)
	return string.format("%s %d %d", date_utils.MONTH_NAMES[date.month], date.day, date.year)
end

function M.get_hours_minutes(time_passed)
	local hours = math.floor((time_passed % 1440) / 60)
	local period = hours >= 12 and "PM" or "AM"

	hours = hours % 12
	if hours == 0 then
		hours = 12
	end

	return string.format("%d:%02d %s", hours, time_passed % 60, period)
end

function M.get_ingots(gold)
	return math.floor(gold / 10000)
end

function M.get_coins(gold)
	return gold % 10000
end

function M.minutes_until_next_morning(time_passed)
	local next_morning = math.floor(time_passed / 1440) * 1440 + 1440 + 480
	return next_morning - time_passed
end

return M
