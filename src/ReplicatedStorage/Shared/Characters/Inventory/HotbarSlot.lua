local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local BaseClass = Framework.GetShared("BaseClass")
local EnumUtilities = Framework.GetShared("EnumUtilities")

local HotbarSlot = {}
HotbarSlot.__index = HotbarSlot
HotbarSlot.ClassName = "HotbarSlot"
setmetatable(HotbarSlot, BaseClass)

function HotbarSlot.new(params)
	local self = BaseClass.new()
	setmetatable(self, HotbarSlot)
	
	self:InjectObject("Hotbar", params.Hotbar)
	
	self.Item = params.Item or {}
	self.Id = params.Id -- Number
	self.Name = params.Name or `Misc{self.Id}`
	self.Keybind = params.Keybind -- Only one keybind
	
	if not string.match(self.Name, "Misc") and not self.Keybind then
		self.Keybind = EnumUtilities.NumberToKeyCode(self.Id)
	end
	
	self.Active = false
	
	self:AddSignals("ItemChanged")
	self:AddConnections({
		OnItemChanged = self:GetSignal("ItemChanged"):Connect(function()
			self.Item:AddExternalReference(self, {})
			
			local hotbar = self.Hotbar
			local id = self.Id
			
			self.Item.Cleaner:Add(function()
				
				if hotbar.CurrentlyActive == id then
					hotbar.CurrentlyActive = nil
				end
				
			end)
		end)
	})
	
	return self
end

function HotbarSlot:SetItem(item)
	self.Item = item
	self:FireSignal("ItemChanged", item)
end

function HotbarSlot:SetActive(params)
	if not next(self.Item) then
		return false
	end
	
	if not self.Item:ShouldSetActive(params) then
		return false
	end
	
	self.Active = true
	self.Hotbar.CurrentlyActive = self.Id
	self.Item:OnSetAsActive(params)
	
	return true
end

function HotbarSlot:SetInactive(params)
	if not next(self.Item) then
		return false
	end
	
	if not self.Item:ShouldSetInactive(params) then
		return false
	end
	
	self.Active = false
	self.Hotbar.CurrentlyActive = nil
	self.Item:OnSetAsInactive(params)
	
	return true
end

function HotbarSlot:ForgetItem()
	self.Item = nil
end

function HotbarSlot:Destroy()
	self.Item = nil
	self:BaseDestroy()
end

return HotbarSlot