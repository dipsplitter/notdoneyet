local HotbarSlot = {
	Name = "HotbarSlot",
	
	Config = {
		Active = "Smoke",
		Inactive = "DarkCharcoal",
	},
	
	Fonts = {
		Keybind = "GothamBoldStroked",
		ItemName = "Gotham",
	},
	
	Main = {
		Type = "ImageLabel",
		AnchorPoint = "Center",
		
		SizeX = UDim.new(1, 0),
		SizeY = UDim.new(1, 0),
		AspectRatio = 1,
		
		BackgroundColor = "White",
		BackgroundTransparency = 0.5,
		
		Stroke = {
			Thickness = 4,
			Color = "DarkCharcoal",
		},
		
		Gradient = {
			Color = {
				{0, "Smoke"},
				{0.5, "MediumGray"},
				{1, "Smoke"},
			},
			Rotation = 90,
		},
	},
	
	ItemNameLabel = {
		Type = "TextLabel",
		FieldName = "ItemNameLabel",
		
		AnchorPoint = "Center",
		
		PosX = UDim.new(0.5, 0),
		PosY = UDim.new(0.5, 0),

		SizeX = UDim.new(0.8, 0),
		SizeY = UDim.new(0.8, 0),
		
		FontFace = "ItemName",
		TextScaled = true, 
		
		BackgroundTransparency = 1,
	},
	
	ItemImage = {
		Type = "ImageLabel",
		FieldName = "ItemImage",
		
		AnchorPoint = "Center",

		PosX = UDim.new(0.5, 0),
		PosY = UDim.new(0.5, 0),
		
		SizeX = UDim.new(0.9, 0),
		SizeY = UDim.new(0.9, 0),
		
		ScaleType = Enum.ScaleType.Fit,
		
		BackgroundTransparency = 1,
	},
	
	KeybindIcon = {
		Type = "TextLabel",
		FieldName = "KeybindIcon",
		
		AnchorPoint = "Center",
		
		ZIndex = -1000,

		PosX = UDim.new(0, 0),
		PosY = UDim.new(0, 0),
		
		SizeX = UDim.new(0.35, 0),
		SizeY = UDim.new(0.35, 0),
		AspectRatio = 1,
		
		CornerRadius = UDim.new(1, 0),
		Stroke = {
			Thickness = 1.5,
			Color = "DarkCharcoal",
		},
		
		Padding = {
			Vertical = UDim.new(0.1, 0),
			Horizontal = UDim.new(0.1, 0),
		},
		
		BackgroundColor = "Smoke",
		BackgroundTransparency = 0,
		
		TextScaled = true,
		TextColor = "White",
		FontFace = "Keybind",
		
		Gradient = {
			Color = {
				{0, "White"},
				{1, "Smoke"},
			},
			Rotation = 90,
		},
	},
}

return HotbarSlot
