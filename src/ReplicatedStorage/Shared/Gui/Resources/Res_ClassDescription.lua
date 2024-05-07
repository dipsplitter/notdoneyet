local UiResource_ClassDescription = {
	Name = "ClassDescription",
	ScreenGui = "ClassSelectionMenu",
	
	Config = {
		TooltipOffset = Vector2.new(0, 25),
		
		RolesText = {
			Damage = "Higher damage outputs and offensive capabilities",
			Support = "Heal, buff, and provide utility to teammates, preventing deaths and assisting kills",
			
			Combo = "APM",
			Debuff = "Apply negative status effects that decrease enemies' capabilities",
			Heal = "Bring wounded teammates back to the fight",
			Buff = "Apply positive status effects to teammates that improve survivability, damage output, and other areas",
			Pick = "Secure kills on major enemy targets",
			Flank = "Create disruptions by attacking enemies from flank positions",
			CrowdControl = "Ward off large groups of enemies with area of effect attacks",
		},
		
		-- Probably should put this somewhere else
		Survivalist = {
			Overview = "A generalist with a penchant for arson. Burn enemies to ashes or watch them run for their lives, trying to remember what comes after \"Stop\" and \"Drop.\"",
			Tips = {
				"Switch between weapons and abilities to inflict immense single-target burst damage",
			},
			Roles = {"Damage",},
			Playstyles = {"Combo", "Debuff"},
		},
		
		Fatman = {
			Overview = "A well-ROUNDed, self-sufficient CQC specialist with a large health pool and high burst damage capabilities, perfect for wiping the floor with anyone who wanders too close",
			Tips = {
				"Tank enemy fire with your high base health and variety of self-healing utilities",
				"Position yourself wisely and retreat before it's too late, as your relatively slow movement speed makes you an easy target",
				"Focus on close-quarters combat; your damage output falls off significantly at longer ranges",
			},
			Roles = {"Damage"},
			Playstyles = {"Combo"},
		},
		
		Medic = {
			Overview = "The quintessential support class. Heal and buff wounded teammates to build up your game-changing Supercharge ability.",
			Tips = {
				"Healing allies, killing enemies, assisting in kills, and other actions that help your team will fill your Supercharge",
				"You are a highly valuable pick and don't have many effective self-defense options, so position yourself such that your team can easily protect you",
				"Staying alive to use your Supercharge should be your top priority; bail on teammates who are beyond saving",
			},
			Roles = {"Support"},
			Playstyles = {"Heal", "Buff"},
		},
		
		Warrior = {
			Overview = "An offensive, melee-oriented class. Hack 'n' slash, slice 'n' dice, rip 'n' tear, cut 'n' thrust, cleave 'n' conquer.",
			Tips = {
				"Dying is bad"
			},
			Roles = {"Damage"},
			Playstyles = {"Flank", "Pick"},
		},
		
		Soldier = {
			Overview = "War man",
			Tips = {
				"Dying is bad"
			},
			Roles = {"Damage"},
			Playstyles = {"CrowdControl", "Flank", "Combo"},
		},
	},
	
	Fonts = {
		ClassName = "GothamBoldStroked",
		ClassInformation = "GothamStroked",
		ClassTips = "Gotham",
		Tooltips = "GothamBold",
	},
	
	Main = {
		BackgroundTransparency = 1,
	},
	
	ClassNameLabel = {
		Type = "TextLabel",
		FieldName = "ClassNameLabel",
		
		LayoutOrder = 1,

		SizeX = UDim.new(1, 0),
		SizeY = UDim.new(0.15, 0),
		
		BackgroundTransparency = 1,
		
		FontFace = "ClassName",
		TextColor = "White",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextSize = 48,
	},
	
	ClassRoleIcons = {
		Type = "Frame",
		FieldName = "ClassRoleIcons",
		
		LayoutOrder = 2,
		
		BackgroundTransparency = 1,
		
		SizeX = UDim.new(1, 0),
		SizeY = UDim.new(0.15, 0),
		
		ListLayout = {
			Padding = UDim.new(0.025, 0),
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			
			ItemLineAlignment = Enum.ItemLineAlignment.Center,
		},
	},
	
	ClassOverviewLabel = {
		Type = "TextLabel",
		FieldName = "ClassOverviewLabel",
		
		LayoutOrder = 3,
		
		BackgroundTransparency = 1,

		SizeX = UDim.new(1, 0),
		SizeY = UDim.new(0.1, 0),
		
		AutomaticSize = Enum.AutomaticSize.Y,
		
		FontFace = "ClassInformation",
		TextColor = "White",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextSize = 20,
		TextWrapped = true,
	},
	
	ClassTips = {
		Type = "TextLabel",
		FieldName = "ClassTips",
		
		LayoutOrder = 4,
		
		BackgroundTransparency = 0,
		BackgroundColor = "MediumGray",
		
		CornerRadius = UDim.new(0.1, 0),
		Padding = {
			Vertical = UDim.new(0, 14),
			Horizontal = UDim.new(0, 7),
		},
		
		SizeX = UDim.new(1, 0),
		SizeY = UDim.new(0.1, 0),
		
		AutomaticSize = Enum.AutomaticSize.Y,
		
		FontFace = "ClassTips",
		TextColor = "White",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		
		TextSize = 16,
	},
	
	ClassRoleIcon = {
		Type = "Frame",
		FieldName = "ClassRoleIcon",
		
		Template = true,
		
		AspectRatio = 1,
		CornerRadius = UDim.new(0.15, 0),
		BackgroundColor = "LightGray",
		
		Stroke = {
			Thickness = 2,
			Color = "DarkCharcoal",
		},
		
		SizeX = UDim.new(1, 0),
		SizeY = UDim.new(1, 0),
		
		FlexBehavior = {
			FlexMode = Enum.UIFlexMode.Shrink
		},
	},
	
	RoleImage = {
		Type = "ImageLabel",
		FieldName = "RoleImage",
		
		Parent = "ClassRoleIcon",
		
		BackgroundTransparency = 1,
		
		PosX = UDim.new(0.5, 0),
		PosY = UDim.new(0.5, 0),
		AnchorPoint = "Center",
		
		SizeX = UDim.new(0.8, 0),
		SizeY = UDim.new(0.8, 0),
	},
	
	ClassPlaystyleIcon = {
		Type = "Frame",
		FieldName = "ClassPlaystyleIcon",

		Template = true,

		AspectRatio = 1,
		CornerRadius = UDim.new(0.15, 0),
		BackgroundColor = "IvoryWhite",

		SizeX = UDim.new(0.75, 0),
		SizeY = UDim.new(0.75, 0),

		FlexBehavior = {
			FlexMode = Enum.UIFlexMode.Shrink
		},
	},
	
	PlaystyleImage = {
		Type = "ImageLabel",
		FieldName = "PlaystyleImage",

		Parent = "ClassPlaystyleIcon",
		
		BackgroundTransparency = 1,

		PosX = UDim.new(0.5, 0),
		PosY = UDim.new(0.5, 0),
		AnchorPoint = "Center",

		SizeX = UDim.new(0.8, 0),
		SizeY = UDim.new(0.8, 0),
	},
	
	Tooltip = {
		Type = "Frame",
		FieldName = "Tooltip",
		
		Template = true,
	
		CornerRadius = UDim.new(0.1, 0),
		
		BackgroundColor = "Charcoal",
		
		SizeX = UDim.new(0, 50),
		SizeY = UDim.new(0, 30),
		
		MaxSize = Vector2.new(300, math.huge),
		
		AutomaticSize = Enum.AutomaticSize.XY,
		
		Padding = {
			Vertical = UDim.new(0, 15),
			Horizontal = UDim.new(0, 15),
		},
		
		ListLayout = {
			Padding = UDim.new(0, 5),
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			VerticalAlignment = Enum.VerticalAlignment.Top,
		},
	},
	
	TooltipHeader = {
		Type = "TextLabel",
		FieldName = "TooltipHeader",
		
		Parent = "Tooltip",
		
		BackgroundTransparency = 1,
		
		SizeX = UDim.new(0, 0),
		SizeY = UDim.new(0, 30),
		
		AutomaticSize = Enum.AutomaticSize.X,
		
		FontFace = "Tooltips",
		TextColor = "White",
		TextSize = 24,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
	},
	
	TooltipDescription = {
		Type = "TextLabel",
		FieldName = "TooltipDescription",
		
		Parent = "Tooltip",
		
		BackgroundTransparency = 1,
		
		SizeX = UDim.new(1, 0),
		SizeY = UDim.new(0, 30),
		
		AutomaticSize = Enum.AutomaticSize.XY,
		
		FontFace = "ClassTips",
		TextColor = "White",
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true
	}
}

return UiResource_ClassDescription
