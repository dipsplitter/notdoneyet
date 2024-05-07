local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local ProjectileSchema = Framework.GetShared("ProjectileSchema")

local Enum_EntityClassHandles = {}

local index = 1
for i, projectileScript in ProjectileSchema.GetScripts() do
	Enum_EntityClassHandles[projectileScript.Name] = index
	index += 1
end

return Enum_EntityClassHandles
