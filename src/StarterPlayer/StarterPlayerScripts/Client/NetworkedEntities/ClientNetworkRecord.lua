local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Framework = require(ReplicatedStorage.Framework)
local DataTableService = Framework.GetShared("DataTableService")
local SettingsStructures = Framework.GetShared("DTS_Settings")

local localPlayer = Players.LocalPlayer

local record = {
	LatestAppliedCommandId = 0,
	
	ClientSettings = DataTableService.Reference({
		Name = `NS{localPlayer.UserId}`,
		Structure = `Settings.Network`,
		Data = SettingsStructures.DefaultValues.Network,
	}),
	
}


return record
