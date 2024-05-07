local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local DistanceUtilities = Framework.GetShared("DistanceUtilities")
local Raycaster = Framework.GetShared("Raycaster")
local TableUtilities = Framework.GetShared("TableUtilities")
local StateTable = Framework.GetShared("StateTable")
local DistanceUtilities = Framework.GetShared("DistanceUtilities")
local ModelUtilities = Framework.GetShared("ModelUtilities")
local InputHandler = Framework.GetShared("InputHandler")
local ItemInventory = Framework.GetShared("ItemInventory")

local Character = Framework.GetServer("Character")
local NPCUtilities = Framework.GetServer("NPCUtilities")
local IKControl = Framework.GetServer("IKControl")
local Vision = Framework.GetServer("NPCVision")

local DefaultNPCStats = {
	MaxVisionRange = 200,
	MinVisionRange = 0,
	MinVisualReactionTime = 0.15,
	ThinkTime = 0.1,
	
	FOV = 90,
}

local NPC = {}
NPC.__index = NPC
NPC.ClassName = "NPC"
setmetatable(NPC, Character)

function NPC.new(params)
	local self = Character.new(params)
	setmetatable(self, NPC)
	
	self.Class = "Custom"
	self.NPCId = params.NPCId
	
	local defaultNPCStats = NPCUtilities.GetStats(self.NPCId)
	if params.NPCStats then
		self.NPCStats = StateTable.new( TableUtilities.Merge(defaultNPCStats, params.NPCStats, true) )
		self.BaseNPCStats = TableUtilities.DeepCopy(self.NPCStats)
	else
		self.NPCStats = StateTable.new(defaultNPCStats)
	end
	
	self.Vision = Vision.new(self)

	self.InputHandler = InputHandler.new()
	self.ItemInventory:SetInputHandler(self.InputHandler)
	
	--[[
		Behavior type: tags
	]]
	self.CharacterLists = self.NPCStats.CharacterLists or {}
	self.CurrentActions = {}
	
	self.LastThinkTime = 0
	self:AddConnections({
		StopMainThink = self.Signals.Died:Connect(function()
			self:CleanupConnection("MainThink", "StopMainThink")
		end),
	})
	
	return self
end

function NPC:GetInputHandler()
	return self.InputHandler
end

-- TODO: Custom core animations / use a better animate script
function NPC:SetupCoreAnimations()
	local animateScript = script.Animate:Clone()
	animateScript.Parent = self:GetModel()
end

function NPC:AddBaseIK()
	self.IKControls = {
		LookAt = IKControl.new({
			EndEffector = "Head",
			ChainRoot = "UpperTorso",
			Type = Enum.IKControlType.LookAt,
			Weight = 0.85,
			Model = self:GetModel()
		})
	}
	self.Cleaner:Add(self.IKControls.LookAt)
end

function NPC:GetStat(statName)
	return self.NPCStats.Data[statName] or DefaultNPCStats[statName]
end

function NPC:LookAt(target)
	self.IKControls.LookAt:LookAt(target)
end

function NPC:ResetLookAt()
	self.IKControls.LookAt:Reset()
end

function NPC:Protect()
	self:GetModel().PrimaryPart:SetNetworkOwner(nil)
end

function NPC:GetDistanceToTarget(target)
	return DistanceUtilities.GetDistance(target, self:GetModel())
end

function NPC:MoveTo(position)
	local humanoid = self:GetModel().Humanoid
	humanoid:MoveTo(position)
end

function NPC:CancelMoveTo()
	local model = self:GetModel()
	local humanoid = model.Humanoid
	humanoid:MoveTo(model.PrimaryPart.Position)
end

return NPC
