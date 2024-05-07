local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local WeaponAttacks = Framework.GetShared("WeaponAttacks")
local ReloadAction = Framework.GetShared("ReloadAction")
local HitscanWeapon = Framework.GetShared("HitscanWeapon")
local ActionManagerConnector = Framework.GetShared("ActionManagerConnector")

local ClientVisualsService = Framework.GetClient("ClientVisualsService")

local DamageAccumulator = Framework.GetServer("DamageAccumulator")

local BaseTool = if Framework.IsServer then Framework.GetServer("BaseTool") else Framework.GetClient("BaseTool")

local PumpShotgun = {
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

		Primary = function(item, args)
			item.Animator:Play("Shoot")
			item.Sounds:PlaySound("Shoot")
			item:SetValue("Clip", item:GetValue("Clip") - 1)
			
			if Framework.IsClient or not item:IsCurrentOwnerPlayer() then
				HitscanWeapon.AttackWithFixedPattern(item, "Primary")
			end
			
			if Framework.IsClient then
				--ClientVisualsService.Create("Bullet", {Character = item.Character, Model = item.ItemModel.Model})
			end
		end,
		
		Reload = {
			ConsecutiveStart = function(item)
				item.Sounds:PlaySound("Reload")
			end,
		},

		Unequip = function(item)
			item.Animator:StopAll()
			item.ActionManager:Cancel("Primary")
			item.Sounds:StopAllSounds()
		end,
	},
	
	Server = {
		Primary = {
			Attack = function(item, args)
				local raycastResults = args.Args
				if not raycastResults then
					return
				end
				
				local accumulator = DamageAccumulator.new({
					Attacker = item.Character,
					Inflictor = item,
					InflictorInfo = {Action = "Primary"}
				})
				
				local damage = item.ActionManager:GetAction("Primary"):GetConfig("DamageProperties").BaseDamage
			
				for i, result in raycastResults do

					local target = result.Character
					
					accumulator:AddDamage(target, damage)

				end
				
				accumulator:ApplyDamageToAll()
			end,
		},
	},
}

function PumpShotgun.new(params)
	params.Id = params.Id or "PumpShotgun"

	local item = BaseTool.new(params)
	
	HitscanWeapon.AddRaycaster(item)
	
	local actionManager = item:GetActionManager()
	local action = actionManager:GetAction("Primary")
	
	action:GetEvent("Started"):SetSuccessEvaluator(function()
		return item:GetValue("Clip") > 0
	end)
	
	item.Reload = ReloadAction.new(item, "Reload")
	item.Reload:ConnectAnimations()
	
	HitscanWeapon.SetActionAsAttack(item, "Primary")
	
	ActionManagerConnector.Declare(item, PumpShotgun)
	
	return item
end

return PumpShotgun
