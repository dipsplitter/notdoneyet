local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)

local EntityService = Framework.GetShared("EntityService")
local DataTableService = Framework.GetShared("DataTableService")
local DTS_Projectile = Framework.GetShared("DTS_Projectile")
local EnumService = Framework.GetShared("EnumService")
local EnumProjectileTypes = EnumService.GetEnum("ProjectileTypes")

local NETWORK = Framework.Network()

local IsClient = RunService:IsClient()
local IsServer = RunService:IsServer()

local ProjectileNetworker = {}

function ProjectileNetworker.SetDataTable(projectileObject)
	if IsServer then
		EntityService.Register(projectileObject)
	end
	
	local dataTableName = if IsClient then `{projectileObject.EntityHandle}` else `{projectileObject.NetworkHandle}`
	
	local dataTableParams = {
		Name = dataTableName,
		Structure = `Projectile.{projectileObject.Id}`,
	}
	
	if IsServer then
		dataTableParams.PlayerContainer = NETWORK.All()
		dataTableParams.Event = DTS_Projectile.Event -- EntitySnapshot
	end
	
	projectileObject.DataTable = DataTableService.Reference(dataTableParams)
end

function ProjectileNetworker.Destroy(projectileObject)
	EntityService.Destroy(projectileObject)
end

return ProjectileNetworker