local get_message_boxes = require "modules.quest.get_message_boxes"

local vendor = { body = "Hello, World!", position = 0 }
local character1 = { body = "Hello, World!1", characterId = "1", position = 1 }
local character2 = { body = "Hello, World!2", characterId = "2", position = 2 }

describe("get_message_boxes", function()
	test("when no one has spoken yet, only the active box is shown", function()
		expect(get_message_boxes({ vendor }, 1)).to_equal({ { body = vendor.body }, false, false })
		expect(get_message_boxes({ character1 }, 1)).to_equal({ false, { body = character1.body, character_id = "1" }, false })
		expect(get_message_boxes({ character2 }, 1)).to_equal({ false, false, { body = character2.body, character_id = "2" } })
	end)

	test("the vendor box stays empty once the vendor has spoken", function()
		expect(get_message_boxes({ vendor, character1 }, 2)).to_equal({
			{ body = "" },
			{ body = character1.body, character_id = "1" },
			false,
		})
		expect(get_message_boxes({ vendor, character2, character2 }, 3)).to_equal({
			{ body = "" },
			false,
			{ body = character2.body, character_id = "2" },
		})
	end)

	test("the upper box keeps the last character that used it", function()
		expect(get_message_boxes({ character1, character2 }, 2)).to_equal({
			false,
			{ body = "", character_id = "1" },
			{ body = character2.body, character_id = "2" },
		})
		expect(get_message_boxes({ character1, { body = "Hello, World!3", characterId = "3", position = 1 }, character2 }, 3)).to_equal({
			false,
			{ body = "", character_id = "3" },
			{ body = character2.body, character_id = "2" },
		})
	end)

	test("the lower box keeps the last character that used it", function()
		expect(get_message_boxes({ character2, vendor, character1 }, 3)).to_equal({
			{ body = "" },
			{ body = character1.body, character_id = "1" },
			{ body = "", character_id = "2" },
		})
	end)

	test("substitutes the player's name", function()
		expect(get_message_boxes({ { body = "Hello, $firstName!", position = 0 } }, 1)[1].body).to_equal("Hello, João!")
		expect(get_message_boxes({ { body = "Hello, $lastName!", position = 0 } }, 1)[1].body).to_equal("Hello, Franco!")
	end)
end)
