local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local BaseClass = Framework.GetShared("BaseClass")
local AnimationKeyframeMarkerCache = Framework.GetShared("AnimationKeyframeMarkerCache")

local AnimationEventListener = {}
AnimationEventListener.__index = AnimationEventListener
setmetatable(AnimationEventListener, BaseClass)

function AnimationEventListener.new(animationTrack)
	local keyframeMarkers = AnimationKeyframeMarkerCache[animationTrack.Animation.Name]
	if not keyframeMarkers then
		return
	end
	
	local self = BaseClass.new()
	setmetatable(self, AnimationEventListener)
	
	local connectionsTable = {}
	for i, markerName in keyframeMarkers do
		connectionsTable[markerName] = animationTrack:GetMarkerReachedSignal(markerName):Connect(function(paramsString)

		end)
	end
	
	connectionsTable.Destroying = animationTrack.Destroying:Connect(function()
		self:Destroy()
	end)
	
	connectionsTable.Stopped = animationTrack.Stopped:Connect(function()
		self:Destroy()
	end)
	
	self:AddConnections(connectionsTable)
	
	return self
end

return AnimationEventListener
