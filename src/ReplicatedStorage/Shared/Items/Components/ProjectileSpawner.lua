local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local WeaponAttacks = Framework.GetShared("WeaponAttacks")
local TableUtilities = Framework.GetShared("TableUtilities")

local Client = Framework.GetClient("Client")

local CharacterRegistry = Framework.GetServer("CharacterRegistry")
local ProjectileService = Framework.GetServer("ProjectileService")

local ProjectileSpawner = {}

function ProjectileSpawner.SetActionAsAttack(item, actionName)
	local action = item:GetActionManager():GetAction(actionName)
	WeaponAttacks.SetActionAsAttack(item, actionName)
end

function ProjectileSpawner.Spawn(item, actionName, args)
	local actionManager = item:GetActionManager()
	local action = actionManager:GetAction(actionName)
	
	local rayInfo
	
	if Framework.IsClient then
		rayInfo = Client.GetHeadToMouseRay()
		rayInfo.Origin = Client.Character.Head.CFrame
	else
		rayInfo = CharacterRegistry.GetCharacterFromModel(item.Character):GetHeadToLookRay()
		rayInfo.Origin = item.Character.Head.CFrame
	end

	if args then
		TableUtilities.Merge(rayInfo, args)
	end
	
	WeaponAttacks.ReplicateAttack(item, actionName, rayInfo)
end

function ProjectileSpawner.CreateProjectile(item, actionName, projectileName, customStats)
	local actionManager = item:GetActionManager()
	local action = actionManager:GetAction(actionName)
	local projectilesTable = action:GetConfig("Projectile")
	
	local projectileId
	local data = {}
	
	if TableUtilities.GetKeyCount(projectilesTable) == 1 then
		projectileId, data.Stats = next(projectilesTable)
	else
		projectileId = projectileName
		data.Stats = projectilesTable[projectileId]
	end
	
	if customStats then
		TableUtilities.Merge(data.Stats, customStats)
	end
	
	data.Spawner = item
	
	return ProjectileService.Create(projectileId, data)
end

return ProjectileSpawner
