--[[
	Valid spread patterns:
	
	Center: Perfectly accurate shot down the center
	
	Grid: Rectangular pattern
		Dimensions: The pattern of the shots (3 x 3) -> 9 shots total, arranged in a 3x3 grid
	
	Ring: A circular ring
]]

local SpreadPattern = {}

function SpreadPattern.Center(params, centerDirection, baseSpread, directions)
	local count = params.Count or 1
	
	for i = 1, count do
		table.insert(directions, centerDirection.LookVector)
	end
end

function SpreadPattern.Grid(gridParams, centerDirection, baseSpread, directions)
	
end

function SpreadPattern.Ring(ringParams, centerDirection, baseSpread, directions)
	local count = ringParams.Count
	local angleMultiplier = ringParams.AngleMultiplier or 1
	
	local angle = baseSpread * angleMultiplier
	
	for i = 1, count do
		local calculatedDirection = centerDirection * CFrame.fromOrientation(0, 0, (2 * math.pi) * i / count) * CFrame.fromOrientation(0, angle, 0)
		
		table.insert(directions, calculatedDirection.LookVector)
	end
end

function SpreadPattern.GenerateDirectionsArray(action, centerDirection)
	local spreadPatternTable = action:GetConfig("SpreadPattern")
	if not spreadPatternTable then
		return
	end
	
	local baseSpread = action:GetConfig("MaxSpread")
	
	local directions = {}
	
	for i, patternInfo in spreadPatternTable do
		SpreadPattern[patternInfo.Type](patternInfo, centerDirection, baseSpread, directions)
	end
	
	return directions
end

return SpreadPattern
