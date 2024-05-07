local StatusEffectProperties = {
	DamageProperties = {
		BaseDamage = true,
		DamageType = true,
	},
	
	ImprovedWhenIncreased = {
		BaseDamage = true,
		Duration = true,
	},
	
	ImprovedWhenDecreased = {
		Tick = true,
	},
	
	IgnoreWhenStacking = {
		StackingParams = true,
	}
}

return StatusEffectProperties
