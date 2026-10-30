local state = require "modules.state.state"
local quest_step = require "modules.quest.quest_step"
local get_available_quest = require "modules.quest.get_available_quest"

local function play_through(quest)
	local steps = 0
	while state.building_id do
		local boxes = quest.message_boxes()
		if not boxes then
			break
		end
		for _, box in ipairs(boxes) do
			if box and box.acknowledge then
				box.acknowledge()
			elseif box and box.confirm then
				box.confirm.yes()
			end
		end
		steps = steps + 1
		assert(steps < 200, "conversation never ends")
	end
end

describe("quests", function()
	test("there are no quests outside of Lisbon", function()
		state.reset()
		state.port_id = "2"
		state.building_id = "8"
		expect(get_available_quest()).to_equal(nil)
	end)

	test("the father's house starts the story and Rocco joins", function()
		state.reset()
		state.building_id = "8"
		expect(get_available_quest()).to_equal("houseBeforeQuest")

		play_through(quest_step.create(function() end))

		expect(state.quests).to_equal({ "houseBeforeQuest" })
		expect(state.mates[2].sailor_id).to_equal("32")
		expect(state.building_id).to_equal(nil)
	end)

	test("the shipyard hands over the first ship after the house", function()
		state.reset()
		state.quests = { "houseBeforeQuest" }
		state.building_id = "3"
		play_through(quest_step.create(function() end))
		expect(#state.fleets[1].ships).to_equal(1)
		expect(state.fleets[1].ships[1].name).to_equal("Hermes II")
	end)

	test("answering yes in the final harbor conversation assigns roles", function()
		state.reset()
		state.quests = {
			"houseBeforeQuest",
			"shipyardAfterQuest",
			"churchAfterQuest",
			"pubAfterQuest",
			"houseAfterQuestAndPub",
		}
		state.mates = {
			{ sailor_id = "1", role = 1 },
			{ sailor_id = "32" },
			{ sailor_id = "33" },
		}
		state.building_id = "4"
		expect(get_available_quest()).to_equal("harborFinal")

		local quest = quest_step.create(function() end)
		play_through(quest)

		expect(state.mates[2].role).to_equal("firstMate")
		expect(state.mates[3].role).to_equal("bookKeeper")
		expect(state.quests[#state.quests]).to_equal("harborFinal")
		expect(quest.message_boxes()).to_equal(nil)
	end)
end)
