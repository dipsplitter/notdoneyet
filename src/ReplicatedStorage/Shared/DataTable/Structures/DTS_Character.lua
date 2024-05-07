local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local NetworkedProperties = Framework.GetShared("DT_NetworkedProperties")
local DECLARE = NetworkedProperties.DeclareProperty
local FLAGS = NetworkedProperties.Flags

local BASE_NETWORK_TABLE = {
	Position = DECLARE("Vector"),
	Velocity = DECLARE("Vector"),
	Pitch = DECLARE("Integer", {Bits = 9}), -- -90 to 90 degrees
	Yaw = DECLARE("Integer", {Bits = 9}), -- -180 to 180 degrees
}

local DTS_Character = {
	Name = "Character",
	Cache = {}
}

return DTS_Character
