local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local Signal = Framework.GetShared("Signal")
local TableUtilities = Framework.GetShared("TableUtilities")

local function DoSignalTagsMatch(signal, compareToTags)
	local tags = signal.Tags
	
	-- Special tag "Type" is checked first
	if tags.Type ~= compareToTags.Type then
		return false
	end
	
	for k, v in compareToTags do
		if tags[k] ~= v then
			return false
		end
	end
	
	return true
end

local SignalTable = {}
SignalTable.__index = SignalTable

function SignalTable.new()
	local self = {}
	setmetatable(self, SignalTable)
	
	return self
end

--[[
	Signal tags:
	Deep - changes made to nested tables also fire the signal with the path to the change
]]
function SignalTable:Add(pathArray, signalTags)
	local key = table.concat(pathArray, ".")
	
	local existingSignal = SignalTable:Get(key, signalTags)
	if existingSignal then
		return existingSignal
	end
	
	local newSignal = Signal.new(signalTags, function(signal)
		self:Remove(pathArray, signal)
	end)
	
	self[key] = {
		[newSignal] = true,
	}
	
	return newSignal
end

function SignalTable:Get(concatKey, signalTags)
	local signalsAtKey = self[concatKey]
	if not signalsAtKey then
		return
	end
	
	for signal in signalsAtKey do
		
		local success = true
		
		if DoSignalTagsMatch(signal, signalTags) then
			return signal
		end
		
	end
end

function SignalTable:Remove(pathArray, signal)
	-- We only want to destroy a signal when it has no connections
	if #signal:GetConnections() > 0 then
		return
	end 
	
	local key = table.concat(pathArray, ".")
	
	self[key][signal] = nil
	signal:Destroy()
	
	-- Cleanup empty signal table keys
	if not next(self[key]) then
		self[key] = nil
	end
end

function SignalTable:Fire(params, signalTagFilterCallback)
	local pathArray = params.PathArray
	
	local key = ""
	
	local args = {
		PathArray = pathArray,
		Args = params.Args
	}
	
	-- Copy over arguments
	for k, v in params do
		if args[k] then
			continue
		end
		
		args[k] = v
	end
	
	-- For each key in the path array, fire deep signals
	for i, pathName in pathArray do
		key = key .. pathName
		
		local signalTable = self[key]
		if signalTable then
			
			for signal in signalTable do
				
				local tags = signal.Tags
				if tags.Type == params.Type and tags.Deep then
					signal:Fire(args)
				end
				
			end
		end
		
		if i < #pathArray then
			key = key .. "."
		end
	end
	
	-- Unnecessary for the lowest level signals
	args.PathArray = nil
	
	local final = self[key]
	if not final then
		return
	end

	for signal in final do
		
		-- Check the callback
		if signalTagFilterCallback and not signalTagFilterCallback(signal.Tags) then
			continue
		end
	
		signal:Fire(args)
	end
end

return SignalTable
