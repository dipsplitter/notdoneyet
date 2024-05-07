local UiResource_DamageIndicator = {
	Name = "DamageIndicator",
	ScreenGui = "Hud",
	
	Config = {
		BatchWindow = 1,
		RandomOffset = 2,
	},
	
	Fonts = {
		DamageNumberFont = "ArialBoldStroked",
	},
	
	Colors = {
		Health = "Red",
		Armor = "BlueGreen",
	},
	
	Animations = {
		Styles = {
			Fadein = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0),
		},
		
		Fadeout = {
			Duration = 1,
			
			Main = {
				Style = "Fadein",
				Goals = {
					PositionDelta = Vector3.new(0, 5, 0),
				}
			},
			
			HealthDisplay = {
				Style = "Fadein",
				Goals = {
					TextTransparency = 0.75,
					TextSize = 22,
					TextStroke = {
						Transparency = 0.9,
						Thickness = 1,
					},
				},
			},
			
			ArmorDisplay = {
				Style = "Fadein",
				Goals = {
					TextTransparency = 0.75,
					TextSize = 22,
					TextStroke = {
						Transparency = 0.9,
						Thickness = 1,
					},
				},
			},
		},

		Fadein = {
			Duration = 0.15,
			
			StopEvents = {
				Fadeout = 0,	
			},
			
			StartEvents = {
				Fadeout = 0.2,
			},
			
			Main = {
				Style = "Fadein",
				Goals = {
					SizeScale = 1.3,
				}
			},
			
			HealthDisplay = {
				Style = "Fadein",
				Goals = {
					TextSize = 30,
				}
			},
			
			ArmorDisplay = {
				Style = "Fadein",
				Goals = {
					TextSize = 30,
				}
			},
		},
	},
	
	Main = {
		Type = "BillboardGui",
		FieldName = "Main",
		
		SizeX = UDim.new(0, 200),
		SizeY = UDim.new(0, 50),
		
		ListLayout = {
			VerticalAlignment = Enum.VerticalAlignment.Center,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
		},

		AspectRatio = 4,
	},
	
	ArmorDisplay = {
		Type = "TextLabel",
		FieldName = "ArmorDisplay",
		LayoutOrder = 0,

		SizeX = UDim.new(1, 0),
		SizeY = UDim.new(0.5, 0),

		AnchorPoint = "Center",
		
		FontFace = "DamageNumberFont",
		
		TextColor = "Armor",
		TextSize = 22,
		
		Visible = false,
	},
	
	HealthDisplay = {
		Type = "TextLabel",
		FieldName = "HealthDisplay",
		LayoutOrder = 1,
		
		SizeX = UDim.new(1, 0),
		SizeY = UDim.new(0.5, 0),
		
		AnchorPoint = "Center",

		FontFace = "DamageNumberFont",
		
		TextColor = "Health",
		TextSize = 22,
		
		Visible = false,
	},
}

return UiResource_DamageIndicator
