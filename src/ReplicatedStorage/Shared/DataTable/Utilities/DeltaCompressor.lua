--!native
--!optimize 2

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local BufferUtilities = Framework.GetShared("BufferUtilities")
local TableUtilities = Framework.GetShared("TableUtilities")
local ValueRetriever = Framework.GetShared("ValueRetriever")
local WriteBitstream = Framework.GetShared("WriteBitstream")
local ReadBitstream = Framework.GetShared("ReadBitstream")
local NetworkedProperties = Framework.GetShared("DT_NetworkedProperties")
local DataTypes = NetworkedProperties.DataTypes

local BitBuffer = Framework.RequireNetworkModule("BitBuffer")

local NAN = 0/0
local STRING = string.rep(string.char(255), 16)
local INF_VECTOR = Vector3.one * math.huge
local BLACKLISTED_KEYS = {"Type", "Bits", "Flags", "DECLARED_PROPERTY"}

local function GetSubstituteType(value)
	if type(value) == "function" then
		value = value()
	end

	if type(value) == "string" then
		return STRING
	elseif type(value) == "boolean" then
		return not value
	elseif type(value) == "vector" then
		return INF_VECTOR
	end

	return NAN
end

local DeltaCompressor = {}
DeltaCompressor.__index = DeltaCompressor

function DeltaCompressor.new(structure, initialData)
	local self = {
		KeyToType = {},
		Keys = {},
		KeyIndices = {},
		Types = {},
		
		QueuedChanges = {},
		
		KeyRateLimitLog = {},

		Previous = nil,
		Current = nil,
	}
	setmetatable(self, DeltaCompressor)
	
	self:RegisterTypes(structure)
	
	if initialData and type(initialData) == "table" then
		self:UpdateCurrent(initialData)
	end
	
	return self
end

function DeltaCompressor:UpdateCurrent(data)
	local flattened = TableUtilities.Flatten(data)
	
	-- Clear unreplicated keys
	for keyName in flattened do
		if not self.KeyToType[keyName] then
			flattened[keyName] = nil
		end
	end

	-- Do we need to overwrite previous data? Do we have current data but no previous data?
	if self.Previous or (self.Current and not self.Previous) then
		local current = self.Current
		self.Previous = current
	end

	self.Current = flattened
end

function DeltaCompressor:UpdatePrevious(data)
	local flattened = TableUtilities.Flatten(data)

	self.Previous = flattened
end

--[[
	A potentially nested dictionary formatted like { Position = "Vector", Count = "Short" }
	The type strings should be spelled exactly as in DataTypes
	
	Ideally the dictionary should not be nested. Recursion is bad !
]]
function DeltaCompressor:RegisterTypes(typesTable)
	-- Flatten into single-level dictionary
	self.KeyToType = TableUtilities.Flatten(typesTable, "", BLACKLISTED_KEYS)

	for key, dataType in self.KeyToType do
		if not dataType.DECLARED_PROPERTY then
			continue
		end
		
		dataType = table.clone(dataType)
		self.KeyToType[key] = dataType
		
		-- Add to rate limit log 
		if dataType.MaximumRate then
			self.KeyRateLimitLog[key] = {
				LastSendTime = 0,
				MaximumRate = dataType.MaximumRate
			}
		end
		
		table.insert(self.Keys, key)
	end
 
	table.sort(self.Keys, function(a, b)
		return #a < #b
	end)

	for index, key in self.Keys do
		-- Add to reverse map
		self.KeyIndices[key] = index
		table.insert(self.Types, self.KeyToType[key])
	end
end

-- No delta compression used, so no delta bits present
function DeltaCompressor:PackFull()
	local values = table.create(#self.Keys)
	local writeBitBuffer = BitBuffer.new()
	
	-- First bit = true means it's a full snapshot
	writeBitBuffer:WriteBool(true)
	
	for i, typeData in self.Types do
		local keyName = self.Keys[i]
		local dataTypeFunctions = DataTypes[typeData.Type]
		
		local currentValue = self.Current[keyName] or dataTypeFunctions.DefaultValue(typeData)
	
		dataTypeFunctions.Write(writeBitBuffer, currentValue, typeData)
	end
	
	table.clear(self.QueuedChanges)
	
	return writeBitBuffer
end

function DeltaCompressor:FlushChanges(deltas)
	deltas = deltas or self.QueuedChanges
	-- No changes!
	if not next(deltas) then
		return
	end

	local writeBitBuffer = BitBuffer.new()
	
	-- First bit = false means delta
	writeBitBuffer:WriteBool(false)
	
	-- Write delta bits first
	for i, typeInfo in self.Types do
		local queued = deltas[i]
		
		-- Limit the rate if applicable
		local rateLimitLog = self.KeyRateLimitLog[self.Keys[i]]
		if rateLimitLog then
			
			if os.clock() - rateLimitLog.LastSendTime <= rateLimitLog.MaximumRate then
				continue
			end
			
			rateLimitLog.LastSendTime = os.clock()
			
		end
		
		local deltaBits
		if queued then
			deltaBits = queued[2]
		end
		
		if deltaBits then
			for i, componentBit in deltaBits do
				writeBitBuffer:WriteBool(componentBit)
			end
		else
			writeBitBuffer:WriteUInt(typeInfo.Components, if queued then 1 else 0)
		end
	end
	
	-- Then write changed properties
	for i, typeInfo in self.Types do
		local queued = deltas[i]

		if not queued then
			continue
		end
		
		local newValue = queued[1]
		local deltaBits = queued[2]

		local dataTypeFunctions = DataTypes[typeInfo.Type]

		local writeFunction = dataTypeFunctions.WriteDelta or dataTypeFunctions.Write
		writeFunction(writeBitBuffer, newValue, typeInfo, deltaBits)
	end
	
	table.clear(deltas)
	
	return writeBitBuffer
end

function DeltaCompressor:PackDeltas(comparison)
	local deltaTable = self:QueueChanges(comparison, {})
	
	return self:FlushChanges(deltaTable)
end

function DeltaCompressor:QueueChanges(comparison, deltaTable)
	deltaTable = deltaTable or self.QueuedChanges
	comparison = comparison or self.Previous
	
	for key, value in self.Current do
		-- Retrieve current and previous values for this key
		local currentValue = ValueRetriever.GetValue(value)
		local previousValue = GetSubstituteType(currentValue)
		local foundIndex = self.KeyIndices[key]
		
		if comparison then
			previousValue = ValueRetriever.GetValue(comparison[key])
		end

		local valueType = self.Types[foundIndex]
		
		local dataTypeFunctions = DataTypes[valueType.Type]
		
		local hasValueChanged, componentDeltaBits = dataTypeFunctions.Changed(previousValue or dataTypeFunctions.DefaultValue(valueType), value)

		if hasValueChanged then
			deltaTable[foundIndex] = {currentValue, componentDeltaBits}
		end
	end
	
	return deltaTable
end

function DeltaCompressor:QueueChangesFromState(otherState)
	for key, value in self.Current do
		local currentValue = ValueRetriever.GetValue(value)
		local previousValue = GetSubstituteType(currentValue)
		local foundIndex = self.KeyIndices[key]
	end
end

function DeltaCompressor:ReadBuffer(readBitBuffer)
	local values = self:Unpack(readBitBuffer)

	return values
end

function DeltaCompressor:Unpack(bitBuffer)
	if typeof(bitBuffer) == "buffer" then
		bitBuffer = BitBuffer.FromBuffer(bitBuffer)
	elseif typeof(bitBuffer) == "string" then
		bitBuffer = BitBuffer.FromString(bitBuffer)
	end
	
	local values = table.create(#self.Types, NAN)
	
	local isFullSnapshot = bitBuffer:ReadBool()
	
	-- Full snapshots: there's no delta bits, so just begin reading the values
	if isFullSnapshot then
		for i, typeInfo in self.Types do
			local dataTypeFunctions = DataTypes[typeInfo.Type]
			
			local value = dataTypeFunctions.Read(bitBuffer, typeInfo)

			values[i] = value
		end
		
		return values
	end
	
	local deltaBits = {}
	
	-- Read all delta bits
	for i, typeInfo in self.Types do
		deltaBits[i] = bitBuffer:ReadUInt(typeInfo.Components)
	end
	
	for i, typeInfo in self.Types do
		local delta = deltaBits[i]
		
		-- Skip unchanged properties
		if delta == 0 then
			continue
		end
		
		local dataTypeFunctions = DataTypes[typeInfo.Type]
		
		local readFunction = dataTypeFunctions.ReadDelta or dataTypeFunctions.Read
		values[i] = readFunction(bitBuffer, typeInfo, delta)
	end
	
	return values
end

function DeltaCompressor:ReconcileChanges(newValues, reconcileAgainst)
	reconcileAgainst = reconcileAgainst or self.Current
	
	local changesTable = {}
	
	for i, key in self.Keys do
		local value = newValues[i]
		local previous = reconcileAgainst[key]

		local typeData = self.Types[i]

		if typeData.Reconcile then
			value = typeData.Reconcile(previous, value)
		else
			value = if value ~= value then previous else value
		end

		changesTable[key] = value
	end
	
	return changesTable
end

function DeltaCompressor:ReconcileToDeltas(newValues, reconcileAgainst)
	reconcileAgainst = reconcileAgainst or self.Current

	local changesTable = {}
	
	for i, value in newValues do
		local keyName = self.Keys[i]
		local previous = reconcileAgainst[keyName]
		
		local typeData = self.Types[i]

		if typeData.Reconcile then
			value = typeData.Reconcile(previous, value)
		else
			value = if value ~= value then previous else value
		end

		changesTable[keyName] = value
	end
	
	return changesTable
end

return DeltaCompressor
