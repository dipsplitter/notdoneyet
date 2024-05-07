local UiResource_ArmorBar = {
	Name = "ArmorBar",
	ScreenGui = "Hud",
	
	Config = {
		LowArmorThreshold = 0.5,
		
		AbsorptionRanges = {
			{
				Range = {-math.huge, 31},
				Color = "DarkRed",
			},
			{
				Range = {31, 80},
				Color = "Orange",
			},
			{
				Range = {80, math.huge},
				Color = "BlueGreen",
			},
		},
	},
	
	Fonts = {
		MaxArmorFont = "GothamBoldThinStroked",
		ArmorFont = "GothamBoldStroked",
	},
	
	Animations = {
		Styles = {
			LowArmor = TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1, true, 0)
		},
		
		ArmorBonusPulse = {
			
		},
		
		LowArmorPulse = {
			Duration = 0.4,
			
			ArmorImageBackground = {
				Style = "LowArmor",
				Goals = {
					Stroke = {
						Thickness = 8,
						Color = "DarkRed",
					},
				},	
			},

			ArmorDisplay = {
				Style = "LowArmor",
				Goals = {
					TextStroke = {
						Thickness = 4,
						Color = "DarkRed",
					},

					TextColor3 = "LightRed",
				},
			},
		},
		
		StopLowArmorPulse = {
			StopEvents = {
				LowArmorPulse = 0
			}
		},
	},
	
	Main = {
		SizeX = UDim.new(0, 150),
		SizeY = UDim.new(0, 150),
		
		AnchorPoint = "Center",
		AspectRatio = 1,
	},
	
	ArmorImageBackground = { 
		Type = "ImageLabel",
		FieldName = "ArmorImageBackground",
		
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
	
	ArmorImage = {
		Type = "ImageLabel",
		FieldName = "ArmorImage",
		Parent = "ArmorImageBackground",
		
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
	
	ArmorBonusImage = {
		Type = "ImageLabel",
		FieldName = "ArmorBonusImage",
		
		Enabled = false,
	},
	
	MaxArmorDisplay = {
		Type = "TextLabel",
		FieldName = "MaxArmorDisplay",
		
		SizeX = UDim.new(0, 0),
		SizeY = UDim.new(0.2, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		
		AnchorPoint = "Center",

		PosX = UDim.new(0.5, 0),
		PosY = UDim.new(0.1, 0),
		
		LabelText = "%MaxArmor%",
		FontFace = "MaxArmorFont",
		TextSize = 14,
	},
	
	ArmorAbsorptionDisplay = {
		Type = "TextLabel",
		FieldName = "ArmorAbsorptionDisplay",

		SizeX = UDim.new(0, 0),
		SizeY = UDim.new(0.2, 0),
		AutomaticSize = Enum.AutomaticSize.X,

		AnchorPoint = "Center",

		PosX = UDim.new(0.5, 0),
		PosY = UDim.new(0.8, 0),

		LabelText = "%Absorption%",
		FontFace = "MaxArmorFont",
		TextSize = 14,
	},
	
	ArmorDisplay = {
		Type = "TextLabel",
		FieldName = "ArmorDisplay",
		
		SizeX = UDim.new(1, 0),
		SizeY = UDim.new(0.2, 0),
		
		AnchorPoint = "Center",
		
		PosX = UDim.new(0.5, 0),
		PosY = UDim.new(0.5, 0),

		ZIndex = 1,
		
		LabelText = "%Armor%",
		FontFace = "ArmorFont",
		TextScaled = true,
		TextColor = "White",
		
		TextPadding = {
			Vertical = UDim.new(0.1, 0),
			Horizontal = UDim.new(0.1, 0),
		},
	},
}

return UiResource_ArmorBar