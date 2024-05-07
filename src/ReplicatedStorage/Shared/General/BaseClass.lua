local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local Signal = Framework.GetShared("Signal")
local Cleaner = Framework.GetShared("Cleaner")

local BaseClass = {}
BaseClass.__index = BaseClass
BaseClass.ClassName = "BaseClass"

function BaseClass.new(tab)
	local self = setmetatable(tab or {}, BaseClass)
	
	self.Tags = {}
	self.Signals = {
		Destroying = Signal.new()
	}
	self.Cleaner = Cleaner.new()
	self.AutoCleanup = false
	
	return self
end

function BaseClass:IsA(className)
	local mt = self
	while mt do
		mt = getmetatable(mt)
		
		if not mt then
			return false
		end
		
		
		if mt.ClassName == className
			or mt.ClassName:sub(3) == className then
			return true
		end
	end
	
	return false
end

function BaseClass:AddExternalReference(tab, replaceWith)
	if not self.References then
		self.References = {}
	end
	
	self.References[tab] = if replaceWith == nil then "NULL" else replaceWith
end

-- Injected objects will not be destroyed when this object is destroyed; their keys will only be set to nil
function BaseClass:InjectObject(keyName, object)
	self[keyName] = object
	
	if not self.Injections then
		self.Injections = {}
	end
	
	if object then
		self.Injections[keyName] = true
	end
end

function BaseClass:GetPrivateMember(publicKeyName)
	if type(publicKeyName) ~= "string" then
		return false
	end
	
	local firstLetter = string.sub(publicKeyName, 1, 1)
	
	if firstLetter == "_" then
		return false
	end
	
	return rawget(self, `_{string.lower(firstLetter)}{string.sub(publicKeyName, 2, -1)}`)
end

function BaseClass:GetPrivateMemberKeyName(publicKeyName)
	if type(publicKeyName) ~= "string" then
		return false
	end

	local firstLetter = string.sub(publicKeyName, 1, 1)

	if firstLetter == "_" then
		return false
	end

	return `_{string.lower(firstLetter)}{string.sub(publicKeyName, 2, -1)}`
end

function BaseClass:AddTags(tagDict)
	if not next(self.Tags) then
		self:AddSignals("TagAdded", "TagRemoved")
	end
	
	for k, v in pairs(tagDict or {}) do
		self.Tags[k] = v
		self.Signals.TagAdded:Fire(k, v)
	end
end

function BaseClass:GetTag(tagName)
	return self.Tags[tagName]
end

function BaseClass:RemoveTags(...)
	local args = {...}
	for i, tag in ipairs(args) do
		self.Signals.TagRemoved:Fire(tag)
		self.Tags[tag] = nil
	end
end

function BaseClass:IsClass(className)
	return className == self.ClassName
end

function BaseClass:Is(value)
	return type(value) == "table" and getmetatable(value) and value.ClassName == self.ClassName
end

function BaseClass:AddConnection(connection, name)
	if not self.Connections then
		self.Connections = {}
		self.ConnectionCount = 1
	end
	
	if not name then
		name = tostring(self.ConnectionCount)
		self.ConnectionCount += 1
	end
	
	if self.Connections[name] then
		self:CleanupConnection(name)
	end
	
	self.Connections[name] = connection

	return name
end

function BaseClass:GetConnection(connectionName)
	if not self.Connections then
		return
	end
	
	return self.Connections[connectionName]
end

function BaseClass:AddConnections(connectionsDict)
	for name, value in pairs(connectionsDict) do
		self:AddConnection(value, name)
	end
end

function BaseClass:CleanupAllConnections()
	if not self.Connections then
		return
	end
	
	for name, c in pairs(self.Connections) do
		self.Connections[name]:Disconnect()
		self.Connections[name] = nil
	end
end

function BaseClass:CleanupConnection(...)
	if not self.Connections then
		return
	end
	
	local args = {...}
	for i, name in ipairs(args) do
		if self.Connections[name] then
			self.Connections[name]:Disconnect()
			self.Connections[name] = nil
		end
	end
end
BaseClass.CleanupConnections = BaseClass.CleanupConnection

function BaseClass:AddSignals(...)
	local args = {...}
	if not self.Signals then
		self.Signals = {}
	end
	for i, name in ipairs(args) do
		if self.Signals[name] then
			self.Signals[name]:Destroy()
		end
		
		self.Signals[name] = Signal.new()
	end
end

function BaseClass:GetSignal(name)
	return self.Signals[name]
end

function BaseClass:FireSignal(signalName, ...)
	self:GetSignal(signalName):Fire(...)
end

function BaseClass:ConnectTo(signalName, fn)
	return self:GetSignal(signalName):Connect(fn)
end

function BaseClass:BaseDestroy()
	if self.Signals and self.Signals.Destroying then
		self.Signals.Destroying:Fire()
	end
	
	if self.Connections then

		for key, value in pairs(self.Connections) do
			self.Connections[key]:Disconnect()
			self.Connections[key] = nil
		end

	end
	
	-- Remove dependency injections
	if self.Injections then
		
		for injectionKey in pairs(self.Injections) do
			if self[injectionKey] then
				self[injectionKey] = nil
			end
		end
			
	end
	
	if self.References then
		
		for tableContainingReference, replaceWith in pairs(self.References) do
			replaceWith = if replaceWith == "NULL" then nil else replaceWith
			
			if tableContainingReference[self] then
				tableContainingReference[self] = replaceWith
				continue
			end
			
			for key, value in pairs(tableContainingReference) do
				if value == self then
					tableContainingReference[key] = replaceWith
				end
			end
			
		end
	end
	
	if self.Cleaner then
		self.Cleaner:Destroy()
	end

	if self.Signals then
		for key, value in pairs(self.Signals) do
			self.Signals[key]:Destroy()
			self.Signals[key] = nil
		end
	end
	
	if self.AutoCleanup then
		-- Auto delete instances because I'm lazy
		for key, value in self do
			if type(value) ~= "table" then
				continue
			end
			
			if getmetatable(value) and value.Destroy and type(value.Destroy) == "function" then
				value:Destroy()
				self[key] = nil
			end
		end
	end
	
	setmetatable(self, nil)
	table.clear(self)
	table.freeze(self)
end
BaseClass.Destroy = BaseClass.BaseDestroy

return BaseClass
