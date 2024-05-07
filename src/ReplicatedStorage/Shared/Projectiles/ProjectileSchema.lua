local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Framework = require(ReplicatedStorage.Framework)
local DTS_Projectile = Framework.GetShared("DTS_Projectile")

local ProjectileFolder = script.Parent
local ProjectileScripts = ProjectileFolder.Scripts
local ProjectileProperties = ProjectileFolder.Properties

local ProjectileSchema = {}

function ProjectileSchema.GetScripts()
	return ProjectileScripts:GetChildren()
end

function ProjectileSchema.GetScript(projectileType)
	return require(ProjectileScripts[projectileType])
end

function ProjectileSchema.GetModel(projectileType)
	return ProjectileProperties[projectileType]:FindFirstChildWhichIsA("Model")
end

function ProjectileSchema.GetDataTableStructure(projectileType)
	return DTS_Projectile.Cache[projectileType]
end

function ProjectileSchema.GetBaseProperties(projectileType)
	return require(ProjectileProperties[`P_{projectileType}`]).Base
end

function ProjectileSchema.GetPropertyScript(projectileType)
	return ProjectileProperties[`P_{projectileType}`]
end

return ProjectileSchema
