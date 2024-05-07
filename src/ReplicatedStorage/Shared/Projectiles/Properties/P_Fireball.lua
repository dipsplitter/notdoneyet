local P_Fireball = {
	Base = {
		
		BlastRadius = 7,

		DamageProperties = {
			DamageType = {Blast = 1, Fire = 0.25},
			BaseDamage = 80,

			DistanceModifiers = {
				Max = 1.25,
				Min = 0.5,
				MaxDistance = 5,
				MinDistance = 35,
			},

			SplashModifiers = {
				Min = 0.5,
				MaxDistance = 2,
				MinDistance = 7,
			},
		},

		VerticalVelocity = 20,
		HorizontalVelocity = 60,

		ImpulseIgnoresMass = true,

		ExplodeOnAnyTouchDelay = 1,
		
	}
}

return P_Fireball
