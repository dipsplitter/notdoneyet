local RitualAxe = {
	
	NETWORK_TABLE = {
		PARENT = "ClassicSword"
	}, 

	Base = {
		EquipSpeed = 0.3,

		Activations = {
			Primary = {
				Id = 0,
				--Keybinds = "Primary",

				ActionType = "Base",
				CooldownTime = 1.1,

				Config = {
					Timestamps = {
						Attack = 0.35,
					},

					DamageProperties = {
						BaseDamage = 40,
						DamageType = "Melee",
					},

					MaxRange = 7,
				}
			}
		},
	},

	Animations = {
		Equip = "Weapons.RitualAxe.Equip",

		Primary = "Weapons.RitualAxe.AttackGroup1",

		Idle = "Weapons.RitualAxe.Idle",
	},

	Sounds = {
		Equip = "Weapons.ClassicSword.Equip",
		Swing = "Weapons.RitualAxe.Swing",
	},
	
}

return RitualAxe
