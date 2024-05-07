local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local MeleeWeapon = Framework.GetShared("MeleeWeapon")
local DirectionalAttacks = Framework.GetShared("DirectionalAttacks")
local MeleeHitbox = Framework.GetShared("MeleeHitbox")
local WeaponAttacks = Framework.GetShared("WeaponAttacks")
local ActionManagerConnector = Framework.GetShared("ActionManagerConnector")

local StatusEffectService = Framework.GetServer("StatusEffectService")
local DamageService = Framework.GetServer("DamageService")

local BaseTool = if Framework.IsServer then Framework.GetServer("BaseTool") else Framework.GetClient("BaseTool")

local Ignis = {
	
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
		
		Primary = {
			Started = function(item)
				local direction = DirectionalAttacks.GetDirection(item, "Primary")
				item.CurrentDirection = direction
				
				item.Animator:Stop("Idle", table.unpack(DirectionalAttacks.GetDirectionNames(item, "Primary")))
				item.Animator:Play(direction, {Name = "Windup"})
				item.ActionManager:GetAction("Primary"):GetTimer("Windup"):Start()

				item.Animator:Play(direction, {Name = "Idle"})
			end,
			
			Ended = function(item, timeArgs)
				local windupTimer = item.ActionManager:GetAction("Primary"):GetTimer("Windup")
				if windupTimer.Active then
					windupTimer:GetSignal("Ended"):Wait()
				end

				local direction = item.CurrentDirection
				item.Animator:Stop(direction)
				item.Animator:Play(direction, {Name = "Swing"})

				item.Sounds:PlaySound("Swing")
				item.Animator:Play("Idle")
			end,
			
			AttackStartTimestampReached = function(item)
				local hitCharacters = {}

				MeleeHitbox.BeginHitbox(item, "Primary", {
					QueryParams = item.ActionManager:GetAction("Primary"):GetConfig(item.CurrentDirection),

					Step = function(finalResults, newlyAdded)

						MeleeHitbox.ReplicateResults(item, "Primary", function(instance)
							return MeleeHitbox.IgnoreDuplicateCharacter(instance, hitCharacters)
						end)

					end,
				})
			end,
			
			AttackEndTimestampReached = function(item)
				MeleeHitbox.EndHitbox(item, "Primary")
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
			Attack = MeleeWeapon.GetDamageFunction("Primary", {
				InflictorInfo = function(item)
					return {Action = "Primary", DamagePropertiesPath = {item.CurrentDirection or "Left", "DamageProperties"}}
				end
			})
		}
	}
}

function Ignis.new(params)
	params.Id = params.Id or "Ignis"
	
	local melee = BaseTool.new(params)
	
	local actionManager = melee:GetActionManager()
	local action = actionManager:GetAction("Primary")
	
	local hitbox = MeleeHitbox.CreateHitbox(melee)

	action:GetTimer("CooldownTimer").Duration = function()
		return action:GetConfig(melee.CurrentDirection or "Down").CooldownTime
	end
	
	action:AddTimers({
		Windup = {
			Duration = function()
				return action:GetConfig(melee.CurrentDirection or "Down").Windup
			end,
		}
	})
	
	DirectionalAttacks.AddAnimationModifiers(melee, "Primary", {
		Windup = {
			Duration = "Windup",
		},
		Swing = {
			Duration = "CooldownTime",
		},
	})
	DirectionalAttacks.SetServerDirectionBasedOnAnimations(melee)

	WeaponAttacks.SetActionAsAttack(melee, "Primary")
	
	ActionManagerConnector.Declare(melee, Ignis)

	return melee
end

return Ignis
