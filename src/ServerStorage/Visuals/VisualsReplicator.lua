local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local VisualsRetriever = Framework.GetShared("VisualsRetriever")

local EnumService = Framework.GetShared("EnumService")
local VisualsEnum = EnumService.GetEnum("Enum_VisualEffects")

local NETWORK = Framework.Network()
local CreateVisualEvent = NETWORK.Event("CreateVisual")
local VisualEvent = NETWORK.Event("VisualEvent")

local currentId = 0

local VisualsReplicator = {}

-- TODO: Selective replication
function VisualsReplicator.Replicate(visualModule, params)
	local id = currentId
	
	CreateVisualEvent:Fire({
		Id = id,
		VisualId = visualModule,
		Args = params,
	}, NETWORK.All())
	
	if currentId == 2^16 - 1 then
		currentId = 0
	else
		currentId += 1
	end
	
	return id
end

function VisualsReplicator.Stop(id)
	VisualEvent:Fire({
		Id = id,
		Events = {"Stop"}
	}, NETWORK.All())
end 

return VisualsReplicator
