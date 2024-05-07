local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local NetworkedProperties = Framework.GetShared("DT_NetworkedProperties")
local DECLARE = NetworkedProperties.DeclareProperty
local FLAGS = NetworkedProperties.Flags

local DTS_Settings = {
	Name = "Settings",
	Cache = {
		Network = {
			ViewInterpolationDelay = DECLARE("Float"),
			MinimumUpdateRate = DECLARE("Integer", {Bits = 6, Flags = {FLAGS.UNSIGNED}}),
			CommandRate = DECLARE("Integer", {Bits = 6, Flags = {FLAGS.UNSIGNED}}),
		},
	},
	
	DefaultValues = {
		Network = {
			ViewInterpolationDelay = 0.06,
			MinimumUpdateRate = 30,
			CommandRate = 30,
			LatestAppliedCommandId = 0
		}
	}
}

return DTS_Settings
