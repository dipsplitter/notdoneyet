local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Framework = require(ReplicatedStorage.Framework)
local DefaultCharacterAttributes = Framework.GetShared("DefaultCharacterAttributes")
local Signal = Framework.GetShared("Signal")
local ItemInventory = Framework.GetShared("ItemInventory")
local ClassHotbars = Framework.GetShared("ClassHotbars")

local InputService = Framework.GetClient("InputService")

local NETWORK = Framework.Network()
local ChangeClassEvent = NETWORK.Event("ChangeClass")

local MOUSE_RAY_DISTANCE = 750

local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera
local mouse = localPlayer:GetMouse()
local diedConnection = nil

local Client = {
	LocalPlayer = localPlayer,
	Character = nil,
	CharacterAttributes = nil,
	Humanoid = nil,
	ItemInventory = ItemInventory.new({
		InputHandler = InputService.InputHandler,
	}),
	Class = "None",
	NextClass = nil,
	IsDead = true,
	
	MovementController = nil,
	
	CharacterAddedSignal = Signal.new(),
	CharacterDiedSignal = Signal.new(),
	ClassChangedSignal = Signal.new(),
	
	ItemEquipped = Signal.new(),
	ItemUnequipped = Signal.new(),
}

local function CharacterAdded(character)
	if Client.NextClass then
		Client.SetClass(Client.NextClass)
	end
	
	Client.IsDead = false
	Client.Character = character
	Client.Humanoid = character:WaitForChild("Humanoid")
	Client.CharacterAttributes = character:WaitForChild("Attributes")
	
	Client.CharacterAddedSignal:Fire(character)
	
	Client.Humanoid.Died:Once(function()
		Client.CharacterDiedSignal:Fire()
		Client.IsDead = true
	end)
end

function Client.RequestSetClass(class)
	ChangeClassEvent:Fire(class)
	Client.NextClass = class
end

function Client.SetClass(class)
	local oldClass = Client.Class
	Client.Class = class
	
	-- TODO
	Client.ItemInventory:SetHotbarSlots(ClassHotbars[class].Hotbars.Main.Slots)
	
	Client.ClassChangedSignal:Fire(class, oldClass)
end

function Client.GetCharacterAttribute(name, valueType)
	if not Client.CharacterAttributes then
		return
	end
	
	if not valueType then
		return Client.CharacterAttributes:GetAttribute(name) or DefaultCharacterAttributes:GetDefault(name)
	end
	
	-- Clamped values are stored as vectors
	local vector = Client.CharacterAttributes:GetAttribute(name)
	if valueType == "Min" then
		return vector.X
	elseif valueType == "Max" then
		return vector.Z
	else
		return vector.Y
	end
end

function Client.IsFirstPerson()
	local head = Client.Character.Head
	if not head then
		return false
	end
	
	return (head.CFrame.Position - camera.CFrame.Position).Magnitude < 1
end

function Client.GetHeadToMouseRay()
	local origin
	if not Client.Character or Client.IsFirstPerson() then
		origin = camera.CFrame.Position
	else
		origin = Client.Character.PrimaryPart.EyesAttachment.WorldPosition
	end
	
	return {
		Origin = origin,
		Direction = (Client.GetMouseHit() - origin).Unit
	}
end

function Client.GetMouseHit()
	return mouse.Hit.Position
end

function Client.GetCameraToMouseRay()
	local screenMousePosition = UserInputService:GetMouseLocation()
	return camera:ViewportPointToRay(screenMousePosition.X, screenMousePosition.Y)
end

function Client.GetInputHandler()
	return InputService.InputHandler
end

function Client.GetItemHotbar()
	return Client.ItemInventory.Hotbars.Main
end

function Client.GetMouseDelta()
	return InputService.MouseDelta
end

function Client.ApplyImpulse(vector)
	if not Client.Character then
		return
	end
	
	Client.MovementController:ApplyImpulse(vector)
end

if localPlayer.Character then
	CharacterAdded(localPlayer.Character)
end
localPlayer.CharacterAdded:Connect(CharacterAdded)

Client.GetItemHotbar():ConnectTo("SlotSetActive", function(slot)
	local item = slot.Item
	Client.ItemEquipped:Fire(item)
end)

Client.GetItemHotbar():ConnectTo("SlotSetInactive", function(slot, newSlot)
	local item = slot.Item
	local newItem = newSlot.Item
	
	-- Unarmed
	if item == newItem then
		Client.ItemUnequipped:Fire(item)
	else
		Client.ItemUnequipped:Fire(item, newItem)
	end
end)

return Client
