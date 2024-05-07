local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)

local StatusEffectService = Framework.GetServer("StatusEffectService")

local Players = game:GetService("Players")
local Folder = script.Parent

local shouldApplyToNpcs = true
local cooldown = 2
local debounceTable = {}

for i, statusEffectPart in Folder:GetChildren() do
	
	if not statusEffectPart:IsA("BasePart") then
		continue
	end
	
	debounceTable[statusEffectPart] = os.clock()
	
	statusEffectPart.Touched:Connect(function(part)
		local model = part:FindFirstAncestorWhichIsA("Model")
		if not model then
			return
		end
		
		if not model:GetAttribute("CharacterID") then
			return
		end
		
		if not shouldApplyToNpcs and not Players:GetPlayerFromCharacter(model) then
			return
		end
		
		if os.clock() - debounceTable[statusEffectPart] < cooldown then
			return
		end
		
		debounceTable[statusEffectPart] = os.clock()
		
		StatusEffectService.Apply({
			Name = statusEffectPart.Name,
			Target = model,
		})
	end)
	
end