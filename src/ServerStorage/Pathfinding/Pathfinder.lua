local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local BaseClass = Framework.GetShared("BaseClass")
local TableUtilities = Framework.GetShared("TableUtilities")
local DistanceUtilities = Framework.GetShared("DistanceUtilities")

local PathVisualizer = Framework.GetServer("PathVisualizer")

local PathfindingService = game:GetService("PathfindingService")

local DefaultSettings = {
	ComparisonChecks = 2,
	ComparisonCheckMinDistance = 0.07,
}

local Pathfinder = {}
Pathfinder.__index = Pathfinder
Pathfinder.ClassName = "Pathfinder"
setmetatable(Pathfinder, BaseClass)

function Pathfinder.new(params)
	local self = BaseClass.new()
	setmetatable(self, Pathfinder)
	
	self.Agent = params.Agent -- The NPC
	local boundingBox = self.Agent.PrimaryPart:FindFirstChild("BoundingBox")
	local agentSize = boundingBox.Size
	
	self.AgentParameters = params.AgentParameters or {
		AgentRadius = agentSize.Z * 0.75,
		AgentHeight = agentSize.X,
		AgentCollisionGroupName = "Default",
		AgentCanJump = true,
		AgentCanClimb = true,
		WaypointSpacing = 8,
		Costs = {}
	}

	self.Path = PathfindingService:CreatePath(self.AgentParameters)
	
	self.Settings = TableUtilities.Merge(TableUtilities.Copy(DefaultSettings), params.Settings or {}, true)
	
	self:AddSignals("WaypointReached", "WaypointAction", "Failed", "Reached", "Blocked", "Stuck")
	
	self:AddConnections({
		
		OnPathBlocked = self.Path.Blocked:Connect(function(index)
			if self.WaypointMovingToIndex <= index and self.WaypointMovingToIndex + 1 >= index then
				self:GetUnstuck()
				self:FireSignal("Blocked")
			end
		end),
		
	})
	
	self.Active = false
	
	-- Set to 2, 1 is the starting position of the path
	self.WaypointMovingToIndex = 2
	
	self.Waypoints = {}
	
	self.PathfindTask = nil
	
	self.DebugMode = false
	self.VisualizedWaypoints = nil
	
	self.ComparisonCheck = {
		LastPosition = Vector3.zero,
		FailCount = 0,
	}
	
	return self
end

function Pathfinder:ComparePositions()
	local previousPosition = self.ComparisonCheck.LastPosition
	local currentPosition = self.Agent.PrimaryPart.Position
	
	if DistanceUtilities.GetDistance(currentPosition, previousPosition) <= self.Settings.ComparisonCheckMinDistance
		and self.ComparisonCheck.FailCount > self.Settings.ComparisonChecks then
		
		self:FireSignal("Stuck")
		self:Jump()
		self.ComparisonCheck.FailCount += 1
		
	else
		self.ComparisonCheck.FailCount = 0
	end
	
	self.ComparisonCheck.LastPosition = currentPosition
end

function Pathfinder:DestroyVisualizedWaypoints()
	if not self.VisualizedWaypoints then
		return
	end
	
	for i, waypoint in ipairs(self.VisualizedWaypoints) do
		waypoint:Destroy()
	end
	self.VisualizedWaypoints = nil
end

function Pathfinder:FireWaypointReached()
	local lastWaypoint = self.Waypoints[self.WaypointMovingToIndex - 1]
	local currentWaypoint = self.Waypoints[self.WaypointMovingToIndex]
	local nextWaypoint = self.Waypoints[self.WaypointMovingToIndex + 1]
	
	self:FireSignal("WaypointReached", lastWaypoint, currentWaypoint, nextWaypoint)
end

function Pathfinder:ComputePath(targetPosition)
	local success, err = pcall(function()
		self.Path:ComputeAsync(self.Agent.PrimaryPart.Position - Vector3.new(0, self.Agent.PrimaryPart.Size.Y / 0.75, 0), targetPosition)
	end)
	
	self.Waypoints = self.Path:GetWaypoints()

	if not success 
		or self.Path.Status == Enum.PathStatus.NoPath
		or #self.Waypoints < 2 
		or self.Agent.Humanoid:GetState() == Enum.HumanoidStateType.Freefall then
		
		-- self.Waypoints = {}
		self:FireSignal("Failed")
	end
	
	return self.Path.Status
end

function Pathfinder:MoveToFinished(success)
	if success and self.WaypointMovingToIndex + 1 <= #self.Waypoints then -- Reached intermediate
		
		self:FireWaypointReached()
		self.WaypointMovingToIndex += 1
		
		-- Loop through waypoints
		self:Step()
		
	elseif success then -- Reached last waypoint; path complete
		
		self:FireSignal("Reached", self.WaypointMovingToIndex, self.Waypoints[self.WaypointMovingToIndex])
		self:ResetPath()
		
	else -- Hit the 8 second timeout
		
		self.Signals.Failed:Fire()
		self:ResetPath()
		
	end
end

function Pathfinder:Jump()
	local humanoid = self.Agent.Humanoid
	if humanoid:GetState() == Enum.HumanoidStateType.Freefall then
		return
	end
	
	humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
end

function Pathfinder:GetUnstuck()
	self.Agent.Humanoid:Move( Vector3.new(math.random(-1, 1), 0, math.random(-1, 1)) )
	self:Jump()
end

function Pathfinder:AddCosts(costsDict)
	TableUtilities.Merge(self.AgentParameters.Costs, costsDict, true)
end

function Pathfinder:ResetPath()
	self:DestroyVisualizedWaypoints()
	self.Waypoints = {}
	self.WaypointMovingToIndex = 2

	self.Active = false
end

function Pathfinder:MoveToWaypoint()
	local currentWaypoint = self.Waypoints[self.WaypointMovingToIndex]
	if not currentWaypoint then
		return
	end
	
	if currentWaypoint.Action == Enum.PathWaypointAction.Jump then
		self:FireSignal("WaypointAction", self.WaypointMovingToIndex, currentWaypoint)
		self:Jump()
	end

	self.Agent.Humanoid:MoveTo(currentWaypoint.Position)
end

function Pathfinder:Step()
	self:ComparePositions()
	self:MoveToWaypoint()

	self:AddConnection({
		MoveToFinished = self.Agent.Humanoid.MoveToFinished:Connect(function(didReach)
			self:MoveToFinished(didReach)
		end)
	})
end

function Pathfinder:ResetPathfindTask()
	if self.PathfindTask then
		self:CleanupConnection("MoveToFinished")
		task.cancel(self.PathfindTask)
		self.PathfindTask = nil
	end
end

function Pathfinder:Run(position)
	local status = self:ComputePath(position)
	if status ~= Enum.PathStatus.Success then
		warn(`Path status: {status}`)
		return
	end

	self.Active = true
	self:ResetPathfindTask()
	
	self.WaypointMovingToIndex = 2

	self:DestroyVisualizedWaypoints()
	self.VisualizedWaypoints = PathVisualizer.VisualizeWaypoints(self.Waypoints)
	
	self.PathfindTask = task.spawn(self.Step, self)
end

function Pathfinder:GetMovingTargetPosition(targetConfig)
	local target = targetConfig.Target
	
	if target:IsA("Model") then
		local primaryPart = target.PrimaryPart
		if primaryPart then
			target = primaryPart
		end
	end
	
	local targetPosition = target.Position
	local targetVelocity = target.AssemblyLinearVelocity
	local velocityCorrection = targetConfig.VelocityCorrection or 0.1

	return targetPosition + targetVelocity * velocityCorrection
end

return Pathfinder
