local Hotbars = {
	Name = "Hotbars",
	
	ItemsHotbar = {
		LayoutOrder = 1,

		SizeX = UDim.new(0, 0),
		SizeY = UDim.new(1, 0),
		AutomaticSize = Enum.AutomaticSize.X,

		ListLayout = {
			VerticalAlignment = Enum.VerticalAlignment.Center,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 15),
		},
	},

	AbilitiesHotbar = {
		LayoutOrder = 2,

		SizeX = UDim.new(0, 0),
		SizeY = UDim.new(1, 0),
		AutomaticSize = Enum.AutomaticSize.X,

		ListLayout = {
			VerticalAlignment = Enum.VerticalAlignment.Center,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 15),
		},
	},
	
}

return Hotbars
