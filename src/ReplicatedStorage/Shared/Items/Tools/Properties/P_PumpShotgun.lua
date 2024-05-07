local PumpShotgun = {
	
	Base = {
		EquipSpeed = 0.25,

		Values = {
			Clip = {
				Max = 6,
			},
			ReserveAmmo = {
				Max = 30,
			},
		},

		Activations = {
			Primary = {
				Id = 0,
				--Keybinds = "Primary",
				CooldownTime = 0.6,

				Config = {
					DamageProperties = {
						BaseDamage = 6,
						DistanceModifiers = {
							Max = 1.5,
							Min = 0.5,
							MaxDistance = 8,
							MinDistance = 40,
						},
						DamageType = "Bullet",
					},
					
					SpreadPattern = {
						{
							Type = "Center", 
							Count = 1,
							AngleMultiplier = 0,
						},

						{
							Type = "Ring",
							Count = 9,
							AngleMultiplier = 1,
						},
					},

					MaxSpread = 0.04,
					MaxRange = 500,
				}
			},

			Reload = {
				Id = 1,

				ActionType = "Custom",

				Config = {
					First = 0.35,
					Consecutive = 0.6,

					AutoReloadDelay = 0.75,
					ReloadedValue = "Clip",
					ReserveValue = "ReserveAmmo",
				}
			}
		},
	},
	
	Animations = {
		Equip = "GenericWeapon.Shotgun.Equip",
		Shoot = "GenericWeapon.Shotgun.Shoot",
		Idle = "GenericWeapon.Shotgun.Idle",
		
		ReloadBegin = {
			Path = "GenericWeapon.Shotgun.ReloadBegin",
			Action = "Reload",
			Modifiers = {
				Duration = "First",
			},
		},

		ReloadConsecutive = {
			Path = "GenericWeapon.Shotgun.ReloadConsecutive",
			Action = "Reload",
			Modifiers = {
				Duration = "Consecutive",
			},
		},

		ReloadEnd = {
			Path = "GenericWeapon.Shotgun.ReloadEnd",
		},
	},
	
	Sounds = {
		Equip = "Weapons.Shotgun.Equip",
		Shoot = "Weapons.Shotgun.Shoot",
		Reload = "Weapons.Shotgun.Reload",
	},
}

return PumpShotgun