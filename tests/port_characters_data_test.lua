local port_characters_data = require "modules.data.port_characters_data"

describe("port_characters_data", function()
	test("characters up to and including MAN have 8 frames each", function()
		expect(port_characters_data.get_start_frame("PLAYER")).to_equal(0)
		expect(port_characters_data.get_start_frame("MAN")).to_equal(16)
		expect(port_characters_data.get_start_frame("MERCHANT")).to_equal(24)
	end)

	test("characters from MERCHANT and up have 2 frames each", function()
		expect(port_characters_data.get_start_frame("DOG")).to_equal(26)
		expect(port_characters_data.get_start_frame("GUARD")).to_equal(28)
		expect(port_characters_data.get_start_frame("BEGGAR")).to_equal(30)
	end)
end)
