local Rex = {
	
	Base = {
		EquipSpeed = 0.5,

		BaseDamage = 40,

		Values = {
			Clip = {
				Max = 6,
			},
			ReserveAmmo = {
				Max = 24,
			},
		},

		Activations = {
			Primary = {
				Id = 0,
				--Keybinds = "Primary",
				CooldownTime = 0.4,

				Config = {
					DamageProperties = {
						BaseDamage = 40,
						DistanceModifiers = {
							Max = 1.5,
							Min = 0.5,
							MaxDistance = 8,
							MinDistance = 48,
						},
						DamageType = "Bullet"
					},

					MaxRange = 500,

					MinSpread = 0,
					MaxSpread = 0.08,
					ConsecutiveSpreadIncrease = 0.02,
					SpreadRecovery = 1.2,
				}
			},

			Reload = {
				Id = 1,

				ActionType = "Custom",

				Config = {
					First = 1,

					AutoReloadDelay = 0.5,
					ReloadedValue = "Clip",
					ReserveValue = "ReserveAmmo",
				}
			}
		},
	},
	
	Animations = {
		Equip = "GenericWeapon.OneHandedRevolver.Equip",
		Shoot = "GenericWeapon.OneHandedRevolver.Shoot",
		Idle = "GenericWeapon.OneHandedRevolver.Idle",
		Reload = "GenericWeapon.OneHandedRevolver.Reload"
	},
	
	Sounds = {
		Equip = "Weapons.REX.Equip",
		Shoot = "Weapons.REX.Shoot",
		Reload = "Weapons.REX.Reload",
	},
}

return Rex


