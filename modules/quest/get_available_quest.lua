local state = require "modules.state.state"
local selectors = require "modules.state.selectors"
local utils = require "modules.utils"

local finished = selectors.finished_quest

local function between_22_and_24(time_passed)
	local time_passed_today = time_passed % 1440
	return time_passed_today >= 1320 or time_passed_today == 0
end

local function get_available_quest()
	local port_id, building_id = state.port_id, state.building_id

	if port_id ~= "1" or not building_id then
		return nil
	end

	if building_id == "8" then
		if not finished("houseBeforeQuest") then
			return "houseBeforeQuest"
		end
		if not finished("houseAfterQuestAndPub") then
			if finished("pubAfterQuest") and between_22_and_24(state.time_passed) then
				return "houseAfterQuestAndPub"
			end
			return "houseAfterQuest"
		end
		return "houseAfterQuestAndPub2"
	end

	if building_id == "2" then
		if not finished("houseBeforeQuest") then
			if not finished("pubBeforeQuest") then
				return "pubBeforeQuest"
			end
			return "pubBeforeQuest2"
		end
		if not finished("pubAfterQuest") then
			return "pubAfterQuest"
		end
		if not finished("houseAfterQuestAndPub") then
			return "pubAfterQuest2"
		end
		return "pubCarlottaGreeting"
	end

	if building_id == "5" or building_id == "7" or building_id == "9" then
		if not finished("houseBeforeQuest") then
			return utils.sample({
				"lodgeBankGuildBeforeQuestRandom1",
				"lodgeBankGuildBeforeQuestRandom2",
				"lodgeBankGuildBeforeQuestRandom3",
			})
		end
		return utils.sample({
			"lodgeBankGuildAfterQuestRandom1",
			"lodgeBankGuildAfterQuestRandom2",
			"lodgeBankGuildAfterQuestRandom3",
		})
	end

	if building_id == "6" then
		if not finished("houseBeforeQuest") then
			return "palaceBeforeQuest"
		end
		return "palaceAfterQuest"
	end

	if building_id == "10" then
		if not finished("houseBeforeQuest") then
			return "itemShopBeforeQuest"
		end
		if not finished("itemShopAfterQuest") then
			return "itemShopAfterQuest"
		end
		return "itemShopAfterQuest2"
	end

	if building_id == "3" then
		if not finished("houseBeforeQuest") then
			return "shipyardBeforeQuest"
		end
		if not finished("shipyardAfterQuest") then
			return "shipyardAfterQuest"
		end
		return nil
	end

	if building_id == "11" then
		if not finished("houseBeforeQuest") then
			if not finished("churchBeforeQuest") then
				return "churchBeforeQuest"
			end
			return "churchBeforeQuest2"
		end
		if not finished("churchAfterEnrico") then
			if not finished("churchAfterQuest") then
				return "churchAfterQuest"
			end
			return "churchAfterEnrico"
		end
		return "churchAfterEnricoAfterGift"
	end

	if building_id == "1" then
		if not finished("houseBeforeQuest") then
			return "marketBeforeQuest"
		end
		if not finished("shipyardAfterQuest") then
			return "marketAfterQuestBeforeShip"
		end
		return nil
	end

	if building_id == "4" then
		if not finished("houseBeforeQuest") then
			return "harborBeforeQuest"
		end
		if not finished("shipyardAfterQuest") then
			return "harborBeforeShip"
		end
		if not finished("churchAfterQuest") then
			return "harborBeforeEnrico"
		end
		if not finished("pubAfterQuest") then
			if not finished("churchAfterEnrico") then
				return "harborAfterEnrico"
			end
			return "harborAfterEnrico2"
		end
		if not finished("houseAfterQuestAndPub") then
			return "harborAfterEnricoBeforeMother"
		end
		if not finished("harborFinal") then
			return "harborFinal"
		end
	end

	return nil
end

return get_available_quest
