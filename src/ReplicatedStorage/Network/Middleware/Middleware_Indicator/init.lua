local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local ReadBuffer = Framework.GetShared("ReadBuffer")
local BitFlagUtilities = Framework.GetShared("BitFlagUtilities")
local EnumService = Framework.GetShared("EnumService")
local IndicatorTypes = EnumService.GetEnum("Enum_IndicatorTypes")

local CharacterRegistry = Framework.GetShared("CharacterRegistry")

local modules = {
	[IndicatorTypes.Damage] = require(script.IndicatorType_Damage),
}

--[[
	BUFFER:
	[2B: character id][1B: indicator type][1 or 2B: flags][...]
]] 

local function MainInbound(stream, cursor)
	local readBuffer = ReadBuffer.new(stream, cursor)
	
	local data = {}
	
	-- Get the character model
	local characterId = readBuffer:readu16()
	
	local character = CharacterRegistry.GetModelFromId(characterId)
	if not character then
		return {Status = false}
	end
	
	data.Instance = character 
	
	-- Read indicator type
	local indicatorType = readBuffer:readu8()
	
	local module = modules[indicatorType]
	
	local indicatorTypeName = IndicatorTypes.FromValue(indicatorType)
	data.Type = indicatorTypeName
	
	-- Read corresponding flags
	local flagsSize = module.FlagBits
	local flags = 0
	if flagsSize == 16 then
		flags = readBuffer:readu16()
	elseif flagsSize == 8 then
		flags = readBuffer:readu8()
	end
	
	data.Flags = BitFlagUtilities.Deserialize(flags, module.Flags, data)

	readBuffer.Cursor += module.Deserialize(stream, readBuffer.Cursor, data)

	return {
		AdvanceCursor = readBuffer:GetBytesRead(),
		Status = true,
		Data = data,
	}
end

--[[
	IndicatorType: The enum
]]
local function MainOutbound(data, queue)
	local indicatorType = data.IndicatorType
	modules[indicatorType].Serialize(data, queue)
	
	return {Status = true}
end

return {
	Inbound = {
		MainInbound,
	},

	Outbound = {
		MainOutbound,
	}
}
