local DistanceUtilities = {}

function DistanceUtilities.GetPosition(instance)
	if typeof(instance) == "Vector3" then
		return instance
	end

	if instance:IsA("Model") then
		if instance.PrimaryPart then
			return instance.PrimaryPart.Position
		else
			return instance:GetPivot().Position
		end
	end

	return instance.Position
end

function DistanceUtilities.GetClosest(config)
	local centerPosition = config.Center
	local targets = config.Targets
	local maxDistance = config.MaxDistance or 1000
	local minDistance = config.MinDistance or 0
	local evaluator = config.Evaluator
	
	local closestTarget = nil
	local closestDistance = maxDistance
	
	for i, potentialTarget in pairs(targets) do
		local targetPosition = DistanceUtilities.GetPosition(potentialTarget)
		
		if evaluator then
			if evaluator(potentialTarget, targetPosition) == false then
				continue
			end
		end
		
		local distance = (targetPosition - centerPosition).Magnitude
		if distance > maxDistance or distance < minDistance then
			continue
		end
		
		if distance < closestDistance then
			closestDistance = distance
			closestTarget = potentialTarget
		end
	end
	
	return closestTarget, closestDistance
end

function DistanceUtilities.GetFarthest(config)
	local centerPosition = config.Center
	local targets = config.Targets
	local maxDistance = config.MaxDistance or 1000
	local minDistance = config.MinDistance or 0
	local evaluator = config.Evaluator

	local farthestTarget = nil
	local farthestDistance = minDistance

	for i, potentialTarget in pairs(targets) do
		local targetPosition = DistanceUtilities.GetPosition(potentialTarget)

		if evaluator then
			if evaluator(potentialTarget, targetPosition) == false then
				continue
			end
		end

		local distance = (targetPosition - centerPosition).Magnitude
		if distance > maxDistance or distance < minDistance then
			continue
		end

		if distance > farthestDistance then
			farthestDistance = distance
			farthestTarget = potentialTarget
		end
	end

	return farthestTarget, farthestDistance
end

function DistanceUtilities.GetDistance(target, center)
	return (DistanceUtilities.GetPosition(target) - DistanceUtilities.GetPosition(center)).Magnitude
end

function DistanceUtilities.GetUnitDirectionTo(target, origin)
	return (DistanceUtilities.GetPosition(target) - DistanceUtilities.GetPosition(origin)).Unit
end

function DistanceUtilities.GetAbsoluteYDifference(t1, t2)
	return math.abs(math.abs(DistanceUtilities.GetPosition(t1).Y) - math.abs(DistanceUtilities.GetPosition(t2).Y))
end

function DistanceUtilities.ArePositionsEqual(pos1, pos2)
	return math.abs(pos1.X - pos2.X) >= 0.01 
		and math.abs(pos1.Y - pos2.Y) >= 0.01 
		and math.abs(pos1.Z - pos2.Z) >= 0.01
end

return DistanceUtilities
