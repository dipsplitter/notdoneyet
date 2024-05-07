local MainSeed = Random.new(os.clock())

--[[
	seed: if true, uses MainSeed; false or nil, pulls from a new seed
	Can also pass own seeds
]]
local function GenerateRandomNumber(min, max, seed)
	local seedToUse = MainSeed
	
	if typeof(seed) == "Random" then
		seedToUse = seed
	else
		seed = seed or (seed == nil and false)
	end
	
	if seed == false then
		seedToUse = Random.new()
	end
	
	return seedToUse:NextNumber(min, max)
end

local function GenerateRandomInteger(min, max, seed)
	local seedToUse = MainSeed

	if typeof(seed) == "Random" then
		seedToUse = seed
	else
		seed = seed or (seed == nil and false)
	end

	if seed == false then
		seedToUse = Random.new()
	end
	
	return seedToUse:NextInteger(min, max)
end

local RandomUtilities = {}

function RandomUtilities.SelectRandomFromArray(array, useSeed)
	local index = GenerateRandomInteger(1, #array, useSeed)
	
	return array[index]
end

function RandomUtilities.SelectRandomFromDictionary(dict, useSeed)
	local keys = {}

	for key in pairs(dict) do
		table.insert(keys, key)
	end

	if #keys == 1 then
		local onlyKey = keys[1]
		return dict[onlyKey]
	end

	local position = GenerateRandomInteger(1, #keys, useSeed)
	local key = keys[position]

	return dict[key]
end

function RandomUtilities.SelectRandomKeyFromDictionary(dict, useSeed)
	local keys = {}

	for key in pairs(dict) do
		table.insert(keys, key)
	end

	local position = GenerateRandomInteger(1, #keys, useSeed)
	return keys[position]
end

--[[
	Valid tables:
	
	{ Item1 = 1, Item2 = 1, Item3 = 3 },
	{ Item1 = {..., Weight = 1}, Item2 = {..., Weight = 2} }
]]
function RandomUtilities.SelectRandomKeyFromWeightedTable(tab, weightKeyName, useSeed)
	weightKeyName = weightKeyName or "Weight"
	local totalWeight = 0

	for item, weight in pairs(tab) do
		if type(weight) == "table" then
			totalWeight += weight[weightKeyName] or 1
		else
			totalWeight += weight
		end
	end

	local threshold = GenerateRandomNumber(0, totalWeight, useSeed)
	
	local current = 0
	for item, weight in pairs(tab) do

		if type(weight) == "table" then
			current += weight[weightKeyName] or 1
		else
			current += weight
		end

		if threshold <= current then
			return item
		end
	end
end

--[[
	Random points from geometry
]]
function RandomUtilities.SelectRandomPointFromCircle(center, radius, useSeed)
	local radius = math.sqrt(GenerateRandomNumber(0.001, 1, useSeed)) * radius
	
	local angle = GenerateRandomNumber(0, math.pi * 2, useSeed)
	
	local x = center.X + radius * math.cos(angle)
	local z = center.Z + radius * math.sin(angle)

	local position = Vector3.new(x, center.Y, z)

	return position
end

function RandomUtilities.SelectRandomPointFromPlane(centerCFrame, size, useSeed)
	local x = GenerateRandomNumber(-size.X / 2, size.X / 2, useSeed)
	local z = GenerateRandomNumber(-size.Z / 2, size.Z / 2, useSeed)

	local localPosition = Vector3.new(x, centerCFrame.Position.Y, z)

	return centerCFrame:PointToWorldSpace(localPosition)
end

--[[
	Prevents part from spilling out of the region
]]
function RandomUtilities.SelectRandomPartPositionFromBox(box, partToPosition, useSeed)
	local boxSize = box.Size
	local partSize = partToPosition.Size
	
	local x = GenerateRandomNumber(-boxSize.X / 2 + partSize.X / 2, boxSize.X / 2 - partSize.X / 2, useSeed)
	local y = GenerateRandomNumber(-boxSize.Y / 2 + partSize.Y / 2, boxSize.Y / 2 - partSize.Y / 2, useSeed)
	local z = GenerateRandomNumber(-boxSize.Z / 2 + partSize.Z / 2, boxSize.Z / 2 - partSize.Z / 2, useSeed)
	
	local localPosition = CFrame.new(x, y, z)
	
	return box.CFrame:ToWorldSpace(localPosition)
end

return RandomUtilities