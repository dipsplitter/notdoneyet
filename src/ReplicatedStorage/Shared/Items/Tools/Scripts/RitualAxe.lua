local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local MeleeWeapon = Framework.GetShared("MeleeWeapon")
local ActionManagerConnector = Framework.GetShared("ActionManagerConnector")

local StatusEffectService = Framework.GetServer("StatusEffectService")

local BaseMelee = Framework.GetShared("ClassicSword")

local RitualAxe = {
	Server = {
		Primary = {
			
			Attack = MeleeWeapon.GetDamageFunction("Primary", {

				PostDamage = function(target, item)

					if not StatusEffectService.GetEffect(target, "Burning") then
						return
					end

					StatusEffectService.Apply({
						Name = "Immolate",
						Source = item,
						Target = target,
					})

				end,

			})
			
		}
	}
}

function RitualAxe.new(params)
	params.Id = params.Id or "RitualAxe"

	local melee = BaseMelee.new(params)
	ActionManagerConnector.Declare(melee, RitualAxe)
	
	return melee
end

return RitualAxe
