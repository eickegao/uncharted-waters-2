--[[
  Runs the unit tests for the game logic with a plain Lua interpreter (5.1+
  or LuaJIT), outside of Defold:

      lua tests/run.lua

  Run from the repository root.
]]
package.path = "./?.lua;" .. package.path

local assets = require "modules.assets"

-- data files are read straight from disk instead of through sys.load_resource
assets.loader = rawget(_G, "read_binary_file") or function(path)
	local file = assert(io.open("." .. path, "rb"))
	local data = file:read("*a")
	file:close()
	return data
end

local passed, failed = 0, 0
local current_describe = ""

local function format(value)
	if type(value) == "table" then
		local parts = {}
		for k, v in pairs(value) do
			parts[#parts + 1] = tostring(k) .. "=" .. format(v)
		end
		table.sort(parts)
		return "{" .. table.concat(parts, ", ") .. "}"
	end
	return tostring(value)
end

local function deep_equal(a, b)
	if type(a) ~= type(b) then
		return false
	end
	if type(a) ~= "table" then
		return a == b
	end
	for k, v in pairs(a) do
		if not deep_equal(v, b[k]) then
			return false
		end
	end
	for k in pairs(b) do
		if a[k] == nil then
			return false
		end
	end
	return true
end

function describe(name, fn)
	local previous = current_describe
	current_describe = previous .. name .. " > "
	fn()
	current_describe = previous
end

function test(name, fn)
	local ok, err = pcall(fn)
	if ok then
		passed = passed + 1
	else
		failed = failed + 1
		print("FAIL " .. current_describe .. name .. "\n     " .. tostring(err))
	end
end

function expect(actual)
	local e = {}

	function e.to_equal(expected)
		if not deep_equal(actual, expected) then
			error("expected " .. format(expected) .. ", got " .. format(actual), 2)
		end
	end

	function e.to_be_close_to(expected)
		if math.abs(actual - expected) > 0.005 then
			error("expected about " .. tostring(expected) .. ", got " .. tostring(actual), 2)
		end
	end

	function e.to_be_greater_than(expected)
		if not (actual > expected) then
			error("expected " .. tostring(actual) .. " > " .. tostring(expected), 2)
		end
	end

	function e.to_be_less_than(expected)
		if not (actual < expected) then
			error("expected " .. tostring(actual) .. " < " .. tostring(expected), 2)
		end
	end

	function e.to_throw()
		if pcall(actual) then
			error("expected function to throw", 2)
		end
	end

	return e
end

local files = {
	"tests.date_utils_test",
	"tests.interface_utils_test",
	"tests.port_characters_data_test",
	"tests.port_utils_test",
	"tests.get_message_boxes_test",
	"tests.world_utils_test",
	"tests.wind_current_test",
	"tests.ship_speed_test",
	"tests.world_player_test",
	"tests.actions_test",
	"tests.quest_test",
	"tests.map_test",
	"tests.hud_test",
	"tests.game_script_test",
}

for _, file in ipairs(files) do
	require(file)
end

print(string.format("%d passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
