local date_utils = require "modules.date_utils"

describe("date_utils", function()
	test("adds whole days only", function()
		expect(date_utils.add_minutes({ year = 1522, month = 5, day = 17 }, 1439)).to_equal({ year = 1522, month = 5, day = 17 })
		expect(date_utils.add_minutes({ year = 1522, month = 5, day = 17 }, 1440)).to_equal({ year = 1522, month = 5, day = 18 })
	end)

	test("rolls over months and years", function()
		expect(date_utils.add_minutes({ year = 1522, month = 5, day = 31 }, 1440)).to_equal({ year = 1522, month = 6, day = 1 })
		expect(date_utils.add_minutes({ year = 1522, month = 12, day = 31 }, 1440)).to_equal({ year = 1523, month = 1, day = 1 })
		expect(date_utils.add_minutes({ year = 1522, month = 1, day = 1 }, 365 * 1440)).to_equal({ year = 1523, month = 1, day = 1 })
	end)

	test("leap years", function()
		expect(date_utils.add_minutes({ year = 1524, month = 2, day = 28 }, 1440)).to_equal({ year = 1524, month = 2, day = 29 })
		expect(date_utils.add_minutes({ year = 1523, month = 2, day = 28 }, 1440)).to_equal({ year = 1523, month = 3, day = 1 })
		expect(date_utils.add_minutes({ year = 1600, month = 2, day = 28 }, 1440)).to_equal({ year = 1600, month = 2, day = 29 })
		expect(date_utils.add_minutes({ year = 1700, month = 2, day = 28 }, 1440)).to_equal({ year = 1700, month = 3, day = 1 })
	end)
end)
