local RocketLauncher = {
	
	Base = {
		EquipSpeed = 0.3,

		Values = {
			Clip = {
				Max = 4,
			},
			ReserveAmmo = {
				Max = 20,
			},
		},

		Activations = {
			Primary = {
				Id = 0,
				--Keybinds = "Primary",

				ActionType = "Base",
				CooldownTime = 0.75,

				Config = {
					Projectile = {
						["Rocket"] = {
							SpawnOffset = CFrame.new(1, 0, -3),
							
							DamageProperties = {
								BaseDamage = 70,
								DistanceModifiers = {
									Max = 1.5,
									Min = 0.5,
									MaxDistance = 10,
									MinDistance = 100,
								},
							}
						}
					}

				},
			},

			Reload = {
				Id = 1,

				ActionType = "Custom",
				Config = {
					First = 0.2,
					Consecutive = 0.7,

					AutoReloadDelay = 0.8,
					ReloadedValue = "Clip",
					ReserveValue = "ReserveAmmo",
				}
			}
		},
	},

	Animations = {
		Equip = "Weapons.FireballLauncher.Equip",
		
		PrimaryFire = "Weapons.FireballLauncher.PrimaryFire",
		
		SecondaryCharge = "Weapons.FireballLauncher.SecondaryCharge",
		
		Idle = "Weapons.FireballLauncher.Idle",
		
		ReloadBegin = {
			Path = "Weapons.FireballLauncher.ReloadBegin",
			Action = "Reload",
			Modifiers = {
				Duration = "First",
			},
		},
		
		ReloadConsecutive = {
			Path = "Weapons.FireballLauncher.ReloadConsecutive",
			Action = "Reload",
			Modifiers = {
				Duration = "Consecutive",
			},
		},
		
		ReloadEnd = {
			Path = "Weapons.FireballLauncher.ReloadEnd",
		},
	},
	
	Sounds = {
		Equip = "Weapons.FireballLauncher.Equip",
		Shoot = "Weapons.FireballLauncher.Shoot",
	},
}

return RocketLauncher


