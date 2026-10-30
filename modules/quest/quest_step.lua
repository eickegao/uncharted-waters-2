--[[
  Plays through the quest available when entering a building (if any). The
  equivalent of the useQuestStep hook in the browser version.
]]
local quest_data = require "modules.data.quest_data"
local get_available_quest = require "modules.quest.get_available_quest"
local get_message_boxes = require "modules.quest.get_message_boxes"
local actions_port = require "modules.state.actions_port"
local ui_bridge = require "modules.state.ui_bridge"
local utils = require "modules.utils"

local M = {}

local action_handlers = {
	buyItem = actions_port.buy_item,
	exitBuildingIfNotLodge = actions_port.exit_building_if_not_lodge,
	receiveGold = actions_port.receive_gold,
	receiveFirstShip = actions_port.receive_first_ship,
	assignFirstRoles = actions_port.assign_first_roles,
	recruitRocco = actions_port.recruit_rocco,
	recruitEnrico = actions_port.recruit_enrico,
}

-- answers to questions asked during a quest add more lines to the conversation
local confirm_handlers = {
	harborFinalRoles = {
		yes = function(messages)
			actions_port.assign_first_roles()
			local more = {
				{ body = "Not a bad idea. Welcome to the crew, Brother Enrico.", characterId = "1", position = 2 },
				{ body = "Oh, and I’d like you to be first mate, Rocco.", characterId = "1", position = 2 },
				{
					body = "Well, I do have a pretty good idea of prices at the ports I’ve read about.",
					characterId = "33",
					position = 1,
				},
				{
					body = "If we check our log of goods, I should be able to figure out which port will pay the most for each item.",
					characterId = "33",
					position = 1,
					completeQuest = true,
				},
			}
			for _, m in ipairs(more) do
				messages[#messages + 1] = m
			end
		end,
		no = function(messages)
			local more = {
				{ body = "No, it’s not right to ask Brother Enrico to do such work.", characterId = "1", position = 2 },
				{
					body = "Well, actually, I wouldn’t mind it in the least. I’d be glad to help!",
					characterId = "33",
					position = 1,
				},
				{
					body = "Well then, perhaps I’ll ask you again when we start to trade.",
					characterId = "1",
					position = 2,
					completeQuest = true,
				},
			}
			for _, m in ipairs(more) do
				messages[#messages + 1] = m
			end
		end,
	},
}

local function run_actions(message)
	for _, call in ipairs(message.action or {}) do
		local handler = action_handlers[call[1]]
		if not handler then
			error("Unknown quest action " .. tostring(call[1]))
		end
		handler(call[2], call[3])
	end
end

-- on_change is called whenever the step changes so the interface can redraw
function M.create(on_change)
	local quest_id = get_available_quest()

	if not quest_id then
		return nil
	end

	-- copied, as answers can add messages to the conversation
	local messages = utils.deep_copy(quest_data.quests[quest_id])
	local step = 1

	local quest = {}

	-- returns nil once the conversation is over
	function quest.message_boxes()
		local message = messages[step]

		if not message then
			return nil
		end

		local function next()
			run_actions(message)

			if message.completeQuest then
				actions_port.complete_quest(quest_id)
			end

			if message.fadeBeforeNext then
				ui_bridge.fade(function()
					step = step + 1
					on_change()
				end)
				return
			end

			if message.exitBuilding then
				actions_port.exit_building()
				return
			end

			step = step + 1
			on_change()
		end

		local boxes = get_message_boxes(messages, step)
		local current = boxes[message.position + 1]

		if current then
			if message.confirm then
				local handler = confirm_handlers[message.confirm]
				current.confirm = {
					yes = function()
						handler.yes(messages)
						next()
					end,
					no = function()
						handler.no(messages)
						next()
					end,
				}
			else
				current.acknowledge = next
			end
		end

		return boxes
	end

	return quest
end

return M
