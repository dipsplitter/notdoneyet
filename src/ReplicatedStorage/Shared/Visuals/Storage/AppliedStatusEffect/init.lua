local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local VisualEffect = Framework.GetShared("VisualEffect")
local ParticleEmitterUtilities = Framework.GetShared("ParticleEmitterUtilities")

local CharacterRegistry = Framework.GetShared("CharacterRegistry")

local AppliedStatusEffect = {}
AppliedStatusEffect.__index = AppliedStatusEffect
AppliedStatusEffect.ClassName = "AppliedStatusEffect"
setmetatable(AppliedStatusEffect, VisualEffect)

function AppliedStatusEffect.new(folder, params)
	params.Base = "NULL"
	local self = VisualEffect.new(folder, params)
	setmetatable(self, AppliedStatusEffect)
	
	self.Target = CharacterRegistry.GetModelFromId(params.CharacterId)
	self.InstanceParents = params.InstanceParents
	
	self:SetParents()

	return self
end

function AppliedStatusEffect:SetParents()
	for instanceName, parents in self.InstanceParents do
		local instance = self:GetBaseInstance(instanceName)
		
		for i, parentName in parents do
			
			if parentName == "All" then
				
				for j, basePart in self.Target:GetChildren() do
					if basePart:IsA("BasePart") then
						local clone = self:CloneInstance(instance)
						clone.Parent = basePart
					end
				end
				
				break
			end
			
			local clone = self:CloneInstance(instance)
			clone.Parent = self.Target:FindFirstChild(parentName) or self.Target.PrimaryPart
		end
	end
end

function AppliedStatusEffect:StartSequence()
	self:EnableAll()
end

function AppliedStatusEffect:DisableAll()
	for i, instance in self.ActiveInstances do
		if instance:IsA("ParticleEmitter") then
			ParticleEmitterUtilities.Toggle(instance)
		end
	end
end

return AppliedStatusEffect
