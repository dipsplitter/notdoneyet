local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local VisualEffect = Framework.GetShared("VisualEffect")
local VisualsRetriever = Framework.GetShared("VisualsRetriever")
local TableUtilities = Framework.GetShared("TableUtilities")

local EnumService = Framework.GetShared("EnumService")
local VisualsEnum = EnumService.GetEnum("Enum_VisualEffects")

local NETWORK = Framework.Network()
local CreateVisualEvent = NETWORK.Event("CreateVisual")
local VisualEvent = NETWORK.Event("VisualEvent")

local activeVisuals = {}

local ClientVisualsService = {}

function ClientVisualsService.Create(visualsModule, params)
	if type(visualsModule) == "string" then
		visualsModule = VisualsRetriever.GetScript(visualsModule)
	end
	
	local visualsData = require(visualsModule)
	
	local moduleToRequire = visualsData

	if visualsData.InheritFrom then
		moduleToRequire = VisualsRetriever.GetModule(visualsData.InheritFrom) or VisualEffect
		params = TableUtilities.Reconcile(params, visualsData.Default or {})
	end

	local effect = moduleToRequire.new(visualsModule, params)

	effect:AddExternalReference(activeVisuals, "NULL")
	effect:StartSequence()
	
	return effect
end

CreateVisualEvent:Connect(function(data)
	local id = data.Id
	local visualId = data.VisualId
	local args = data.Args
	
	local effect = ClientVisualsService.Create(visualId, args)

	activeVisuals[id] = effect
end)


VisualEvent:Connect(function(args)
	local id, eventNameArray = args.Id, args.Events
	
	local effect = activeVisuals[id]
	if not effect then
		return
	end
	
	for i, eventName in eventNameArray do
		effect:TriggerEvent(eventName)
	end
end)

return ClientVisualsService
