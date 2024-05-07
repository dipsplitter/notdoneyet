local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataTypes = require(ReplicatedStorage.Network.DataTypes.DataTypesList)

local VisualEffectProperties = {
	PropertyIndices = {}
}

VisualEffectProperties.Properties = {
	[1] = {
		"CFrame",
		DataTypes.CFrame(),
	},
	
	[2] = {
		"Radius",
		DataTypes.Float(),
	},
	
	[3] = {
		"CharacterId",
		DataTypes.UnsignedShort(),
	},
}

-- Add each property to reverse lookup
for index, propInfo in VisualEffectProperties.Properties do
	local propertyName = propInfo[1]
	
	VisualEffectProperties.PropertyIndices[propertyName] = index
end

return VisualEffectProperties
