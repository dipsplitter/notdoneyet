local UiResource_AmmoCounter = {
	Name = "AmmoCounter",
	ScreenGui = "Hud",
	
	Config = {},
	
	Fonts = {
		ItemName = "GothamBold",
		LoadedValue = "GothamBoldStroked",
	},
	
	Main = {
		SizeX = UDim.new(0, 150),
		SizeY = UDim.new(0, 150),
		
		AnchorPoint = "Center",
		AspectRatio = 1.4,
		
		LayoutOrder = -10000,
	},
	
	CounterBackground = {
		Type = "ImageLabel",
		FieldName = "CounterBackground",
		
		AnchorPoint = "Center",

		PosX = UDim.new(0.5, 0),
		PosY = UDim.new(0.5, 0),

		SizeX = UDim.new(1, 0),
		SizeY = UDim.new(1, 0),
		
		BackgroundColor = "MediumGray",

		Stroke = {
			Color = "Charcoal",
			Thickness = 4,
		},
		
		Gradient = {
			Color = {
				{0, "White"},
				{1, "LightGray"},
			},
			Rotation = -90,
		},
	},
	
	-- TEMP
	ItemNameLabel = {
		Type = "TextLabel",
		FieldName = "ItemNameLabel",
		
		AnchorPoint = "Top",
		
		PosX = UDim.new(0.5, 0),
		PosY = UDim.new(0, 0),
		
		SizeX = UDim.new(1, 0),
		SizeY = UDim.new(0.4, 0),
		
		LabelText = "%EquippedItemName%",
		FontFace = "ItemName",
		TextScaled = true,
		TextColor = "White",
		
		ZIndex = 100,
		
		Padding = {
			Vertical = UDim.new(0.1, 0),
			Horizontal = UDim.new(0.1, 0),
		},
	},
	
	ReloadedValueLabel = {
		Type = "TextLabel",
		FieldName = "ReloadedValueLabel",
		
		AnchorPoint = "Center",

		PosX = UDim.new(0.3, 0),
		PosY = UDim.new(0.75, 0),

		SizeX = UDim.new(0.5, 0),
		SizeY = UDim.new(0.4, 0),
		
		BackgroundTransparency = 1,

		LabelText = "%Loaded%",
		FontFace = "LoadedValue",
		TextScaled = true,
		TextColor = "White",
		
		ZIndex = 100,
	},
	
	ReserveValueLabel = {
		Type = "TextLabel",
		FieldName = "ReserveValueLabel",

		AnchorPoint = "Center",

		PosX = UDim.new(0.75, 0),
		PosY = UDim.new(0.75, 0),

		SizeX = UDim.new(0.3, 0),
		SizeY = UDim.new(0.3, 0),
		
		BackgroundTransparency = 1,

		LabelText = "%Reserve%",
		FontFace = "LoadedValue",
		TextScaled = true,
		TextColor = "White",

		ZIndex = 100,
	},
	
	LargeReserveValueLabel = {
		Type = "TextLabel",
		FieldName = "LargeReserveValueLabel",

		AnchorPoint = "Center",

		PosX = UDim.new(0.5, 0),
		PosY = UDim.new(0.75, 0),

		SizeX = UDim.new(0.8, 0),
		SizeY = UDim.new(0.5, 0),

		BackgroundTransparency = 1,

		LabelText = "%Reserve%",
		FontFace = "LoadedValue",
		TextScaled = true,
		TextColor = "White",
		
		Visible = false,

		ZIndex = 100,
	}
}

return UiResource_AmmoCounter