local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local BaseClass = Framework.GetShared("BaseClass")

local PatrolRegions = {}
PatrolRegions.__index = PatrolRegions
PatrolRegions.ClassName = "PatrolRegions"
setmetatable(PatrolRegions, BaseClass)

function PatrolRegions.new(params)
	local self = BaseClass.new()
	setmetatable(self, PatrolRegions)
	
	
	return self
end


return PatrolRegions
