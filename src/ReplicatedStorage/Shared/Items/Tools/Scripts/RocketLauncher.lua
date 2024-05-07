local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local WeaponAttacks = Framework.GetShared("WeaponAttacks")
local ReloadAction = Framework.GetShared("ReloadAction")
local ProjectileSpawner = Framework.GetShared("ProjectileSpawner")
local ActionManagerConnector = Framework.GetShared("ActionManagerConnector")

local BaseTool = if Framework.IsServer then Framework.GetServer("BaseTool") else Framework.GetClient("BaseTool")

local RocketLauncher = {
	Shared = {
		Equip = {
			Started = function(item)
				item.Animator:Play("Equip")
				item.Animator:Play("Idle")
				item.Sounds:PlaySound("Equip")
			end,
			
			Ended = function(item)
				item.ActionManager:Bind("Primary")
			end,
		},

		Primary = function(item)
			item.Animator:Play("PrimaryFire")

			item.Sounds:PlaySound("Shoot")
			item:SetValue("Clip", item:GetValue("Clip") - 1)

			if Framework.IsClient or not item:IsCurrentOwnerPlayer() then
				ProjectileSpawner.Spawn(item, "Primary")
			end
		end,

		Unequip = function(item)
			item.Animator:StopAll()
			item.ActionManager:Cancel("Primary")
			item.Sounds:StopAllSounds()
		end,
	},
	
	Server = {
		Primary = {
			Attack = function(item, args)
				args = args.Args or args

				local rocket = ProjectileSpawner.CreateProjectile(item, "Primary")
				rocket:PivotToLookAt(args.Origin, args.Direction)
				rocket:Stage()
				rocket:SetLinearVelocity()
			end,
		},
	},
}

function RocketLauncher.new(params)
	params.Id = params.Id or "RocketLauncher"

	local item = BaseTool.new(params)
	
	local actionManager = item:GetActionManager()
	local action = actionManager:GetAction("Primary")
	
	action:GetEvent("Started"):SetSuccessEvaluator(function()
		return item:GetValue("Clip") > 0
	end)
	
	item.Reload = ReloadAction.new(item, "Reload")
	item.Reload:ConnectAnimations()
	
	ProjectileSpawner.SetActionAsAttack(item, "Primary")
	
	ActionManagerConnector.Declare(item, RocketLauncher)
	
	return item
end

return RocketLauncher
