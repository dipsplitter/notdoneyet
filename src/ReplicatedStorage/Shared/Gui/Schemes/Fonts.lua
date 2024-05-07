local assetIds = {
	Gotham = "rbxasset://fonts/families/GothamSSm.json",
	Arial = "rbxasset://fonts/families/Arial.json",
}

local Fonts = {
	["GothamBoldStroked"] = {
		FontFace = Font.new(assetIds.Gotham, Enum.FontWeight.Bold),
		Stroke = {
			Thickness = 3,
		}
	},
	
	["GothamBoldThinStroked"] = {
		FontFace = Font.new(assetIds.Gotham, Enum.FontWeight.Bold),
		Stroke = {
			Thickness = 2,
		}
	},
	
	["GothamBold"] = {
		FontFace = Font.new(assetIds.Gotham, Enum.FontWeight.Bold),
	},
	
	["GothamStroked"] = {
		FontFace = Font.new(assetIds.Gotham),
		Stroke = {
			Thickness = 2,
		}
	},
	
	["Gotham"] = {
		FontFace = Font.new(assetIds.Gotham),
	},
	
	["Arial"] = {
		FontFace = Font.new(assetIds.Arial),
	},
	
	["ArialBold"] = {
		FontFace = Font.new(assetIds.Arial, Enum.FontWeight.Bold),
	},
	
	["ArialBoldStroked"] = {
		FontFace = Font.new(assetIds.Arial, Enum.FontWeight.Bold),
		Stroke = {
			Thickness = 2,
		},
	},
}

return Fonts

