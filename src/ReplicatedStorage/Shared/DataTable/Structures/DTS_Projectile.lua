local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)

local ProjectilePropertyScripts = ReplicatedStorage.Shared.Projectiles.Properties

local TableUtilities = Framework.GetShared("TableUtilities")
local NetworkedProperties = Framework.GetShared("DT_NetworkedProperties")
local DECLARE = NetworkedProperties.DeclareProperty
local FLAGS = NetworkedProperties.Flags

local BASE_NETWORK_TABLE = {
	["CFrame"] = DECLARE("CFrame"),
	Velocity = DECLARE("Vector"),
}

local DTS_Projectile = {
	Name = "Projectile",
	Cache = {},
	Event = "EntitySnapshot",
}

for i, projectileModule in ProjectilePropertyScripts:GetChildren() do
	local requiredScript = require(projectileModule)
	
	local networkTable = requiredScript.NETWORK_TABLE
	
	-- Script names are prefixed with "P_"
	local projectileType = string.sub(projectileModule.Name, 3)
	
	if not networkTable then
		
		local newNetworkTable = table.clone(BASE_NETWORK_TABLE)
		DTS_Projectile.Cache[projectileType] = newNetworkTable
		
		continue
		
	end
	
	DTS_Projectile.Cache[projectileType] = TableUtilities.DeepMerge(networkTable, BASE_NETWORK_TABLE)
end

return DTS_Projectile