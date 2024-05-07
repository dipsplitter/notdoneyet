local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local BaseClass = Framework.GetShared("BaseClass")
local RecycledSpawn = Framework.GetShared("RecycledSpawn")

local GuiObject = require(script.Parent.GuiObject)

local GuiButton = {}
GuiButton.__index = GuiButton
GuiButton.ClassName = "GuiButton"
setmetatable(GuiButton, GuiObject)

function GuiButton.new(params)
	local self = GuiObject.new(params)
	setmetatable(self, GuiButton)
	
	return self
end

function GuiButton:SetHoverCallback(callback)
	BaseClass.AddConnections(self, {
		HoverConnection = self.Ui.MouseEnter:Connect(callback)
	})
end

function GuiButton:SetLeaveCallback(callback)
	BaseClass.AddConnections(self, {
		LeaveConnection = self.Ui.MouseLeave:Connect(callback)
	})
end

function GuiButton:SetInputCallbacks(callbackTable)
	for eventName, callback in callbackTable do
		callbackTable[eventName] = self.Ui[eventName]:Connect(callback)
	end
	
	BaseClass.AddConnections(self, callbackTable)
end

GuiButton.AddConnection = BaseClass.AddConnection
GuiButton.CleanupConnection = BaseClass.CleanupConnection

return GuiButton
