local P_Flare = {
	Base = {
		DamageProperties = {
			DamageType = "Fire",
			BaseDamage = 45,

			StatusEffects = {
				Burning = {},
			},
		},

		BurningParams = {

		},

		VerticalVelocity = 5,
		HorizontalVelocity = 140,

		GravityScale = 0.75,
		ImpulseIgnoresMass = true,
	}
}

return P_Flare
