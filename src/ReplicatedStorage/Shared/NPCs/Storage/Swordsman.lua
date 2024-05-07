local Swordsman = {
	["CharacterStats"] = {
		Health = 300,
		Armor = 50,
	},
	
	["Stats"] = {
		MaxVisionRange = 100,
		FOV = 100,
		ThinkTime = 0.1,
		
		DeaggroTime = 4,
	},
	
	Inventory = {
		Hotbars = {
			Main = {
				Slots = {
					Primary = Enum.KeyCode.One,
					Melee = Enum.KeyCode.Two,
				}
			}
		}
		
	}
}

return Swordsman
