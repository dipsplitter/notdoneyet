local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local BaseClass = Framework.GetShared("BaseClass")
local ValueModifiers = Framework.GetShared("ValueModifiers")

local Value = {}
Value.ClassName = "Value"
setmetatable(Value, BaseClass)

function Value.new(baseValue)
	local self = BaseClass.new()
	
	self.AutoCleanup = true
	self._value = if type(baseValue) == "table" then baseValue.Value else baseValue
	
	self:AddSignals("Changed")
	
	setmetatable(self, Value)
	return self
end

function Value:__index(index)
	if index == "Value" then
		return rawget(self, "_value")
	elseif Value[index] then
		return Value[index]
	end
end

function Value:__newindex(index, value)
	if index ~= "Value" then
		rawset(self, index, value)
		return
	end
	
	local previous = rawget(self, "_value")
	
	if previous ~= value then
		rawset(self, "_value", value)
		
		self:FireSignal("Changed", previous, value)
	end
end

-- Will update the attribute value whenever the value changes
function Value:LinkAttribute(attributeContainer, name)
	self:AddConnections({
		[`Update{attributeContainer.Name}{name}`] = self:GetSignal("Changed"):Connect(function(previous, new)
			attributeContainer:SetAttribute(name, new)
		end),
		
		[`{attributeContainer.Name}Destroying`] = attributeContainer.Destroying:Connect(function()
			self:CleanupConnection(`{attributeContainer.Name}Destroying`, `Update{attributeContainer.Name}{name}`)
		end),
	})
end

return Value
