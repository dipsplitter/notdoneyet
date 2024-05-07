local FlareGun = {

	Base = {
		EquipSpeed = 0.2,

		Values = {
			Clip = {
				Max = 1,
			},
			ReserveAmmo = {
				Max = 20,
			},
		},

		Activations = {
			Primary = {
				Id = 0,
				--Keybinds = "Primary",

				--ActionType = {"Hold", "Base"},
				ActionType = "Base",
				CooldownTime = 0.5,

				Config = {
					Projectile = {
						["Flare"] = {
							SpawnOffset = CFrame.new(1.2, 0, -2),
							
							DamageProperties = {
								BaseDamage = 40,
							},
						}
					}

				},
			},

			Reload = {
				Id = 1,

				ActionType = "Custom",
				Config = {
					First = 1.5,

					AutoReloadDelay = 0.45,
					ReloadedValue = "Clip",
					ReserveValue = "ReserveAmmo",
				}
			}
		},
	},

	Animations = {
		Equip = "Weapons.FlareGun.Equip",
		
		PrimaryCharge = "Weapons.FlareGun.PrimaryCharge",
		PrimaryFire = "Weapons.FlareGun.PrimaryFire",

		Idle = "Weapons.FlareGun.Idle",
		
		Reload = "Weapons.FlareGun.Reload"
	},

	Sounds = {
		Equip = "Weapons.FireballLauncher.Equip",
		Shoot = "Weapons.FlareGun.Shoot",
	},
}

return FlareGun
