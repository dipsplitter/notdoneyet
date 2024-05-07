local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local DECLARE = Framework.GetShared("DT_NetworkedProperties").DeclareProperty

local FireballLauncher = {
	
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

				ActionType = {"Hold", "Base"},
				CooldownTime = 0.75,

				Config = {
					MaxHoldTime = 2,

					Projectile = {
						["Fireball"] = {
							SpawnOffset = CFrame.new(1, 0, -3),
							
							DamageProperties = {
								BaseDamage = 50,
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
					First = 0.4,
					Consecutive = 0.65,

					AutoReloadDelay = 1,
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

return FireballLauncher


