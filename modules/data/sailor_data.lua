local M = {}

M.sailor_skills = {
	"Celestial Navigation",
	"Accounting",
	"Negotiation",
	"Gunnery",
	"Cartography",
}

-- the order in which stats are listed in the Mates window
M.stat_names = { "leadership", "seamanship", "knowledge", "intuition", "courage", "swordplay", "charm", "luck" }

local sailor_data = {
	["1"] = {
		name = "João Franco",
		age = 18,
		stats = {
			leadership = 78,
			seamanship = 75,
			knowledge = 73,
			intuition = 85,
			courage = 82,
			swordplay = 82,
			charm = 89,
			luck = 50,
		},
		navigationLevel = 1,
		battleLevel = 1,
		skills = { "Negotiation" },
	},
	["32"] = {
		name = "Rocco Alemkel",
		age = 65,
		stats = {
			leadership = 75,
			seamanship = 82,
			knowledge = 84,
			intuition = 90,
			courage = 93,
			swordplay = 92,
			charm = 70,
			luck = 70,
		},
		navigationLevel = 30,
		battleLevel = 32,
		skills = { "Celestial Navigation", "Gunnery" },
	},
	["33"] = {
		name = "Enrico Malione",
		age = 24,
		stats = {
			leadership = 66,
			seamanship = 48,
			knowledge = 93,
			intuition = 55,
			courage = 62,
			swordplay = 48,
			charm = 82,
			luck = 100,
		},
		navigationLevel = 1,
		battleLevel = 1,
		skills = { "Accounting" },
	},
}

function M.get_sailor(id)
	return sailor_data[id]
end

return M
