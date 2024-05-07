local P_Rocket = {
	Base = {
		BlastRadius = 9,

		DamageProperties = {
			DamageType = "Blast",
			BaseDamage = 80,

			DistanceModifiers = {
				Max = 1.25,
				Min = 0.5,

				MaxDistance = 10,
				MinDistance = 100,
			},

			SplashModifiers = {
				Min = 0.5,
				MaxDistance = 2,
				MinDistance = 8,
			},

			SelfDamageScale = 0.3,

			KnockbackProperties = {
				SelfDamageScale = 4,
			},
		},

		HorizontalVelocity = 70,

		ImpulseIgnoresMass = true,
	}
}

return P_Rocket
