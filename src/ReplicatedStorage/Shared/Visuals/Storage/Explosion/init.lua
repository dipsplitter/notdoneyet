local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local VisualEffect = Framework.GetShared("VisualEffect")

local Explosion = {}
Explosion.__index = Explosion
Explosion.ClassName = "ExplosionVisual"
setmetatable(Explosion, VisualEffect)

function Explosion.new(folder, params)
	local self = VisualEffect.new(folder, params)
	setmetatable(self, Explosion)
	
	
	
	return self
end

function Explosion:AdjustParticleSizes()
	
end

return Explosion
