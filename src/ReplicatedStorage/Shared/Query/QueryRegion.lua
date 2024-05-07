local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Framework = require(ReplicatedStorage.Framework)
local TableUtilities = Framework.GetShared("TableUtilities")

local VisualizeQuery = Framework.GetShared("VisualizeQuery")

local validQueryParams = {
	Size = true,
	["OverlapParams"] = true
}

local QueryRegion = {}
QueryRegion.__index = QueryRegion
QueryRegion.ClassName = "QueryRegion"

function QueryRegion.new(params)
	local self = {
		FilterFunction = params.FilterFunction or function() return true end,
		QueryParams = params.QueryParams or {},
		QueryType = params.QueryType or "Radius",
		
		ContinuousQueryConnection = nil,
		ContinuousQueryResults = {},
	}
	
	setmetatable(self, QueryRegion)
	-- Either a Vector3 position or part
	self:SetOrigin(params.Origin)
	
	return self
end

function QueryRegion:SetOrigin(newOrigin)
	self.Origin = newOrigin
	
	if typeof(self.Origin) == "Instance" and self.Origin:IsA("BasePart") then
		self.QueryType = "Part"
	end
end

function QueryRegion:SetProperties(propertiesTable)
	for propertyName, value in propertiesTable do
		if not self[propertyName] then
			continue
		end
		
		if type(value) == "table" then
			for keyName, v in value do
				if not validQueryParams[keyName] then
					continue
				end
				
				self[propertyName][keyName] = v
			end
		else
			self[propertyName] = value
		end
	end
end

function QueryRegion:GetOriginPosition()
	if typeof(self.Origin) == "Vector3" then
		return self.Origin
	elseif typeof(self.Origin) == "Instance" then
		
		if self.Origin:IsA("Model") then 
			return self.Origin:GetPivot().Position
		end
		
		if self.Origin:IsA("Attachment") then
			return self.Origin.WorldPosition
		end
		
		return self.Origin.Position
	end
end

function QueryRegion:GetOriginCFrame()
	if typeof(self.Origin) == "Vector3" then
		return CFrame.new(self.Origin)
	elseif typeof(self.Origin) == "Instance" then

		if self.Origin:IsA("Model") then 
			return self.Origin:GetPivot()
		end
		
		if self.Origin:IsA("Attachment") then
			return self.Origin.WorldCFrame
		end

		return self.Origin.CFrame
	end
end

function QueryRegion:GetQueryParam(name)
	return self.QueryParams[name]
end

function QueryRegion:PerformQuery(filterFunc, ...)
	local queryType = self.QueryType
	
	local results
	if queryType == "Radius" then
		results = workspace:GetPartBoundsInRadius(self:GetOriginPosition(), self.QueryParams.Size, self.QueryParams.OverlapParams)
	elseif queryType == "Box" then
		results = workspace:GetPartBoundsInBox(self:GetOriginCFrame(), self.QueryParams.Size, self.QueryParams.OverlapParams)
		
		--VisualizeQuery.VisualizeBoxQuery(self:GetOriginCFrame(), self.QueryParams.Size)
	else
		results = workspace:GetPartsInPart(self.Origin, self.QueryParams.OverlapParams)
	end
	
	return TableUtilities.Filter(results, filterFunc or self.FilterFunction, ...), results
end

function QueryRegion:ContinuousQuery(callbacks)
	table.clear(self.ContinuousQueryResults)
	
	local lastRecordedTime = os.clock()
	self.ContinuousQueryConnection = RunService.PostSimulation:Connect(function(deltaTime)
		local cooldown = self.QueryParams.ContinuousQueryTick
		
		if cooldown and os.clock() < lastRecordedTime + cooldown then
			return
		end
		lastRecordedTime = os.clock()
		
		local instances = self:PerformQuery(callbacks.Filter, self.ContinuousQueryResults)
		self.ContinuousQueryResults = TableUtilities.MergeArrays(self.ContinuousQueryResults, instances)
		
		if callbacks.Step then
			callbacks.Step(self.ContinuousQueryResults, instances)
		end
	end)
end

function QueryRegion:StopContinuousQuery()
	if self.ContinuousQueryConnection then
		self.ContinuousQueryConnection:Disconnect()
		self.ContinuousQueryConnection = nil
	end
end

function QueryRegion:Destroy()
	self:StopContinuousQuery()
	
	table.clear(self)
	setmetatable(self, nil)
	table.freeze(self)
end

return QueryRegion
