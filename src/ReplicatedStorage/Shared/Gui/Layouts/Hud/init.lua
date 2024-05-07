local HudLayout = {
	ScreenGui = "Hud",
	
	PlayerStatus = {
		PosX = UDim.new(0.08, 0),
		PosY = UDim.new(0.92, 0),
		AnchorPoint = "Center",
		
		SizeX = UDim.new(0.16, 0),
		SizeY = UDim.new(0.16, 0),
 	},
	
	ItemStatus = {
		PosX = UDim.new(0.9, 0),
		PosY = UDim.new(0.9, 0),
		AnchorPoint = "Center",
		
		SizeX = UDim.new(0.2, 0),
		SizeY = UDim.new(0.2, 0),
	},
	
	Hotbars = {
		PosX = UDim.new(0.5, 0),
		PosY = UDim.new(0.945, 0),
		AnchorPoint = "Center",

		SizeX = UDim.new(0.32, 0),
		SizeY = UDim.new(0.055, 0),
		
		ListLayout = {
			VerticalAlignment = Enum.VerticalAlignment.Center,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
		},
	}
}

return HudLayout
