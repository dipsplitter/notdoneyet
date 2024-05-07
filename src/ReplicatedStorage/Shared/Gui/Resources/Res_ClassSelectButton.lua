local UiResource_ClassSelectButton = {
	Name = "ClassSelectButton",
	ScreenGui = "ClassSelectionMenu",
	
	Config = {},
	
	Fonts = {
		ClassCount = "GothamBold",
	},
	
	States = {
		Clicked = {
			Main = {
				BackgroundColor = "MediumGray",
				BackgroundTransparency = 0.25,
			},
		},
		
		Chosen = {
			Main = {
				BackgroundColor = "Charcoal",
				BackgroundTransparency = 0.1,
				
				SizeY = UDim.new(0.4, 0),
				
				Stroke = {
					Thickness = 3,
				}
			}
		},
		
		Locked = {
			Main = {
				Gradient = {
					Color = "MediumGray",
				},
			},
		},
	},
	
	Main = {
		Type = "ImageButton",
		
		AnchorPoint = "Center",
		AspectRatio = 1,
		
		SizeX = UDim.new(0.1, 0),
		SizeY = UDim.new(0.3, 0),
		
		CornerRadius = UDim.new(0.1, 0),
		Stroke = {
			Thickness = 1.5,
			Color = "DarkCharcoal",
			LineJoinMode = Enum.LineJoinMode.Bevel,
		},
		
		BackgroundTransparency = 0.25,
		BackgroundColor = "White",
		
		Gradient = {
			Color = "White"
		},
		
		FlexBehavior = {
			FlexMode = Enum.UIFlexMode.Shrink,
		},
	},
	
	Count = {
		Type = "TextLabel",
		FieldName = "Count",

		SizeX = UDim.new(1, 0),
		SizeY = UDim.new(0.2, 0),
		
		PosX = UDim.new(0, 0),
		PosY = UDim.new(0, 0),
		
		BackgroundTransparency = 1,
		
		TextScaled = true,
		FontFace = "ClassCount",
		TextXAlignment = Enum.TextXAlignment.Left,
	},
}

return UiResource_ClassSelectButton
