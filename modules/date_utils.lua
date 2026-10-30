-- os.time() can't be relied on for dates in the 1500s, so dates are calculated
-- by hand using the proleptic Gregorian calendar (same as JavaScript's Date).
local constants = require "modules.constants"

local M = {}

M.MONTH_NAMES = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" }

local function is_leap_year(year)
	return (year % 4 == 0 and year % 100 ~= 0) or year % 400 == 0
end

function M.days_in_month(year, month)
	local days = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
	if month == 2 and is_leap_year(year) then
		return 29
	end
	return days[month]
end

function M.add_minutes(date, minutes)
	local year, month, day = date.year, date.month, date.day
	local days = math.floor(minutes / 1440)
	while days > 0 do
		local remaining_in_month = M.days_in_month(year, month) - day
		if days <= remaining_in_month then
			day = day + days
			days = 0
		else
			days = days - remaining_in_month - 1
			day = 1
			month = month + 1
			if month > 12 then
				month = 1
				year = year + 1
			end
		end
	end
	return { year = year, month = month, day = day }
end

function M.current_date(time_passed)
	return M.add_minutes(constants.START_DATE, time_passed)
end

return M
