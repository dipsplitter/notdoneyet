local Types = {
	ClampedValue = "ClampedValue",
	Property = "Property"
}

local DefaultCharacterAttributes = {
	
	Health = {
		Value = 100,
		Type = Types.ClampedValue,
	},
	
	Armor = {
		Value = 100,
		DefaultValue = false,
		Type = Types.ClampedValue,
	},
	
	DamageResistance = {
		Value = 1,
		Type = Types.Property,
	},
	
	DamageMultiplier = {
		Value = 1,
		Type = Types.Property,
	},
	
	HealingMultiplier = {
		Value = 1,
		Type = Types.Property,
	},
	
	WalkSpeed = {
		Value = 16,
		Type = Types.Property,
	},
	
	JumpPower = {
		Value = 50,
		Type = Types.Property,
	},
	
	ArmorAbsorption = {
		Value = 0.5,
		Type = Types.Property,
		Parent = "Armor",
	},
	
}

return DefaultCharacterAttributes
