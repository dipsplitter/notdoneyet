local ItemMasterList = {
	["FireballLauncher"] = {
		ItemType = "Tool",
		SchemaId = 1,
		DisplayName = "Fireball Launcher",

		UsedBy = {
			Survivalist = true,
		},
		DefaultSlot = "Primary",
	},

	["FlareGun"] = {
		ItemType = "Tool",
		SchemaId = 2,
		DisplayName = "Flare Gun",

		UsedBy = {
			Survivalist = true,
		},
		DefaultSlot = "Tertiary",
	},

	["ClassicSword"] = {
		ItemType = "Tool",
		SchemaId = 3,
		DisplayName = "Classic Sword",

		UsedBy = {
			Survivalist = true,
			Medic = true, -- TODO: NO, he CANNOT use it !!!
		},
		DefaultSlot = "Melee",
	},
	
	["RitualAxe"] = {
		ItemType = "Tool",
		SchemaId = 600,
		DisplayName = "Ritual Axe",
		
		UsedBy = {
			Survivalist = true,
		},
		DefaultSlot = "Melee",
	},

	["REX"] = {
		ItemType = "Tool",
		SchemaId = 4,
		DisplayName = "REX",

		UsedBy = {
			Survivalist = true,
			Fatman = true,
		},
		DefaultSlot = "Secondary",
		ClassSlot = {
			Fatman = "Primary",
		},
	},

	["Fists"] = {
		ItemType = "Tool",
		SchemaId = 100,
		DisplayName = "Fists",

		UsedBy = {
			Fatman = true,
		},

		DefaultSlot = "Melee",
	},
	
	["Ignis"] = {
		ItemType = "Tool",
		SchemaId = 5,
		DisplayName = "Ignis",
		
		UsedBy = {
			Survivalist = true,
			Warrior = true,
		},
		DefaultSlot = "Melee",
	},
	
	["PumpShotgun"] = {
		ItemType = "Tool",
		SchemaId = 6,
		DisplayName = "Pump Shotgun",
		
		UsedBy = {
			Fatman = true,
			Soldier = true,
		},
		DefaultSlot = "Primary",
		
		ClassSlot = {
			Soldier = "Secondary",
		},
	},
	
	["RocketLauncher"] = {
		ItemType = "Tool",
		SchemaId = 7,
		DisplayName = "Rocket Launcher",
		
		UsedBy = {
			Soldier = true,
		},
		
		DefaultSlot = "Primary",
	},
	
	["KnockbackDebug"] = {
		ItemType = "Tool",
		SchemaId = 1000,
		DisplayName = "KnockbackDebug",
		
		UsedBy = {
			Survivalist = true,
		},
		DefaultSlot = "Primary",
	},
}

return ItemMasterList
