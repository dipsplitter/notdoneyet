local PlayerStatus = {
	Name = "PlayerStatus",
	
	HealthBar = {
		Main = {
			PosX = UDim.new(0.45, 0),
			PosY = UDim.new(0.5, 0),
			
			SizeX = UDim.new(0.5, 0),
			SizeY = UDim.new(1.2, 0),
		},
	},

	ArmorBar = {
		Main = {
			PosX = UDim.new(0.8, 0),
			PosY = UDim.new(0.5, 0),
			
			SizeX = UDim.new(0.45, 0),
			SizeY = UDim.new(1, 0),
		},
	},
}

return PlayerStatus
