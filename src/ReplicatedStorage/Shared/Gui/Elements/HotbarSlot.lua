local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local RecycledSpawn = Framework.GetShared("RecycledSpawn")
local ItemSchema = Framework.GetShared("ItemSchema")
local GetSchemeGlobal = Framework.GetShared("GetSchemeGlobal")

local GuiObject = require(script.Parent.GuiObject)

local HotbarSlot = {}
HotbarSlot.__index = HotbarSlot

function HotbarSlot.new(params)
	local self = GuiObject.new(params)
	setmetatable(self, HotbarSlot)
	
	local slot = params.Slot
	local item = slot.Item
	
	self.Ui.LayoutOrder = slot.Id
	self.Ui.Name = slot.Name

	self:SetItem(item)
	self.Ui.KeybindIcon.Text = if #slot.Keybind.Name > 1 then slot.Id else slot.Keybind.Name
	
	self.ChangedConnection = slot:ConnectTo("ItemChanged", function(newItem)
		self:SetItem(newItem)
	end)
	
	return self
end

function HotbarSlot:SetItem(newItem)
	if newItem == nil or next(newItem) == nil then
		self.Ui.ItemImage.Image = ""
		self.Ui.ItemNameLabel.Text = ""
		return
	end
	
	local imageId = ItemSchema.GetItemIcon(newItem.Id)
	
	if imageId == "" then
		self.Ui.ItemNameLabel.Text = newItem.Id
	else
		self.Ui.ItemImage.Image = imageId
	end
end

function HotbarSlot:OnSetActive()
	self.Ui.UIStroke.Thickness *= 1.5
	self.Ui.UIStroke.Color = GetSchemeGlobal.Typed(self.Resource, "Colors", self.Resource.Config.Active)
	self.Ui.UIGradient.Enabled = false
end

function HotbarSlot:OnSetInactive()
	self.Ui.UIStroke.Thickness /= 1.5
	self.Ui.UIStroke.Color = GetSchemeGlobal.Typed(self.Resource, "Colors", self.Resource.Config.Inactive)
	self.Ui.UIGradient.Enabled = true
end 

function HotbarSlot:Destroy()
	self.ChangedConnection:Disconnect()
	self.ChangedConnection = nil
	
	GuiObject.Destroy(self)
end

return HotbarSlot
