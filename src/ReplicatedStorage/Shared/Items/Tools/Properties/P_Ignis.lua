local Ignis = {
	
	NETWORK_TABLE = {
		PARENT = "ClassicSword"
	}, 

	Base = {
		EquipSpeed = 0.3,

		BaseDamage = 50,

		Activations = {
			Primary = {
				Id = 0,
				
				ActionType = {"Hold", "Base"},
				CooldownTime = 0.8,

				Config = {
					
					Timestamps = {
						AttackStart = "AttackStart",
						AttackEnd = "AttackEnd",
					},
					
					Directions = {
						Left = {-60, 60},
						Up = {60, 120},
						Right = {120, -120},
						Down = {-120, -60},
					},
					
					Left = {
						Windup = 0.2,
						CooldownTime = 0.7,
						
						Size = Vector3.new(4, 4, 2),
						DamageProperties = {
							BaseDamage = 50,
							DamageType = "Melee",
						},
					},
					
					Right = {
						Windup = 0.2,
						CooldownTime = 0.7,
						
						Size = Vector3.new(4, 4, 2),
						DamageProperties = {
							BaseDamage = 50,
							DamageType = "Melee",
						},
					},
					
					Up = {
						Windup = 0.3,
						CooldownTime = 1,
						
						Size = Vector3.new(2, 2, 5),
						DamageProperties = {
							BaseDamage = 75,
							DamageType = "Melee",
						},
					},
					
					Down = {
						Windup = 0.2,
						CooldownTime = 0.55,
						Size = Vector3.new(3, 3, 9),
						DamageProperties = {
							BaseDamage = 60,
							DamageType = "Melee",
						},
					},
				}
			}
		},
	},

	Animations = {
		Equip = "GenericWeapon.Sabre.Equip",
		
		Left = "MeleeSwingDirections.Sabre.Left",
		Right = "MeleeSwingDirections.Sabre.Right",
		Up = "MeleeSwingDirections.Sabre.Up",
		Down = "MeleeSwingDirections.Sabre.Down",

		Idle = "GenericWeapon.Sabre.Idle",
	},

	Sounds = {
		Equip = "Weapons.ClassicSword.Equip",
		Swing = "Weapons.RitualAxe.Swing",
	},
	
}

return Ignis
