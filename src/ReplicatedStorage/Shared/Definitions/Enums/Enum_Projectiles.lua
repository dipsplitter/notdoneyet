local Enum_Projectiles = {
	
	Enum_ProjectileTypes = {
		Fireball = 0,
		Flare = 1,
		Rocket = 2,
	},
	
	Enum_ProjectileEventTypes = {
		Touched = 0,
		PropertyChange = 1,
	},
	
	Enum_ProjectilePropertyFlags = {
		Elasticity = 2^0,
		ElasticityWeight = 2^1,

		Density = 2^2,
		DensityWeight = 2^3,
		
		Friction = 2^4,
		FrictionWeight = 2^5,
		
		Transparency = 2^6,
		Reflectance = 2^7,
	},
}

return Enum_Projectiles
