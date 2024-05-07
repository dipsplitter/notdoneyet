local DamageTypes = {
	
	--[[
	Damage calculation normally consists of summing the typed damage * a proportion * any relevant multipliers
	Flag multipliers are multiplied to the final sum to obtain the total damage
	]]
	Flags = {
		Physical = {Id = 1},
		Magic = {Id = 2},
		Ranged = {Id = 3},
		Elemental = {Id = 4},
		
		MiniCritical = {
			Properties = {
				AffectedByRangeNegatively = false,
			},
			
			Multipliers = {
				DamageMultiplier = 1.35,
			},
			
			Id = 5,
		},
		
		Critical = {
			Properties = {
				AffectedByRange = false,
			},
			
			Multipliers = {
				DamageMultiplier = 3,
			},
			
			Id = 6,
		},
		
		SuperCritical = {
			Properties = {
				AffectedByRange = false,
			},

			Multipliers = {
				DamageMultiplier = 6,
			},

			Id = 7,
		},
		
		Environmental = {Id = 8},
		Unknown = {Id = 9},
	},
	
	--[[ 
	Damage type entries:
	
	Damage type name: flags table
	Flags included will be unconditionally true/false during damage calculation
	
	Dealing melee damage but attempting to set the ranged flag to true will not change any behavior;
	it will not be considered ranged damage and not take into account ranged damage modifiers
	
	Setting the critical flag to true will give the damage the 3x multiplier because the flag was by default set to false in the entry's table
	
	If a damage event is set to be melee (not ranged) and blast (ranged), the ranged flag will be set to the damage type with the
	greater proportion (e.g. melee: 3, blast: 1 -> not considered range); ties are decided by the greater damage type id 
	(e.g. melee: 1, blast: 1 -> melee has id 1, blast has id 3, so it's ranged)
	]]
	
	Melee = {
		Flags = {
			Physical = true,
			Ranged = false,
		},
		
		Id = 1,
	},
	
	Bullet = {
		Flags = {
			Physical = true,
			Ranged = true,
		},
		
		Properties = {
			AffectedByRange = true,
		},
		
		Id = 2,
	},
	
	Blast = {
		Flags = {
			Physical = true,
			Ranged = true,
		},
		
		Properties = {
			AffectedByRange = true,
			AffectedBySplash = true,
		},
		
		Id = 3,
	},
	
	Fire = {
		Flags = {
			Physical = true,
			Elemental = true,
		},
		
		Id = 4,
	},
	
	Fall = {
		Flags = {
			Environmental = true,
			Physical = true,
			Ranged = false,
		},
		
		Id = 5,
	},
}

return DamageTypes
