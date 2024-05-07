local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local DECLARE = Framework.GetShared("DT_NetworkedProperties").DeclareProperty

local ClassicSword = {
	Base = {
		EquipSpeed = 0.5,

		BaseDamage = 65,

		Activations = {
			Primary = {
				Id = 0,
				--Keybinds = "Primary",

				ActionType = "Base",
				CooldownTime = 0.8,

				Config = {
					Timestamps = {
						Attack = 0.25
					},

					DamageProperties = {
						BaseDamage = 65,
						DamageType = "Melee",
					},

					MaxRange = 7,
				}
			}
		},
	},
	
	Animations = {
		Equip = "GenericWeapon.OneHandedSword.Equip",
		
		Primary = "GenericWeapon.OneHandedSword.AttackGroup1",
		
		Idle = "GenericWeapon.OneHandedSword.Idle",
	},
	
	Sounds = {
		Equip = "Weapons.ClassicSword.Equip",
		Swing = "Weapons.ClassicSword.Swing",
		
	},
}

return ClassicSword


