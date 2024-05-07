local RunService = game:GetService("RunService")
local IsServer = RunService:IsServer()

local Storage = script.Parent.Storage

local StatusEffectStorage = {}

function StatusEffectStorage.GetStatusEffectVisuals(name)
	return Storage:FindFirstChild(name)
end

return StatusEffectStorage
