local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local MeleeWeapon = Framework.GetShared("MeleeWeapon")
local WeaponAttacks = Framework.GetShared("WeaponAttacks")
local ActionManagerConnector = Framework.GetShared("ActionManagerConnector")

local BaseTool = if Framework.IsServer then Framework.GetServer("BaseTool") else Framework.GetClient("BaseTool")

local ClassicSword = {
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
				item.Animator:Play("Primary")
				item.Sounds:PlaySound("Swing")
			end,
			
			AttackTimestampReached = function(item)
				MeleeWeapon.Raycast(item, "Primary", function(results)
					MeleeWeapon.ReplicateRaycast(item, "Primary", results)
				end)
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
			Attack = MeleeWeapon.GetDamageFunction("Primary")
		},
	},
}

function ClassicSword.new(params)
	params.Id = params.Id or "ClassicSword"

	local item = BaseTool.new(params)
	
	MeleeWeapon.AddRaycaster(item)
	WeaponAttacks.SetActionAsAttack(item, "Primary")
	
	ActionManagerConnector.Declare(item, ClassicSword)
	
	return item
end

return ClassicSword
