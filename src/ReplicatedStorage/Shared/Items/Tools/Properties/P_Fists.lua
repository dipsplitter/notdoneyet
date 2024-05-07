local Fists = {
	
	NETWORK_TABLE = {
		PARENT = "ClassicSword",
	},

	Base = {
		EquipSpeed = 0.25,

		BaseDamage = 80,

		Activations = {
			Primary = {
				Id = 0,
				--Keybinds = "Primary",

				ActionType = "Base",
				CooldownTime = 1.1,

				Config = {
					Timestamps = {
						Attack = "Attack",
					},
					
					MaxHits = 3,

					DamageProperties = {
						BaseDamage = 75,
						DamageType = "Melee",
					},

					MaxRange = 8,
				}
			}
		},
	},

	Animations = {
		Equip = "GenericWeapon.UnarmedMelee.Equip",

		Primary = "GenericWeapon.UnarmedMelee.Punch",

		Idle = "GenericWeapon.UnarmedMelee.Idle",
	},

	Sounds = {
		Swing = "Weapons.Fists.Punch",
	},
}

return Fists
