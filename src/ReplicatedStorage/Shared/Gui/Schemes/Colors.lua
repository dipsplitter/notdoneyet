local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local ColorUtilities = Framework.GetShared("ColorUtilities")

local Colors = {
	White = Color3.fromRGB(255, 255, 255),
	Black = Color3.fromRGB(0, 0, 0),
	Red = Color3.fromRGB(255, 0, 0),
	LightRed = Color3.fromRGB(255, 137, 137),
	LightGreen = Color3.fromRGB(144, 238, 144),
	DarkRed = Color3.fromRGB(159, 0, 0),
	BlueGreen = Color3.fromRGB(8, 143, 143),
	Orange = Color3.fromRGB(255, 165, 0),
	
	LightIvory = Color3.fromRGB(255, 248, 201),
	IvoryWhite = Color3.fromRGB(242, 239, 222),
	WarmIvory = Color3.fromRGB(239, 224, 205),
	Eggshell = Color3.fromRGB(240, 234, 214),
	Pearl = Color3.fromRGB(216, 216, 216),
	LightGray = Color3.fromRGB(194, 194, 194),
	Smoke = Color3.fromRGB(132, 136, 132),
	MediumGray = Color3.fromRGB(106, 106, 106),
	Charcoal = Color3.fromRGB(69, 69, 69),
	DarkCharcoal = Color3.fromRGB(50, 50, 50),
}

return Colors
