--!native
local RunService = game:GetService("RunService")
local IsClient = RunService:IsClient()
local IsServer = RunService:IsServer()

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local ReadBuffer = Framework.GetShared("ReadBuffer")

local DataTypes = require(ReplicatedStorage.Network.DataTypes.DataTypesList)
local ArgumentSignatures = require(script.ArgumentSignatures)
local GenericParse = require(script.GenericParse)
local ArgumentTableStructures = require(script.ArgumentTableStructures)
local SignatureAliases = require(script.SignatureAliases)

local packetSignatures = {}
for i, packetInfo in ArgumentTableStructures do
	local signature = ArgumentSignatures.GenerateSignatureFromStructure(packetInfo.Structure)
	if not signature then
		continue
	end
	
	packetSignatures[signature] = i
end

local function MainInbound(stream, cursor)
	local usedCursor = cursor
	
	local readBuffer = ReadBuffer.new(stream, cursor)
	local itemHandle = readBuffer:readu16()
	local actionId, eventId, argsType = readBuffer:readu8(), readBuffer:readu8(), readBuffer:readu8()

	local module = ArgumentTableStructures[argsType].Module
	local readFunction = if module then module.Deserialize else GenericParse.Deserialize

	local readArgs, addCursor = readFunction(stream, readBuffer.Cursor, ArgumentTableStructures[argsType].Structure)
	readBuffer.Cursor += addCursor
	
	-- We're not going to find the action manager and get the action names, etc., here
	local data = {
		EntityHandle = itemHandle,
		ActionName = actionId,
		EventName = eventId,
		Args = readArgs
	}
	
	return {
		AdvanceCursor = readBuffer:GetBytesRead(),
		Status = true,
		Data = data,
	}
end

local function MainOutbound(data, queue)
	-- Write our metadata
	local actionManager = data.ActionManager
	local actionName = data.ActionName
	local eventName = data.EventName
	
	local itemHandle = actionManager.EntityHandle
	local actionId = actionManager.ActionIdentifierMap:Serialize(actionName)
	local eventId = actionManager:GetAction(actionName).EventIdentifierMap:Serialize(eventName)
	
	queue:writeu16(itemHandle)
	queue:writeu8(actionId)
	queue:writeu8(eventId)
	
	local args = data.Args
	
	-- Either the number or the signature string
	local signature
	if args then
		signature = SignatureAliases[args.SIGNATURE or data.SIGNATURE]
	end
	
	signature = signature or ArgumentSignatures.GenerateSignature(args)
	
	local argsType = if type(signature) == "string" then packetSignatures[signature] else signature

	if not argsType then
		return {Status = false}
	end
	
	queue:writeu8(argsType)
	
	local module = ArgumentTableStructures[argsType].Module
	local serializeFunction = if module then module.Serialize else GenericParse.Serialize
	serializeFunction(args, queue, ArgumentTableStructures[argsType].Structure)
	
	return {Status = true}
end

local function PreSerializeArgumentTable(args)
	-- Either within the entire table or the args table
	local alias = args.SIGNATURE or (if args.Args then args.Args.SIGNATURE else nil)

	if not alias then
		return {Status = true}
	end
	
	local argumentTableId = SignatureAliases[alias]
	
	local module = ArgumentTableStructures[argumentTableId].Module
	if not module.PreSerialize then
		return {Status = false}
	end
	
	return {
		Status = true, 
		Data = module.PreSerialize(args)
	}
end

return {
	Inbound = {
		MainInbound,
	},

	Outbound = {
		PreSerializeArgumentTable,
		MainOutbound,
	}
}
