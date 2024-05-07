local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local BaseClass = Framework.GetShared("BaseClass")
local RecycledSpawn = Framework.GetShared("RecycledSpawn")

local GuiObject = require(script.Parent.GuiObject)

local ValueBar = {}
ValueBar.__index = ValueBar
ValueBar.ClassName = "ValueBar"
setmetatable(ValueBar, GuiObject)

function ValueBar.new(params)
	local self = GuiObject.new(params)
	setmetatable(self, ValueBar)
	
	self.Active = true
	
	self.TrackedValues = {}
	self.SizeRatio = {}
	
	BaseClass.AddSignals(self, "RatioChanged")
	
	return self
end

function ValueBar:IsValueRelatedToSizeRatio(valueName)
	return self.SizeRatio.Numerator == valueName or self.SizeRatio.Denominator == valueName
end

function ValueBar:SetSizeRatioComponents(numeratorName, denominatorName)
	self.SizeRatio.Numerator = numeratorName
	self.SizeRatio.Denominator = denominatorName
end

function ValueBar:GetSizeRatio()
	local numerator = self.SizeRatio.Numerator
	if type(numerator) == "string" then
		numerator = self.TrackedValues[numerator].Current
	end
	
	local denominator = self.SizeRatio.Denominator
	if type(denominator) == "string" then
		denominator = self.TrackedValues[denominator].Current
	end

	return numerator, denominator
end

function ValueBar:RemoveTrackedValue(valueName)
	self.TrackedValues[valueName] = nil
	BaseClass.CleanupConnection(`{valueName}Changed`)
end

function ValueBar:AddTrackedValue(valueName, signal, getter, modifyCallback)
	self.TrackedValues[valueName] = {
		Signal = signal,
		Getter = getter,
		Current = getter(),
		Callback = modifyCallback,
	}
	
	local entry = self.TrackedValues[valueName]
	
	BaseClass.AddConnections(self, {
		[`{valueName}Changed`] = signal:Connect(function()
			local old = entry.Current
			entry.Current = getter()
			
			if entry.Callback then
				if self:IsValueRelatedToSizeRatio(valueName) then
					RecycledSpawn(entry.Callback, self, self:GetSizeRatio())
				else
					RecycledSpawn(entry.Callback, self, entry.Current, old)
				end
			end
		end)
	})
end

ValueBar.AddConnection = BaseClass.AddConnection
ValueBar.CleanupConnection = BaseClass.CleanupConnection

return ValueBar
