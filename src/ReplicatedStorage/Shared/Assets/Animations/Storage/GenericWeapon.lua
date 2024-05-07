local GenericWeaponAnimations = {
	OneHandedSword = {
		Equip = {
			Id = 14400923734,
		},

		Idle = {
			Id = 14403746939,
			Weight = 0.9,
			Looped = true,
		},
		
		AttackGroup1 = {
			Slash1 = {
				Id = 14402125055,
			},

			Slash2 = {
				Id = 14543922433,
			},

			UpperStrike = {
				Id = 14543280957,
			},
		},
		
	},
	
	Sabre = {
		Equip = {
			Id = 16759243227,
		},
		
		Idle = {
			Id = 16783640047,
			Looped = true,
		},
	},
	
	OneHandedRevolver = {
		Equip = {
			Id = 14946174472,
			FadeTime = 0.15,
			Weight = 0.9,
		},

		Shoot = {
			Id = 14993523681,
			Weight = 0.95,
			FadeTime = 0.1,
		},

		Idle = {
			Id = 14954436684,	
			Weight = 0.75,
			Looped = true,
		},

		Reload = {
			Id = 14993500867,
		}
	},
	
	UnarmedMelee = {
		Equip = {
			Id = 15742703859,
		},
		
		-- TODO: Reanimate this. It's so bad
		Idle = {
			Id = 15742839890,	
			Weight = 0.75,
			Looped = true,
			Speed = 0.5,
		},
		
		Punch = {
			Id = 15742329837,
		},
	},
	
	Shotgun = {
		Equip = {
			Id = 16960169736,
		},
		
		Shoot = {
			Id = 16963187124,--16960394121,
		},
		
		Idle = {
			Id = 16960564812,
			Looped = true,
		},
		
		ReloadBegin = {
			Id = 16964360465,
		},
		
		ReloadConsecutive = {
			Id = 16964527039,
			Looped = true
		},
		
		ReloadEnd = {
			Id = 16964707804,
		},
	},
}

return GenericWeaponAnimations
