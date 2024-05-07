local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local NetworkedProperties = Framework.GetShared("DT_NetworkedProperties")
local DECLARE = NetworkedProperties.DeclareProperty
local FLAGS = NetworkedProperties.Flags

local ItemValueDefaultTypes = {
	Clip = DECLARE("Integer", {Flags = {FLAGS.UNSIGNED}}),
	ReserveAmmo = DECLARE("Integer", {Flags = {FLAGS.UNSIGNED}}),
}

return ItemValueDefaultTypes
