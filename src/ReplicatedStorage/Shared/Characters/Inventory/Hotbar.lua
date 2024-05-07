local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local BaseClass = Framework.GetShared("BaseClass")
local InputContext = Framework.GetShared("InputContext")
local TableUtilities = Framework.GetShared("TableUtilities")
local HotbarSlot = Framework.GetShared("HotbarSlot")
local DefaultKeybinds = Framework.GetShared("DefaultKeybinds")
local EnumUtilities = Framework.GetShared("EnumUtilities")

local Hotbar = {}
Hotbar.__index = Hotbar
Hotbar.ClassName = "ItemInventory"
setmetatable(Hotbar, BaseClass)

function Hotbar.new(params)
	local self = BaseClass.new()
	setmetatable(self, Hotbar)
	
	self.Name = params.Name
	self.SlotOrder = {}
	self.Slots = {}
	self.CurrentlyActive = nil -- Each hotbar can only have ONE currently active item
	
	self:AddSignals("SlotChosen", "SlotSetActive", "SlotSetInactive", "SlotAdded")
	
	self.ScrollContext = InputContext.new({
		Keybinds = {Enum.UserInputType.MouseWheel},
		ContextName = "HotbarScroll",
	})
	
	self.LastScrollSwitchTime = 0
	self.ScrollSwitchDelay = 0.1
	
	if params.InputHandler then
		self:SetInputHandler(params.InputHandler)
	end
	
	self:SetSlots(params.Slots or {})
	if params.Size then
		self:SetTotalSize(params.Size)
	end
	
	return self
end

function Hotbar:SetInputHandler(inputHandler)
	self:InjectObject("InputHandler", inputHandler)
	
	self:AddConnections({
		InputListener = self.InputHandler:GetSignal("InputOccurred"):Connect(function(inputInfo)
			local inputState = inputInfo.InputState
			local inputType = inputInfo.InputType
			if inputState ~= Enum.UserInputState.Begin then
				return
			end

			local slot = self:GetSlotFromInput(inputType)
			if not slot then
				return
			end

			self:SetSlotAsActive(slot, inputInfo)
		end),

		OnMouseScroll = self.ScrollContext:GetSignal("Triggered"):Connect(function(inputInfo)
			if os.clock() - self.LastScrollSwitchTime < self.ScrollSwitchDelay then
				return
			else
				self.LastScrollSwitchTime = os.clock()
			end

			local z = inputInfo.Position.Z
			-- Scrolled up

			local idToSetActive = self.CurrentlyActive
			if z > 0 then
				idToSetActive += 1
			else
				idToSetActive -= 1
			end

			self:SetSlotAsActive(self:GetSlotById(idToSetActive), inputInfo)
		end)
	})
end

function Hotbar:BindScroll()
	self.ScrollContext:Bind()
end

function Hotbar:UnbindScroll()
	self.ScrollContext:Unbind()
end

function Hotbar:GetVacantSlots()
	local results = {}
	
	for slotName, slot in pairs(self.Slots) do
		if not next(slot.Item) then
			table.insert(results, slot)
		end
	end
	
	return results
end

function Hotbar:CreateSlot(params)
	params.Hotbar = self
	
	local newSlot = HotbarSlot.new(params)
	self.Slots[params.Name] = newSlot
	
	self:FireSignal("SlotAdded", newSlot)
end

function Hotbar:IsSlotActive(slotName)
	if not self.Slots[slotName] then
		return false
	end
	
	return self.Slots[slotName].Active
end

function Hotbar:GetSlotById(id)
	for slotName, slot in pairs(self.Slots) do
		if slot.Id == id then
			return slot
		end
	end
end

function Hotbar:GetCurrentlyActiveSlot()
	if not self.CurrentlyActive then
		return
	end
	
	return self:GetSlotById(self.CurrentlyActive)
end


function Hotbar:SetSlotAsActive(slot, inputInfo)
	local itemToSetActive = slot.Item
	-- TODO: Default to a fallback item like fists?
	if not next(itemToSetActive) then
		return
	end
	
	local current = self:GetCurrentlyActiveSlot()
	
	local function SetSlotActive()
		local result = slot:SetActive({
			InputInfo = inputInfo,
			Hotbar = self.Slots
		})
		
		if result then
			self:FireSignal("SlotSetActive", slot)
		end
	end
	
	if current then
		local result = current:SetInactive({
			InputInfo = inputInfo,
			ItemToSetActive = itemToSetActive,

			Callback = SetSlotActive,
		})
		
		if result then
			self:FireSignal("SlotSetInactive", current, slot)
		end
		
	else
		SetSlotActive()
	end
end

function Hotbar:SwapItemsInSlot(slot1, slot2)
	local item1 = slot1.Item
	local item2 = slot2.Item
	if not item1 or not item2 then
		return
	end
	
	slot1:SetItem(item2)
	slot2:SetItem(item1)
end

function Hotbar:IsItemInHotbar(item)
	for name, slot in pairs(self.Slots) do
		if slot.Item == item then
			return true
		end
	end
	
	return false
end

function Hotbar:GetSlotFromInput(input)
	for slotName, slot in pairs(self.Slots) do
		local slotKeybind = slot.Keybind
		if slotKeybind == input then
			return slot
		end
	end
end

function Hotbar:SetSlots(slotsTable)
	-- Remove all previous items (same as resetting)
	for slotName, slot in pairs(self.Slots) do
		slot:Destroy()
	end
	table.clear(self.SlotOrder)
	table.clear(self.Slots)
	
	self.CurrentlyActive = nil
	
	local currentSlotNumber = 1
	for slotName, keybind in slotsTable do
		
		-- TODO
		if not keybind or typeof(keybind) ~= "EnumItem" then
			
		end
		
		local nextId = currentSlotNumber
		
		local autoNextId = EnumUtilities.KeyCodeToNumber(keybind)
		if autoNextId then
			nextId = autoNextId
		end
		
		self:CreateSlot({
			Name = slotName,
			Id = nextId,
			Keybind = keybind,
		})
		self.SlotOrder[currentSlotNumber] = slotName
		
		currentSlotNumber += 1
	end
end
 
function Hotbar:SetTotalSize(size)
	local currentSize = #self.SlotOrder
	
	if size <= currentSize then
		warn(`Tried reducing hotbar size from {currentSize} to {size}!`)
		return
	end
	
	local newAnonymousSlots = currentSize - size
	for i = 1, newAnonymousSlots do
		local slotNumber = #self.SlotOrder + 1
		
		self:CreateSlot({
			Id = slotNumber
		})
		
		self.SlotOrder[slotNumber] = "Misc"
	end
end

function Hotbar:AddItems(slotToItemDict)
	for slotName, item in pairs(slotToItemDict) do
		local slotToAssign = self.Slots[slotName]
		-- TODO: Add to a misc slot
		if type(slotName) == "number" then
			
			local defaultSlot = item.SchemaEntry.DefaultSlot
			slotToAssign = self.Slots[defaultSlot]
			
		end
		
		if not slotToAssign then
			warn(`Tried assigning an item to slot {slotName}, but it doesn't exist or hasn't been created yet!`)
			continue
		end
		
		slotToAssign:SetItem(item)
	end
end

function Hotbar:ForgetAllItems()
	for slotName, slot in self.Slots do
		slot:ForgetItem()
	end
end

function Hotbar:Destroy()
	self:ForgetAllItems()
	self:ForgetAll() 
	self:BaseDestroy()
end

return Hotbar
