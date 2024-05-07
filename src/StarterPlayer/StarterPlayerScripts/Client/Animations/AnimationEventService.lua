local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local AnimationEventListener = Framework.GetShared("AnimationEventListener")

local Characters = workspace.Characters

local animatorConnections = {}

local function RegisterCharacter(character)
	local animator = character:FindFirstChild("Animator", true)
	if not animator then
		return
	end
	
	animatorConnections[character] = animator.AnimationPlayed:Connect(function(animationTrack)
		local listener = AnimationEventListener.new(animationTrack)
	end)
end

-- Plays visual effects for animations
-- Prefix animation schemas with AS
local AnimationEventService = {}

for i, character in Characters:GetChildren() do
	RegisterCharacter(character)
end

Characters.ChildAdded:Connect(RegisterCharacter)

Characters.ChildRemoved:Connect(function(child)
	animatorConnections[child] = nil
end)

return AnimationEventService
