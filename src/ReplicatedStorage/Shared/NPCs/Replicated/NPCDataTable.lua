local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local NetworkedProperties = Framework.GetShared("DT_NetworkedProperties")
local DECLARE = NetworkedProperties.DeclareProperty
local FLAGS = NetworkedProperties.Flags

local DT_FIELDS = {
	Velocity = DECLARE("Vector"),
	Position = DECLARE("Vector"),
}

local NPCDataTable = {}
NPCDataTable.__index = NPCDataTable

return NPCDataTable
