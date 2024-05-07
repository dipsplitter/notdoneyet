local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataTypes = require(ReplicatedStorage.Network.DataTypes.DataTypesList)

local ArgumentTableStructures = {
	-- Empty structure
	[0] = {
		Structure = {},
	},
	
	-- Hold to fire projectile
	[1] = {
		Structure = {
			{"Direction", DataTypes.Vector3()},
			{"TimeHeld", DataTypes.Float()},
			{"Origin", DataTypes.CFrame()}
		},
	},

	-- Fire projectile
	[2] = {
		Structure = {
			{"Direction", DataTypes.Vector3()},
			{"Origin", DataTypes.CFrame()},
		},
	},

	-- Shotguns
	[3] = {
		Module = require(script.Parent.AT_MultiCharacterRaycastResult)
	},

	-- Raycast result without hitting character
	[4] = {
		Structure = {
			{"Position", DataTypes.Vector3()},
			{"Distance", DataTypes.Float()}
		},
	},
	
	-- Shapecast
	[5] = {
		Structure = {
			{"Count", DataTypes.UnsignedByte()},
		},
	},
}

return ArgumentTableStructures
