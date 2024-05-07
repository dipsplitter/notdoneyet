local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local ProjectileSchema = Framework.GetShared("ProjectileSchema")

local projectileCache = {}
local currentProjectileId = 0
local ProjectileService = {}

function ProjectileService.Create(name, params)
	local module = ProjectileSchema.GetScript(name)
	
	if not params.Id then
		params.Id = name
	end
	
	params.EntityHandle = currentProjectileId
	currentProjectileId += 1
	local projectile = module.Create(params)
	
	projectileCache[projectile.EntityHandle] = projectile
	projectile:AddExternalReference(projectileCache)
	
	return projectile
end

function ProjectileService.GetFromId(id)
	id = tonumber(id)
	return projectileCache[id]
end

function ProjectileService.GetFromInstance(instance)
	local model = instance
	if not instance:IsA("Model") then
		model = instance:FindFirstAncestorOfClass("Model")
	end
	
	for id, projectile in pairs(projectileCache) do
		if projectile.Model == model then
			return projectile
		end
	end
end

return ProjectileService
