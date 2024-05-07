local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)

local Client = Framework.GetClient("Client")

local CharacterAttributeBar = {}

function CharacterAttributeBar.AddValue(valueBar, name, updateFunction)
	local attributes = Client.CharacterAttributes
	if not attributes then
		return
	end
	
	local value = attributes:GetAttribute(name)
	local valueSignal = attributes:GetAttributeChangedSignal(name)
	
	local function GetValue()
		return attributes:GetAttribute(name)
	end
	
	local function GetMax()
		return
	end
	
	-- Clamped value
	if typeof(value) == "Vector3" then
		GetMax = function()
			return attributes:GetAttribute(name).Z
		end
		
		GetValue = function()
			return attributes:GetAttribute(name).Y
		end
		
		valueBar:AddTrackedValue(`Max{name}`, valueSignal, GetMax, updateFunction)
	end
	
	valueBar:AddTrackedValue(name, valueSignal, GetValue, updateFunction)
	
	updateFunction(valueBar, GetValue(), GetMax())
end

function CharacterAttributeBar.OnClientDeath(valueBar)
	valueBar.Ui.Visible = false
	
	local ratioComponents = valueBar.SizeRatio
	
	if next(ratioComponents) then
		valueBar:RemoveTrackedValue(ratioComponents.Numerator)
		valueBar:RemoveTrackedValue(ratioComponents.Denominator)
	end
end

return CharacterAttributeBar
