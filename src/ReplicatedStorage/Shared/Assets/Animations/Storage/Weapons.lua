local Weapons = {
	FireballLauncher = {
		Equip = {
			Id = 15136561353,
		},
		
		PrimaryFire = {
			Id = 15143589673,
		},

		SecondaryCharge = {
			Id = 15144458469,
			Looped = true,
		},

		Idle = {
			Id = 15144571973,
			Looped = true,
		},
		
		ReloadBegin = {
			Id = 15443836688,
		},
		
		ReloadConsecutive = {
			Id = 15425909812,
			Looped = true,
		},
		
		ReloadEnd = {
			Id = 15425941249,
		}
	},
	
	FlareGun = {
		Equip = {
			Id = 15924054861,
		},
		
		PrimaryCharge = {
			Id = 15924207089,
		},
		
		PrimaryFire = {
			Id = 15932911487,
		},
		
		Reload = {
			Id = 15932601199,
		},
		
		Idle = {
			Id = 15941000077,
			Looped = true,
			Speed = 0.5,
		}
	},
	
	RitualAxe = {
		Equip = {
			Id = 16192234892,
		},
		
		AttackGroup1 = {
			RightSwing = {
				Id = 16203707224
			},
			
			LeftSwing = {
				Id = 16220250797
			},
		},
		
		
		Idle = {
			Id = 16219026216,
			Looped = true,
		}
		
	}
}

return Weapons
