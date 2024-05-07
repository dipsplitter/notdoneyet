local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local EnumService = Framework.GetShared("EnumService")
local Classes = EnumService.GetEnum("Classes")

--[[
	ChangeClass:
	
	Class ID: u8
		The enum of the class
]]

local function MainInbound(stream, cursor)
	local classId = buffer.readu8(stream, cursor)
	
	return {
		AdvanceCursor = 1,
		Status = true,
		Data = Classes.FromValue(classId)
	}
end

local function MainOutbound(className, queue)
	local classId = Classes[className]
	
	queue:writeu8(classId)

	return {Status = true}
end

return {
	Inbound = {
		MainInbound
	},
	
	Outbound = {
		MainOutbound
	}
}
