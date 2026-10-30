local interface_utils = require "modules.interface_utils"

describe("interface_utils", function()
	test("minutes_until_next_morning", function()
		local m = interface_utils.minutes_until_next_morning
		expect(m(0)).to_equal(1440 + 480)
		expect(m(480)).to_equal(1440)
		expect(m(500)).to_equal(1440 - 20)
		expect(m(1439)).to_equal(1 + 480)
		expect(m(1440)).to_equal(1440 + 480)
		expect(m(1640)).to_equal(1440 - 200 + 480)
		expect(m(2880)).to_equal(1440 + 480)
	end)

	test("get_date starts on May 17 1522", function()
		expect(interface_utils.get_date(480)).to_equal("May 17 1522")
		expect(interface_utils.get_date(480 + 15 * 1440)).to_equal("Jun 1 1522")
	end)

	test("get_hours_minutes", function()
		expect(interface_utils.get_hours_minutes(0)).to_equal("12:00 AM")
		expect(interface_utils.get_hours_minutes(480)).to_equal("8:00 AM")
		expect(interface_utils.get_hours_minutes(725)).to_equal("12:05 PM")
		expect(interface_utils.get_hours_minutes(1439)).to_equal("11:59 PM")
	end)

	test("gold is shown as ingots and coins", function()
		expect(interface_utils.get_ingots(25000)).to_equal(2)
		expect(interface_utils.get_coins(25000)).to_equal(5000)
	end)
end)
