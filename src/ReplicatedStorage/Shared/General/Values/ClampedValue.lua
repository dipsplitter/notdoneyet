local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local BaseClass = Framework.GetShared("BaseClass")
local ValueModifiers = Framework.GetShared("ValueModifiers")

local PublicIndices = {"Value", "Max", "Min"}

local ClampedValue = {}
ClampedValue.ClassName = "ClampedValue"
setmetatable(ClampedValue, BaseClass)

function ClampedValue.new(max, min, currentValue)
	local self = BaseClass.new()
	
	self.AutoCleanup = true
	
	-- In case we're dealing with a table:
	if type(max) == "table" then
		self._max = if not max.Max then max.Value else max.Max
		self._value = max.Value or self._max
		self._min = max.Min or 0
	else
		self._max = max
		self._value = currentValue or max
		self._min = min or 0
	end
	
	setmetatable(self, ClampedValue)
	
	self:AddSignals("Changed")
	
	return self
end

function ClampedValue:__index(index)
	if table.find(PublicIndices, index) then
		return self:GetPrivateMember(index)
	elseif ClampedValue[index] then
		return ClampedValue[index]
	end
end

function ClampedValue:__newindex(index, value)
	if not table.find(PublicIndices, index) then
		rawset(self, index, value)
		return
	end
	
	local previous = self:GetPrivateMember(index)
	
	if previous ~= value then
		
		if index == "Value" then
			value = math.clamp(value, self._min, self._max)
		elseif index == "Min" or index == "Max" then
			self.Value = self._value
		end
		
		self[self:GetPrivateMemberKeyName(index)] = value
		self:FireSignal("Changed", index, previous, value)
	end
end

-- Will update the attribute value whenever the value changes
function ClampedValue:LinkAttribute(attributeContainer, name)
	self:AddConnections({
		[`Update{attributeContainer.Name}{name}`] = self:GetSignal("Changed"):Connect(function(index, previous, new)
			-- Clamped values represented as Vector3s
			attributeContainer:SetAttribute(name, Vector3.new(self.Min, self.Value, self.Max))
		end),

		[`{attributeContainer.Name}Destroying`] = attributeContainer.Destroying:Connect(function()
			self:CleanupConnection(`{attributeContainer.Name}Destroying`, `Update{attributeContainer.Name}{name}`)
		end),
	})
end

return ClampedValue