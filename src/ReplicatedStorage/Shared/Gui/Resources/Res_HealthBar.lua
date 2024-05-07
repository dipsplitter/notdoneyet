local UiResource_HealthBar = {
	Name = "HealthBar",
	ScreenGui = "Hud",
	
	Config = {
		LowHealthThreshold = 0.5,
	},
	
	Fonts = {
		MaxHealthFont = "GothamBoldThinStroked",
		HealthFont = "GothamBoldStroked",
	},
	
	Animations = {
		Styles = {
			LowHealth = TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1, true, 0)
		},
		
		HealthBonusPulse = {
			
		},
		
		LowHealthPulse = {
			Duration = 0.4,
			
			HealthImageBackground = {
				Style = "LowHealth",
				Goals = {
					Stroke = {
						Thickness = 8,
						Color = "DarkRed",
					},
				},	
			},
			
			HealthDisplay = {
				Style = "LowHealth",
				Goals = {
					TextStroke = {
						Thickness = 4,
						Color = "DarkRed",
					},
					
					TextColor3 = "LightRed",
				},
			},
		},
		
		StopLowHealthPulse = {
			StopEvents = {
				LowHealthPulse = 0,
			}
		}
	},
	
	Main = {
		SizeX = UDim.new(0, 180),
		SizeY = UDim.new(0, 180),
		
		AnchorPoint = "Center",
		AspectRatio = 1,
	},
	
	HealthImageBackground = { 
		Type = "ImageLabel",
		FieldName = "HealthImageBackground",
		
		AnchorPoint = "Center",

		PosX = UDim.new(0.5, 0),
		PosY = UDim.new(0.5, 0),
		
		AspectRatio = 1,
		
		SizeX = UDim.new(0.6, 0),
		SizeY = UDim.new(0.6, 0),
		
		ZIndex = -10,
		
		CornerRadius = UDim.new(1, 0),
		BackgroundColor = "MediumGray",
		
		Stroke = {
			Thickness = 5,
			Color = "DarkCharcoal",
		},
		
		Gradient = {
			Color = {
				{0, "LightGray"},
				{1, "White"},
			},
			Rotation = -90,
		},
		
		Enabled = true,
	},
	
	HealthImage = {
		Type = "ImageLabel",
		FieldName = "HealthImage",
		Parent = "HealthImageBackground",
		
		AnchorPoint = "Center",

		PosX = UDim.new(0.5, 0),
		PosY = UDim.new(0.5, 0),
		
		SizeX = UDim.new(1, 0),
		SizeY = UDim.new(1, 0),
		
		ZIndex = -5,
		
		CornerRadius = UDim.new(1, 0),
		
		Gradient = {
			Color = {
				{0, "LightGray"},
				{1, "White"},
			},
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(0.999, 0),
				NumberSequenceKeypoint.new(1, 1),
			}),
			Rotation = -90,
		},

		Enabled = true,
	},
	
	HealthBonusImage = {
		Type = "ImageLabel",
		FieldName = "HealthBonusImage",
		
		Enabled = false,
	},
	
	MaxHealthDisplay = {
		Type = "TextLabel",
		FieldName = "MaxHealthDisplay",
		
		SizeX = UDim.new(0, 0),
		SizeY = UDim.new(0.2, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		
		AnchorPoint = "Center",

		PosX = UDim.new(0.5, 0),
		PosY = UDim.new(0.1, 0),
		
		LabelText = "%MaxHealth%",
		FontFace = "MaxHealthFont",
		TextSize = 14,
	},
	
	HealthDisplay = {
		Type = "TextLabel",
		FieldName = "HealthDisplay",
		
		SizeX = UDim.new(1, 0),
		SizeY = UDim.new(0.2, 0),
		
		AnchorPoint = "Center",
		
		PosX = UDim.new(0.5, 0),
		PosY = UDim.new(0.5, 0),

		ZIndex = 1,
		
		LabelText = "%Health%",
		FontFace = "HealthFont",
		TextScaled = true,
		TextColor = "White",
		
		TextPadding = {
			Vertical = UDim.new(0.1, 0),
			Horizontal = UDim.new(0.1, 0),
		},
	},
}

return UiResource_HealthBar
