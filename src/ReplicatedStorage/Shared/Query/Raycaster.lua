local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local VisualizeQuery = Framework.GetShared("VisualizeQuery")
local BaseClass = Framework.GetShared("BaseClass")
local RaycastUtilities = Framework.GetShared("RaycastUtilities")

local HttpService = game:GetService("HttpService")

local Raycaster = {}
Raycaster.__index = Raycaster
Raycaster.ClassName = "Raycaster"
setmetatable(Raycaster, BaseClass)

function Raycaster.new(params)
	local self = BaseClass.new()
	setmetatable(self, Raycaster)
	
	self.MaxRetries = params.MaxRetries or 5
	self.DebugMode = false
	self.DefaultLength = params.DefaultLength
	
	self.FilterFunction = params.FilterFunction or function() return false end
	
	self.RaycastParams = RaycastParams.new()
	
	self.RaycastParams.FilterDescendantsInstances = params.IgnoreList or {}
	self.RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
	
	self.RaycastParams.CollisionGroup = params.CollisionGroup or "Default"
	
	self.ShouldConvertRaycastResult = Framework.DefaultTrue(params.ShouldConvertRaycastResult)
	
	return self
end

function Raycaster:AddToIgnoreList(items)
	self.RaycastParams:AddToFilter(items)
end

function Raycaster:CopyRaycastParams()
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = self.RaycastParams.FilterDescendantsInstances
	raycastParams.FilterType = self.RaycastParams.FilterType
	raycastParams.CollisionGroup = self.RaycastParams.CollisionGroup
	
	return raycastParams
end

function Raycaster:PerformRaycast(origin, direction, totalLength)
	local currentRaycastCount = 0
	local remainingLength = totalLength or self.DefaultLength
	local lastPosition = origin
	
	local raycastParams = self:CopyRaycastParams()
	
	while currentRaycastCount <= self.MaxRetries do
		
		local result = workspace:Raycast(lastPosition, direction * remainingLength, raycastParams)
		if self.DebugMode then
			VisualizeQuery.VisualizeRaycast(lastPosition, direction, remainingLength, raycastParams)
		end
		
		if not result then
			return false
		end
		
		local shouldContinue = self.FilterFunction(result)
		
		if not shouldContinue then
			return if self.ShouldConvertRaycastResult then RaycastUtilities.ConvertRaycastResultToTable(result) else result
		end
		
		raycastParams:AddToFilter(result.Instance)
		remainingLength -= result.Distance
		lastPosition = result.Position
			
		
		currentRaycastCount += 1
	end
end

function Raycaster:PerformBlockcast(cframe, size, direction)
	local currentRaycastCount = 0
	local raycastParams = self:CopyRaycastParams()

	while currentRaycastCount <= self.MaxRetries do

		local result = workspace:Blockcast(cframe, size, direction, raycastParams)
		if self.DebugMode then
			VisualizeQuery.VisualizeBlockcast(cframe, size, direction, raycastParams)
		end

		if not result then
			return false
		end

		local shouldContinue = self.FilterFunction(result)

		if not shouldContinue then
			return if self.ShouldConvertRaycastResult then RaycastUtilities.ConvertRaycastResultToTable(result) else result
		end

		raycastParams:AddToFilter(result.Instance)

		currentRaycastCount += 1
	end
end

function Raycaster:PerformSpherecast(position, radius, direction)
	local currentRaycastCount = 0
	local raycastParams = self:CopyRaycastParams()

	while currentRaycastCount <= self.MaxRetries do

		local result = workspace:Spherecast(position, radius, direction, self.RaycastParams)
		if self.DebugMode then
			--VisualizeQuery.VisualizeRaycast(lastPosition, direction, remainingLength)
		end

		if not result then
			return false
		end

		local shouldContinue = self.FilterFunction(result)

		if not shouldContinue then
			return if self.ShouldConvertRaycastResult then RaycastUtilities.ConvertRaycastResultToTable(result) else result
		end

		raycastParams:AddToFilter(result.Instance)

		currentRaycastCount += 1
	end
end

--[[
	Params:
	
	To perform a single raycast, use normal raycast arguments
	To perform multiple raycasts of the same length and origin, pass an array of directions
]]
function Raycaster:Cast(origin, direction, length)
	length = length or self.DefaultLength
	local resultsTable = {}
	
	local directionsTable = if type(direction) == "table" then direction else {direction}
	
	for i, dir in directionsTable do
		local result = self:PerformRaycast(origin, dir, length)
		resultsTable[i] = result or false
	end
	
	for k, val in resultsTable do
		if val ~= false then
			return resultsTable
		end
	end
end

function Raycaster:Blockcast(cframe, size, direction)
	local resultsTable = {}
	
	local directionsTable = if type(direction) == "table" then direction else {direction}
	
	for i, dir in directionsTable do
		local result = self:PerformBlockcast(cframe, size, direction)
		resultsTable[i] = result or false
	end

	for k, val in resultsTable do
		if val ~= false then
			return resultsTable
		end
	end
end

return Raycaster
