local ClassSelectionMenu = {
	ScreenGui = "ClassSelectionMenu",
	
	ClassButtons = {
		PosX = UDim.new(0.5, 0),
		PosY = UDim.new(0.88, 0),
		AnchorPoint = "Center",

		SizeX = UDim.new(0.8, 0),
		SizeY = UDim.new(0.2, 0),
		
		ListLayout = {
			Padding = UDim.new(0, 5),
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			
			Wraps = true,
			ItemLineAlignment = Enum.ItemLineAlignment.Center,
		},
	},
	
	ClassDescription = {
		PosX = UDim.new(0.84, 0),
		PosY = UDim.new(0.375, 0),
		AnchorPoint = "Center",

		SizeX = UDim.new(0.3, 0),
		SizeY = UDim.new(0.65, 0),
		
		ListLayout = {
			Padding = UDim.new(0, 25),
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Top,
		},
	},
	
	ClassImage = {
		Type = "ImageLabel",
		
		PosX = UDim.new(0.5, 0),
		PosY = UDim.new(0.36, 0),
		AnchorPoint = "Center",
		
		SizeX = UDim.new(0.2, 0),
		SizeY = UDim.new(0.6, 0),
	},
	
	PlayButton = {
		Type = "TextButton",
		
		PosX = UDim.new(0.5, 0),
		PosY = UDim.new(0.7, 0),
		AnchorPoint = "Center",
		
		SizeX = UDim.new(0.15, 0),
		SizeY = UDim.new(0.1, 0),
		
		AspectRatio = 2,
	},
}

return ClassSelectionMenu
