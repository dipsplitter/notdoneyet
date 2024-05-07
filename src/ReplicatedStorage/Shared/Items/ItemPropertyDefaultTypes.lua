local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local NetworkedProperties = Framework.GetShared("DT_NetworkedProperties")
local DECLARE = NetworkedProperties.DeclareProperty
local FLAGS = NetworkedProperties.Flags

-- THEY'RE ALL FLOATS ?!??!!?!
local ItemPropertyDefaultTypes = {
	
	EquipSpeed = DECLARE("Float"),
	UnequipSpeed = DECLARE("Float"),

	CooldownTime = DECLARE("Float"),
	MaxHoldTime = DECLARE("Float"),

	MaxRange = DECLARE("Integer", {Flags = {FLAGS.UNSIGNED}}),
	
	-- In radians, the maximum spread value is 1 radian (why would you need any higher???)
	MinSpread = DECLARE("Float", {Flags = {FLAGS.NORMAL}}),
	MaxSpread = DECLARE("Float", {Flags = {FLAGS.NORMAL}}),
	--Spread = DECLARE("Float", -1, FLAGS.NORMAL),
	
	ConsecutiveSpreadIncrease = DECLARE("Float", {Flags = {FLAGS.NORMAL}}),
	
	SpreadRecovery = DECLARE("Float"),
	
	AttackTimestamp = DECLARE("Float"),
	
	-- Reload
	AutoReloadDelay = DECLARE("Float"),
	First = DECLARE("Float"),
	Consecutive = DECLARE("Float"),
}

return ItemPropertyDefaultTypes
